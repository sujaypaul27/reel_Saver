import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/video_format.dart';
import 'models/video_info.dart';

/// Service responsible for extracting video metadata and format streams using yt-dlp.
class ExtractionService {
  final String? ytDlpBinaryPath;

  const ExtractionService({this.ytDlpBinaryPath});

  /// Fetches video details and format options for the provided [url].
  Future<VideoInfo> fetchDetails(String url) async {
    final binaryPath = ytDlpBinaryPath ?? await _locateBundledYtDlp();

    if (binaryPath != null && await File(binaryPath).exists()) {
      try {
        final processResult = await Process.run(
          binaryPath,
          ['--dump-json', '--no-warnings', url],
        );

        if (processResult.exitCode == 0) {
          final dynamic parsedJson = jsonDecode(processResult.stdout.toString());
          if (parsedJson is Map<String, dynamic>) {
            return parseYtDlpJson(parsedJson);
          } else {
            throw const FormatException('Extractor returned unexpected data structure.');
          }
        } else {
          final stderrOutput = processResult.stderr.toString().trim();
          debugPrint('[ExtractionService] yt-dlp failed: $stderrOutput');
          throw Exception(
            'Could not fetch video details. The video may be private, removed, or unavailable.',
          );
        }
      } on FormatException {
        rethrow;
      } catch (processError) {
        if (processError is Exception &&
            processError.toString().contains('Could not fetch')) {
          rethrow;
        }
        debugPrint('[ExtractionService] Error executing yt-dlp: $processError');
        throw Exception(
          'Could not fetch video details. Please check your internet connection and try again.',
        );
      }
    }

    // TODO: replace with real yt-dlp binary call once binary is bundled (see Phase 3b)
    // Fallback: return realistic mock data with a varied set of formats (144p to 4K + audio)
    return _generateMockVideoInfo(url);
  }

  /// Parses raw JSON output from yt-dlp into a structured [VideoInfo] object.
  VideoInfo parseYtDlpJson(Map<String, dynamic> rawJson) {
    final title = (rawJson['title'] as String?) ?? 'Video';
    final thumbnailUrl = (rawJson['thumbnail'] as String?) ?? '';
    final durationSeconds = (rawJson['duration'] as num?)?.toInt() ?? 0;

    final rawFormats = rawJson['formats'] as List<dynamic>? ?? [];
    final extractedFormats = <VideoFormat>[];

    for (final rawFormat in rawFormats) {
      if (rawFormat is! Map<String, dynamic>) continue;

      final vcodec = rawFormat['vcodec'] as String?;
      final acodec = rawFormat['acodec'] as String?;

      final hasVideo = vcodec != null && vcodec != 'none';
      final hasAudio = acodec != null && acodec != 'none';

      // Ignore entries with neither video nor audio (metadata/storyboards)
      if (!hasVideo && !hasAudio) continue;

      final FormatType type;
      if (hasVideo && hasAudio) {
        type = FormatType.videoAndAudio;
      } else if (hasVideo && !hasAudio) {
        type = FormatType.videoOnly;
      } else {
        type = FormatType.audioOnly;
      }

      final extension = (rawFormat['ext'] as String?) ?? 'mp4';
      final height = (rawFormat['height'] as num?)?.toInt();
      final abr = (rawFormat['abr'] as num?)?.toInt();
      final tbr = (rawFormat['tbr'] as num?)?.toInt();
      final bitrate = abr ?? tbr;

      // Extract quality label
      final String label;
      if (hasVideo) {
        if (height != null) {
          if (height >= 2160) {
            label = '4K';
          } else {
            label = '${height}p';
          }
        } else {
          label = (rawFormat['format_note'] as String?) ?? 'Video';
        }
      } else {
        if (bitrate != null && bitrate > 0) {
          label = '${bitrate}kbps';
        } else {
          label = (rawFormat['format_note'] as String?) ?? 'Audio';
        }
      }

      // Calculate estimated file size in MB
      final rawFileSize = (rawFormat['filesize'] as num?)?.toDouble() ??
          (rawFormat['filesize_approx'] as num?)?.toDouble();
      final estimatedSizeMB =
          rawFileSize != null ? (rawFileSize / (1024 * 1024)) : null;

      extractedFormats.add(
        VideoFormat(
          label: label,
          type: type,
          fileExtension: extension,
          estimatedSizeMB: estimatedSizeMB,
          height: height,
          bitrate: bitrate,
        ),
      );
    }

    // Deduplication: Keep only one format per (label + type), preferring mp4/m4a
    final deduplicatedFormatsMap = <String, VideoFormat>{};
    for (final format in extractedFormats) {
      final key = '${format.label}_${format.type.name}';
      final existing = deduplicatedFormatsMap[key];
      if (existing == null) {
        deduplicatedFormatsMap[key] = format;
      } else {
        final isExistingPreferred =
            existing.fileExtension.toLowerCase() == 'mp4' ||
                existing.fileExtension.toLowerCase() == 'm4a';
        final isCurrentPreferred =
            format.fileExtension.toLowerCase() == 'mp4' ||
                format.fileExtension.toLowerCase() == 'm4a';

        if (!isExistingPreferred && isCurrentPreferred) {
          deduplicatedFormatsMap[key] = format;
        }
      }
    }

    final uniqueFormats = deduplicatedFormatsMap.values.toList();

    // Sorting: Video formats first (highest resolution to lowest),
    // then Audio formats (highest bitrate to lowest).
    final videoFormats = uniqueFormats
        .where((f) => f.type == FormatType.videoAndAudio || f.type == FormatType.videoOnly)
        .toList()
      ..sort((a, b) {
        final heightA = a.height ?? 0;
        final heightB = b.height ?? 0;
        if (heightA != heightB) {
          return heightB.compareTo(heightA);
        }
        // If same resolution, place videoAndAudio before videoOnly
        if (a.type == FormatType.videoAndAudio && b.type != FormatType.videoAndAudio) {
          return -1;
        }
        if (b.type == FormatType.videoAndAudio && a.type != FormatType.videoAndAudio) {
          return 1;
        }
        return 0;
      });

    final audioFormats = uniqueFormats
        .where((f) => f.type == FormatType.audioOnly)
        .toList()
      ..sort((a, b) {
        final bitrateA = a.bitrate ?? 0;
        final bitrateB = b.bitrate ?? 0;
        return bitrateB.compareTo(bitrateA);
      });

    return VideoInfo(
      title: title,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      formats: [...videoFormats, ...audioFormats],
    );
  }

