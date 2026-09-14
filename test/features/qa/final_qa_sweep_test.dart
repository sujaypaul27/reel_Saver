import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_service.dart';
import 'package:reel_saver/features/clipboard_engine/share_intent_service.dart';
import 'package:reel_saver/features/download_engine/download_execution_service.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';
import 'package:reel_saver/features/history/history_screen.dart';
import 'package:reel_saver/features/history/history_service.dart';
import 'package:reel_saver/features/history/models/history_item.dart';
import 'package:reel_saver/features/settings/settings_screen.dart';
import 'package:reel_saver/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingMockExtractionService extends ExtractionService {
  final String errorMessage;

  const FailingMockExtractionService({this.errorMessage = 'Network offline'});

  @override
  Future<VideoInfo> fetchDetails(String url) async {
    throw Exception(errorMessage);
  }
}

class MixedDownloadProcessRunner implements DownloadProcessRunner {
  final Map<String, int> urlExitCodes;

  const MixedDownloadProcessRunner(this.urlExitCodes);

  @override
  Future<int> runDownloadProcess({
    required String executable,
    required List<String> arguments,
    required void Function(double progressPercent) onProgress,
    required void Function(String errorLine) onErrorLine,
  }) async {
    onProgress(50.0);
    // Find URL from arguments
    final targetUrl = arguments.last;
    final exitCode = urlExitCodes[targetUrl] ?? 0;
    if (exitCode != 0) {
      onErrorLine('ERROR: [youtube] Private video. Sign in to view this video.');
      onErrorLine('Traceback (most recent call last):');
      onErrorLine('  File "yt_dlp/extractor/youtube.py", line 400');
    } else {
      final oIndex = arguments.indexOf('-o');
      if (oIndex != -1 && oIndex + 1 < arguments.length) {
        final filePath = arguments[oIndex + 1];
        final file = File(filePath);
        await file.create(recursive: true);
        await file.writeAsString('Mock media stream data content');
      }
      onProgress(100.0);
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temporaryDirectory = await Directory.systemTemp.createTemp('reel_saver_qa_temp_');
    downloadsDirectory = await Directory.systemTemp.createTemp('reel_saver_qa_dl_');
    historyFile = File('${temporaryDirectory.path}/history_qa.json');
    historyService = HistoryService(customHistoryFile: historyFile);
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
    if (downloadsDirectory.existsSync()) {
      downloadsDirectory.deleteSync(recursive: true);
    }
  });

