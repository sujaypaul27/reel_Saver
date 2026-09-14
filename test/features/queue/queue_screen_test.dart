import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';
import 'package:reel_saver/features/download_engine/queue_storage_service.dart';
import 'package:reel_saver/features/queue/screens/queue_screen.dart';
import 'package:reel_saver/l10n/app_localizations.dart';

class FakeQueueStorageService extends QueueStorageService {
  @override
  Future<List<QueueItem>> loadQueue() async => [];

  @override
  Future<void> saveQueue(List<QueueItem> queueItems) async {}
}

Widget createTestableQueueScreen({
  required List<QueueItem> initialItems,
}) {
  return ProviderScope(
    overrides: [
      queueStorageServiceProvider.overrideWithValue(FakeQueueStorageService()),
      downloadQueueProvider.overrideWith(
        (ref) => DownloadQueueNotifier(
          storageService: FakeQueueStorageService(),
          initialItems: initialItems,
        ),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: QueueScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const format720 = VideoFormat(
    label: '720p',
    type: FormatType.videoAndAudio,
    fileExtension: 'mp4',
    estimatedSizeMB: 25.0,
  );

  const format1080 = VideoFormat(
    label: '1080p',
    type: FormatType.videoAndAudio,
    fileExtension: 'mp4',
    estimatedSizeMB: 50.0,
  );

  const sampleVideo = VideoInfo(
    title: 'Flutter Tutorial Video',
    thumbnailUrl: '',
    durationSeconds: 120,
    formats: [format720, format1080],
  );

  group('QueueScreen Widget Tests', () {
    testWidgets('renders empty state when queue has no items', (tester) async {
      await tester.pumpWidget(createTestableQueueScreen(initialItems: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
      expect(find.text('No items in download queue.'), findsOneWidget);
    });

    testWidgets('renders queued, downloading, completed, and failed item cards',
        (tester) async {
      final items = [
        const QueueItem(
          id: '1',
          videoInfo: sampleVideo,
          selectedFormat: format1080,
          status: QueueItemStatus.queued,
        ),
        const QueueItem(
          id: '2',
          videoInfo: sampleVideo,
          selectedFormat: format720,
          status: QueueItemStatus.downloading,
          progressPercent: 45.0,
        ),
        const QueueItem(
          id: '3',
          videoInfo: sampleVideo,
          selectedFormat: format1080,
          status: QueueItemStatus.completed,
          progressPercent: 100.0,
        ),
        const QueueItem(
          id: '4',
          videoInfo: sampleVideo,
          selectedFormat: format720,
          status: QueueItemStatus.failed,
          errorMessage: 'Network timed out',
        ),
      ];

      await tester.pumpWidget(createTestableQueueScreen(initialItems: items));
      await tester.pump();

      // Verify status indicators and badges
      expect(find.text('Queued'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Network timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Verify FAB "Download All" is shown since queued item exists
      expect(find.text('Download All'), findsOneWidget);
    });

    testWidgets('tapping Select Quality opens format picker modal sheet',
        (tester) async {
      final items = [
        const QueueItem(
          id: 'shared_1',
          videoInfo: sampleVideo,
          selectedFormat: null, // Shared from external app
          status: QueueItemStatus.queued,
        ),
      ];

      await tester.pumpWidget(createTestableQueueScreen(initialItems: items));
      await tester.pumpAndSettle();

      expect(find.text('Select Quality'), findsOneWidget);
      await tester.tap(find.text('Select Quality'));
      await tester.pumpAndSettle();

      // Modal sheet should be open with format options
      expect(find.text('Select Format'), findsOneWidget);
      expect(find.text('720p (Video + Audio)'), findsOneWidget);
      expect(find.text('1080p (Video + Audio)'), findsOneWidget);

      // Tap 1080p option to assign quality
      await tester.tap(find.text('1080p (Video + Audio)'));
      await tester.pumpAndSettle();

      // Format should now be upgraded and badge displayed
      expect(find.text('1080p (Video + Audio)'), findsOneWidget);
    });

    testWidgets('tapping delete icon button removes item from queue',
        (tester) async {
      final items = [
        const QueueItem(
          id: 'delete_test_1',
          videoInfo: sampleVideo,
          selectedFormat: format720,
          status: QueueItemStatus.queued,
        ),
      ];

      await tester.pumpWidget(createTestableQueueScreen(initialItems: items));
      await tester.pumpAndSettle();

      expect(find.text('Flutter Tutorial Video'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No items in download queue.'), findsOneWidget);
    });

    testWidgets('Clear Completed button clears finished items from queue',
        (tester) async {
      final items = [
        const QueueItem(
          id: 'done_1',
          videoInfo: sampleVideo,
          selectedFormat: format1080,
          status: QueueItemStatus.completed,
        ),
      ];

      await tester.pumpWidget(createTestableQueueScreen(initialItems: items));
      await tester.pumpAndSettle();

      expect(find.text('Clear Completed'), findsOneWidget);
      await tester.tap(find.text('Clear Completed'));
      await tester.pumpAndSettle();

      expect(find.text('No items in download queue.'), findsOneWidget);
    });
  });
}
