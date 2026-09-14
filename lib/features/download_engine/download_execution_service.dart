import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';

import '../history/history_service.dart';
import '../history/models/history_item.dart';
import 'models/video_format.dart';
import 'models/video_info.dart';

/// Interface for executing download processes. Enables mock injection in tests.
abstract class DownloadProcessRunner {
  Future<int> runDownloadProcess({
    required String executable,
    required List<String> arguments,
    required void Function(double progressPercent) onProgress,
    required void Function(String errorLine) onErrorLine,
  });
}

/// Default implementation that starts a system process and streams stdout.
class DefaultDownloadProcessRunner implements DownloadProcessRunner {
  const DefaultDownloadProcessRunner();

  @override
  Future<int> runDownloadProcess({
    required String executable,
    required List<String> arguments,
    required void Function(double progressPercent) onProgress,
    required void Function(String errorLine) onErrorLine,
  }) async {
    final process = await Process.start(executable, arguments);

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final progressPercent = parseStdoutProgress(line);
      if (progressPercent != null) {
        onProgress(progressPercent);
      }
    });

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(onErrorLine);

    return process.exitCode;
  }

  /// Parses yt-dlp stdout progress percentage lines (e.g. "[download]  45.2% of 12.0MiB").
  static double? parseStdoutProgress(String line) {
    final match = RegExp(r'\[download\]\s+(\d+(?:\.\d+)?)%').firstMatch(line);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
}

/// Service responsible for managing video download execution, direct stream piping,
/// yt-dlp process routing, real-time progress parsing, Android MediaStore registration,
/// and history record persistence.
class DownloadExecutionService {
  final HistoryService historyService;
  final DownloadProcessRunner processRunner;
  final String? ytDlpBinaryPath;
  final Directory? customDownloadsDirectory;
  final http.Client? httpClient;

  const DownloadExecutionService({
    required this.historyService,
    this.processRunner = const DefaultDownloadProcessRunner(),
    this.ytDlpBinaryPath,
    this.customDownloadsDirectory,
    this.httpClient,
  });

  /// Resolves or creates the destination directory: ReelSaver/Downloads.
  Future<Directory> getDownloadsDirectory() async {
    if (customDownloadsDirectory != null) {
      if (!await customDownloadsDirectory!.exists()) {
        await customDownloadsDirectory!.create(recursive: true);
      }
      return customDownloadsDirectory!;
    }

    Directory? baseDirectory;
    try {
      baseDirectory = await getExternalStorageDirectory();
    } catch (_) {}
    baseDirectory ??= await getApplicationDocumentsDirectory();

    final downloadsDirectory =
        Directory('${baseDirectory.path}/ReelSaver/Downloads');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    return downloadsDirectory;
  }

  /// Sanitizes a video title for safe file system usage.
  String sanitizeFileName(String title) {
    final sanitized = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'video' : sanitized;
  }

  /// Builds command-line arguments for yt-dlp based on the chosen format.
  List<String> buildYtDlpArguments({
    required String url,
    required VideoFormat format,
    required String destinationFilePath,
  }) {
    final arguments = <String>[
      '--no-warnings',
      '--newline',
    ];

    if (format.type == FormatType.audioOnly) {
      arguments.addAll([
        '-x',
        '--audio-format',
        format.fileExtension,
      ]);
    } else if (format.height != null) {
      arguments.addAll([
        '-f',
        'bestvideo[height<=${format.height}]+bestaudio/best[height<=${format.height}]/best',
      ]);
    } else {
      arguments.addAll([
        '-f',
        'bestvideo+bestaudio/best',
      ]);
    }

    arguments.addAll([
      '-o',
      destinationFilePath,
      url,
    ]);

    return arguments;
  }