  group('Phase 11 QA: Download Queue Concurrency & Mixed Results', () {
    test('handles mixed success and failure concurrently without aborting other downloads',
        () async {
      final runner = MixedDownloadProcessRunner({
        'https://youtube.com/watch?v=fail': 1,
        'https://youtube.com/watch?v=success': 0,
      });

      // Create dummy executable to simulate yt-dlp binary presence
      final dummyBinary = File('${temporaryDirectory.path}/dummy_ytdlp.exe');
      await dummyBinary.writeAsString('mock');

      final executionService = DownloadExecutionService(
        historyService: historyService,
        processRunner: runner,
        ytDlpBinaryPath: dummyBinary.path,
        customDownloadsDirectory: downloadsDirectory,
      );

      final notifier = DownloadQueueNotifier(executionService: executionService);

      const format = VideoFormat(
        label: '1080p',
        type: FormatType.videoAndAudio,
        fileExtension: 'mp4',
      );

      const failInfo = VideoInfo(
        title: 'Failing Video',
        thumbnailUrl: '',
        durationSeconds: 60,
        formats: [format],
      );

      const successInfo = VideoInfo(
        title: 'Successful Video',
        thumbnailUrl: '',
        durationSeconds: 120,
        formats: [format],
      );

      notifier.addQueueItem(failInfo, format, videoUrl: 'https://youtube.com/watch?v=fail');
      notifier.addQueueItem(successInfo, format, videoUrl: 'https://youtube.com/watch?v=success');

      expect(notifier.state.length, 2);

      await notifier.startQueuedDownloads();

      final failedItem = notifier.state.firstWhere((i) => i.videoInfo.title == 'Failing Video');
      final successItem =
          notifier.state.firstWhere((i) => i.videoInfo.title == 'Successful Video');

      expect(failedItem.status, equals(QueueItemStatus.failed));
      expect(failedItem.errorMessage, isNotNull);
      // Ensure raw Python traceback was sanitized
      expect(failedItem.errorMessage, isNot(contains('Traceback')));
      expect(
        failedItem.errorMessage,
        equals('This video is private, restricted, or requires an account.'),
      );

      expect(successItem.status, equals(QueueItemStatus.completed));
      expect(successItem.progressPercent, equals(100.0));
      expect(successItem.downloadedFilePath, isNotNull);

      // Verify history store contains only the successful download
      final history = await historyService.getHistory();
      expect(history.length, 1);
      expect(history.first.title, 'Successful Video');
    });

    test('sanitizes various exception types into clean user-friendly error messages', () {
      expect(
        DownloadQueueNotifier.sanitizeDownloadErrorMessage(
          Exception('ERROR: [youtube] 12345: Private video. Sign in if you have access'),
        ),
        equals('This video is private, restricted, or requires an account.'),
      );

      expect(
        DownloadQueueNotifier.sanitizeDownloadErrorMessage(
          const SocketException('Failed host lookup: www.instagram.com'),
        ),
        equals('Network connection error. Please check your internet connection.'),
      );

      expect(
        DownloadQueueNotifier.sanitizeDownloadErrorMessage(
          const FileSystemException('No space left on device, errno = 28'),
        ),
        equals('Insufficient disk space to save the downloaded file.'),
      );

      expect(
        DownloadQueueNotifier.sanitizeDownloadErrorMessage(
          Exception('HTTP Error 403: Forbidden'),
        ),
        equals('Access to video stream was forbidden by the server.'),
      );

      expect(
        DownloadQueueNotifier.sanitizeDownloadErrorMessage(
          Exception('ERROR: Video unavailable. This video is no longer available.'),
        ),
        equals('This video is unavailable or has been removed.'),
      );
    });

    test('deduplicates accurately by URL when videos share identical generic titles', () {
      final notifier = DownloadQueueNotifier();
      const format = VideoFormat(
        label: '720p',
        type: FormatType.videoAndAudio,
        fileExtension: 'mp4',
      );

      const genericInfo1 = VideoInfo(
        title: 'Instagram Video',
        thumbnailUrl: '',
        durationSeconds: 15,
        formats: [format],
      );

      const genericInfo2 = VideoInfo(
        title: 'Instagram Video',
        thumbnailUrl: '',
        durationSeconds: 30,
        formats: [format],
      );

      final id1 = notifier.addQueueItem(
        genericInfo1,
        format,
        videoUrl: 'https://instagram.com/reel/first',
      );
      final id2 = notifier.addQueueItem(
        genericInfo2,
        format,
        videoUrl: 'https://instagram.com/reel/second',
      );

      // Distinct URLs must produce 2 distinct queue items despite identical titles
      expect(id1, isNot(equals(id2)));
      expect(notifier.state.length, equals(2));

      // Re-adding the exact same URL + format deduplicates to id1
      final duplicateId = notifier.addQueueItem(
        genericInfo1,
        format,
        videoUrl: 'https://instagram.com/reel/first',
      );
      expect(duplicateId, equals(id1));
      expect(notifier.state.length, equals(2));
    });
  });