  /// Generates a realistic mock [VideoInfo] object containing a wide set of qualities.
  VideoInfo _generateMockVideoInfo(String url) {
    return const VideoInfo(
      title: 'Amazing Landscape & Travel Adventure Reel (4K 60fps)',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      durationSeconds: 215,
      formats: [
        VideoFormat(
          label: '4K',
          type: FormatType.videoOnly,
          fileExtension: 'mp4',
          estimatedSizeMB: 185.4,
          height: 2160,
        ),
        VideoFormat(
          label: '1080p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
          estimatedSizeMB: 68.2,
          height: 1080,
        ),
        VideoFormat(
          label: '1080p',
          type: FormatType.videoOnly,
          fileExtension: 'mp4',
          estimatedSizeMB: 48.0,
          height: 1080,
        ),
        VideoFormat(
          label: '720p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
          estimatedSizeMB: 34.5,
          height: 720,
        ),
        VideoFormat(
          label: '480p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
          estimatedSizeMB: 18.2,
          height: 480,
        ),
        VideoFormat(
          label: '360p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
          estimatedSizeMB: 12.0,
          height: 360,
        ),
        VideoFormat(
          label: '144p',
          type: FormatType.videoOnly,
          fileExtension: 'mp4',
          estimatedSizeMB: 4.8,
          height: 144,
        ),
        VideoFormat(
          label: '320kbps',
          type: FormatType.audioOnly,
          fileExtension: 'mp3',
          estimatedSizeMB: 8.5,
          bitrate: 320,
        ),
        VideoFormat(
          label: '128kbps',
          type: FormatType.audioOnly,
          fileExtension: 'mp3',
          estimatedSizeMB: 3.4,
          bitrate: 128,
        ),
      ],
    );
  }

  /// Locates any bundled yt-dlp binary on the system.
  Future<String?> _locateBundledYtDlp() async {
    // Check standard bundled binary locations
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

/// Provider for [ExtractionService].
final extractionServiceProvider = Provider<ExtractionService>((ref) {
  return const ExtractionService();
});