  /// Executes download for a given format and URL, streaming actual media bytes,
  /// updating progress, registering with MediaStore, and saving to History.
  Future<String> executeDownload({
    required String url,
    required VideoInfo videoInfo,
    required VideoFormat format,
    required void Function(double progressPercent) onProgress,
  }) async {
    final downloadsDir = await getDownloadsDirectory();
    final cleanTitle = sanitizeFileName(videoInfo.title);
    String destinationPath =
        '${downloadsDir.path}/$cleanTitle.${format.fileExtension}';

    // Prevent file collision and overwriting by generating a unique name if target already exists
    int collisionIndex = 1;
    while (await File(destinationPath).exists()) {
      destinationPath =
          '${downloadsDir.path}/$cleanTitle ($collisionIndex).${format.fileExtension}';
      collisionIndex++;
    }

    // 1. Direct stream download if format has direct downloadUrl (e.g. from YouTubeExplode or Instagram)
    if (format.downloadUrl != null && format.downloadUrl!.isNotEmpty) {
      await _downloadFromDirectUrl(
        downloadUrl: format.downloadUrl!,
        destinationPath: destinationPath,
        estimatedSizeMB: format.estimatedSizeMB,
        onProgress: onProgress,
      );
    } else {
      // 2. yt-dlp binary execution
      final binaryPath = ytDlpBinaryPath ?? await _locateBundledYtDlp();
      final hasCustomRunner = processRunner is! DefaultDownloadProcessRunner;

      if (hasCustomRunner || (binaryPath != null && await File(binaryPath).exists())) {
        final arguments = buildYtDlpArguments(
          url: url,
          format: format,
          destinationFilePath: destinationPath,
        );

        final errorLines = <String>[];
        final exitCode = await processRunner.runDownloadProcess(
          executable: binaryPath ?? 'yt-dlp',
          arguments: arguments,
          onProgress: onProgress,
          onErrorLine: (err) => errorLines.add(err),
        );

        if (exitCode != 0) {
          final message = errorLines.isNotEmpty
              ? errorLines.join('\n')
              : 'Download process failed with exit code $exitCode';
          throw Exception(message);
        }
      } else {
        throw Exception(
          'Cannot download media: yt-dlp binary is missing and no direct stream URL is available.',
        );
      }
    }

    // Verify downloaded file is valid on disk
    final downloadedFile = File(destinationPath);
    if (!await downloadedFile.exists() || await downloadedFile.length() == 0) {
      throw Exception('Downloaded file is empty or missing at $destinationPath');
    }

    // Register with Android MediaStore so file appears in phone's Gallery
    try {
      await MediaScanner.loadMedia(path: destinationPath);
      debugPrint('[DownloadExecutionService] Registered with MediaStore: $destinationPath');
    } catch (scannerError) {
      debugPrint('[DownloadExecutionService] MediaScanner skipped or unavailable: $scannerError');
    }

    // Determine final file size
    double fileSizeMB = format.estimatedSizeMB ?? 0.0;
    try {
      fileSizeMB = (await downloadedFile.length()) / (1024 * 1024);
    } catch (_) {}

    // Record entry to History store
    final historyItem = HistoryItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: videoInfo.title,
      thumbnailUrl: videoInfo.thumbnailUrl,
      filePath: destinationPath,
      format: '${format.label} (${format.typeDescription})',
      fileSizeMB: double.parse(fileSizeMB.toStringAsFixed(2)),
      downloadedAt: DateTime.now(),
    );

    await historyService.addHistoryEntry(historyItem);
    return destinationPath;
  }

  /// Streams direct media bytes from URL with real-time progress calculation.
  Future<void> _downloadFromDirectUrl({
    required String downloadUrl,
    required String destinationPath,
    required double? estimatedSizeMB,
    required void Function(double progressPercent) onProgress,
  }) async {
    final client = httpClient ?? http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final response = await client.send(request);
      if (response.statusCode >= 400) {
        throw Exception(
          'Server returned HTTP ${response.statusCode} while downloading video stream.',
        );
      }

      final totalBytes = response.contentLength ??
          (estimatedSizeMB != null ? (estimatedSizeMB * 1024 * 1024).round() : 0);

      final file = File(destinationPath);
      sink = file.openWrite();

      int receivedBytes = 0;
      await response.stream.listen((chunk) {
        sink?.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes) * 100.0;
          onProgress(progress.clamp(0.0, 100.0));
        }
      }).asFuture();

      await sink.flush();
      await sink.close();
      sink = null;
      onProgress(100.0);
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      final file = File(destinationPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<String?> _locateBundledYtDlp() async {
    const possiblePaths = [
      'assets/bin/yt-dlp.exe',
      'assets/bin/yt-dlp',
    ];
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }
}

/// Provider for [DownloadExecutionService].
final downloadExecutionServiceProvider =
    Provider<DownloadExecutionService>((ref) {
  return DownloadExecutionService(
    historyService: ref.watch(historyServiceProvider),
  );
});