  group('Phase 11 QA: File Collision & Overwriting Prevention', () {
    test('generates unique non-colliding file names when downloading duplicate or same-title media',
        () async {
      final executionService = DownloadExecutionService(
        historyService: historyService,
        customDownloadsDirectory: downloadsDirectory,
        processRunner: const MixedDownloadProcessRunner({}),
      );

      const format = VideoFormat(
        label: '1080p',
        type: FormatType.videoAndAudio,
        fileExtension: 'mp4',
      );

      const videoInfo = VideoInfo(
        title: 'My Favorite Reel',
        thumbnailUrl: '',
        durationSeconds: 45,
        formats: [format],
      );

      // First download
      final path1 = await executionService.executeDownload(
        url: 'https://youtube.com/watch?v=sample1',
        videoInfo: videoInfo,
        format: format,
        onProgress: (_) {},
      );

      // Second download of the same title
      final path2 = await executionService.executeDownload(
        url: 'https://youtube.com/watch?v=sample2',
        videoInfo: videoInfo,
        format: format,
        onProgress: (_) {},
      );

      // Third download of the same title
      final path3 = await executionService.executeDownload(
        url: 'https://youtube.com/watch?v=sample3',
        videoInfo: videoInfo,
        format: format,
        onProgress: (_) {},
      );

      expect(path1, endsWith('My Favorite Reel.mp4'));
      expect(path2, endsWith('My Favorite Reel (1).mp4'));
      expect(path3, endsWith('My Favorite Reel (2).mp4'));

      expect(File(path1).existsSync(), isTrue);
      expect(File(path2).existsSync(), isTrue);
      expect(File(path3).existsSync(), isTrue);

      final history = await historyService.getHistory();
      expect(history.length, 3);
      expect(history.map((h) => h.filePath).toSet().length, 3);
    });
  });

  group('Phase 11 QA: Share Intent Failure Notification (No Silent Failure)', () {
    test('notifies user when shared video details extraction fails', () async {
      final notifier = DownloadQueueNotifier();
      String? notifiedMessage;

      final shareService = ShareIntentService(
        clipboardService: const ClipboardService(),
        extractionService: const FailingMockExtractionService(),
        downloadQueueNotifier: notifier,
        getQueueLength: () => notifier.state.length,
        showNativeToast: false,
        onConfirmation: (message) {
          notifiedMessage = message;
        },
      );

      await shareService.handleSharedText('https://instagram.com/reel/broken123');

      expect(notifiedMessage, isNotNull);
      expect(
        notifiedMessage,
        equals('Could not fetch shared video. Please check your connection or link.'),
      );
      expect(notifier.state.isEmpty, isTrue);
    });
  });

  group('Phase 11 QA: History & Settings Resilient Error Handling', () {
    testWidgets('HistoryScreen gracefully handles missing file with error snackbar',
        (tester) async {
      final historyItem = HistoryItem(
        id: '101',
        title: 'Playable Reel',
        thumbnailUrl: '',
        filePath: '/invalid/path/that/does/not/exist.mp4',
        format: '1080p (Video + Audio)',
        fileSizeMB: 12.5,
        downloadedAt: DateTime(2026, 9, 14),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            historyServiceProvider.overrideWithValue(historyService),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HistoryScreen(
              customHistoryService: historyService,
              initialItems: [historyItem],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap play button on missing file
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should show user-friendly snackbar and not crash
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('File not found at'), findsOneWidget);
    });

    test('SettingsScreen.formatFriendlyErrorMessage sanitizes raw FileSystemException and stack traces', () {
      const osError = OSError('Permission denied', 13);
      const fsException = FileSystemException('Cannot delete', '/data/user/cache', osError);

      final friendlyMessage = SettingsScreen.formatFriendlyErrorMessage(fsException);
      expect(friendlyMessage, equals('Permission denied'));
      expect(friendlyMessage, isNot(contains('FileSystemException')));
      expect(friendlyMessage, isNot(contains('errno')));

      final genericError = Exception('Generic operation failure\nAt line 45');
      expect(SettingsScreen.formatFriendlyErrorMessage(genericError), equals('Generic operation failure'));
    });

    test('ExtractionService throws descriptive user-friendly exception on yt-dlp failure',
        () async {
      final dummyScript = File('${temporaryDirectory.path}/mock_fail_ytdlp.bat');
      await dummyScript.writeAsString('@exit /b 1');

      final extractionService = ExtractionService(
        ytDlpBinaryPath: dummyScript.path,
      );

      expect(
        () => extractionService.fetchDetails('https://youtube.com/watch?v=fails'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
