import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/download_execution_service.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/history/history_service.dart';

class MockDownloadProcessRunner implements DownloadProcessRunner {
  final int exitCode;
  final List<String> stdoutLines;
  final List<String> stderrLines;
  final bool simulateCreateFile;

  MockDownloadProcessRunner({
    this.exitCode = 0,
    this.stdoutLines = const [],
    this.stderrLines = const [],
    this.simulateCreateFile = true,
  });

  @override
  Future<int> runDownloadProcess({
    required String executable,
    required List<String> arguments,
    required void Function(double progressPercent) onProgress,
    required void Function(String errorLine) onErrorLine,
  }) async {
    for (final line in stdoutLines) {
      final percent = DefaultDownloadProcessRunner.parseStdoutProgress(line);
      if (percent != null) {
        onProgress(percent);
      }
    }
    for (final err in stderrLines) {
      onErrorLine(err);
    }

    if (simulateCreateFile && exitCode == 0) {
      final oIndex = arguments.indexOf('-o');
      if (oIndex != -1 && oIndex + 1 < arguments.length) {
        final filePath = arguments[oIndex + 1];
        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsString('Mock media stream data content');
      }
    }

    return exitCode;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late Directory downloadsDirectory;
  late File historyFile;
  late HistoryService historyService;

  const sampleVideo = VideoInfo(
    title: 'Awesome/Reel: Test* 1080p?',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    durationSeconds: 30,
    formats: [],
  );

  const videoFormat1080 = VideoFormat(
    label: '1080p',
    type: FormatType.videoAndAudio,
    fileExtension: 'mp4',
    height: 1080,
    estimatedSizeMB: 20.0,
  );

  const audioFormatMp3 = VideoFormat(
    label: '320kbps',
    type: FormatType.audioOnly,
    fileExtension: 'mp3',
    bitrate: 320,
    estimatedSizeMB: 5.0,
  );

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('execution_test_');
    downloadsDirectory =
        Directory('${temporaryDirectory.path}/ReelSaver/Downloads');
    await downloadsDirectory.create(recursive: true);

    historyFile = File('${temporaryDirectory.path}/history.json');
    historyService = HistoryService(customHistoryFile: historyFile);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('DownloadExecutionService Helper Tests', () {
    test('parseStdoutProgress extracts percentage correctly from varied lines', () {
      expect(
        DefaultDownloadProcessRunner.parseStdoutProgress('[download]   0.0% of 10.00MiB at 500.00KiB/s'),
        equals(0.0),
      );
      expect(
        DefaultDownloadProcessRunner.parseStdoutProgress('[download]  45.3% of ~20.00MiB at 1.50MiB/s ETA 00:07'),
        equals(45.3),
      );
      expect(
        DefaultDownloadProcessRunner.parseStdoutProgress('[download] 100% of 15.20MiB in 00:03'),
        equals(100.0),
      );
      expect(
        DefaultDownloadProcessRunner.parseStdoutProgress('[info] Downloading webpage'),
        isNull,
      );
    });

    test('sanitizeFileName removes illegal filesystem characters', () {
      final service = DownloadExecutionService(historyService: historyService);
      final sanitized = service.sanitizeFileName('Reel/Title: With* Illegal? "Chars"');
      expect(sanitized, equals('Reel_Title_ With_ Illegal_ _Chars_'));
      expect(sanitized.contains('/'), isFalse);
      expect(sanitized.contains(':'), isFalse);
      expect(sanitized.contains('?'), isFalse);
    });

    test('buildYtDlpArguments generates correct flags for video and audio formats', () {
      final service = DownloadExecutionService(historyService: historyService);

      final videoArgs = service.buildYtDlpArguments(
        url: 'https://instagram.com/reel/abc',
        format: videoFormat1080,
        destinationFilePath: '/out/video.mp4',
      );
      expect(videoArgs, contains('-f'));
      expect(videoArgs, contains('-o'));
      expect(videoArgs, contains('/out/video.mp4'));

      final audioArgs = service.buildYtDlpArguments(
        url: 'https://youtube.com/watch?v=abc',
        format: audioFormatMp3,
        destinationFilePath: '/out/audio.mp3',
      );
      expect(audioArgs, contains('-x'));
      expect(audioArgs, contains('--audio-format'));
      expect(audioArgs, contains('mp3'));
    });
  });

  group('DownloadExecutionService Process Execution Tests', () {
    test('successful execution streams progress, creates file, and records history entry', () async {
      final mockRunner = MockDownloadProcessRunner(
        exitCode: 0,
        stdoutLines: [
          '[download]  10.0% of 20.00MiB',
          '[download]  50.5% of 20.00MiB',
          '[download] 100% of 20.00MiB',
        ],
      );

      // Create a dummy executable file so binary check passes
      final fakeBinary = File('${temporaryDirectory.path}/fake_yt_dlp');
      await fakeBinary.create();

      final service = DownloadExecutionService(
        historyService: historyService,
        processRunner: mockRunner,
        ytDlpBinaryPath: fakeBinary.path,
        customDownloadsDirectory: downloadsDirectory,
      );

      final progressValues = <double>[];
      final destinationPath = await service.executeDownload(
        url: 'https://instagram.com/reel/test',
        videoInfo: sampleVideo,
        format: videoFormat1080,
        onProgress: (percent) => progressValues.add(percent),
      );

      // Check progress emitted
      expect(progressValues, equals([10.0, 50.5, 100.0]));
      // Check file created
      expect(await File(destinationPath).exists(), isTrue);

      // Check History recorded
      final history = await historyService.getHistory();
      expect(history.length, equals(1));
      expect(history.first.title, equals(sampleVideo.title));
      expect(history.first.filePath, equals(destinationPath));
      expect(history.first.format, contains('1080p'));
    });

    test('process failure throws exception with captured stderr', () async {
      final mockRunner = MockDownloadProcessRunner(
        exitCode: 1,
        stderrLines: ['ERROR: Private video cannot be accessed'],
        simulateCreateFile: false,
      );

      final fakeBinary = File('${temporaryDirectory.path}/fake_yt_dlp');
      await fakeBinary.create();

      final service = DownloadExecutionService(
        historyService: historyService,
        processRunner: mockRunner,
        ytDlpBinaryPath: fakeBinary.path,
        customDownloadsDirectory: downloadsDirectory,
      );

      expect(
        () => service.executeDownload(
          url: 'https://instagram.com/reel/private',
          videoInfo: sampleVideo,
          format: videoFormat1080,
          onProgress: (_) {},
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Private video cannot be accessed'),
          ),
        ),
      );

      // History should remain empty on failure
      expect(await historyService.getHistory(), isEmpty);
    });
  });
}
