import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';
import 'package:reel_saver/features/home/screens/fetching_details_screen.dart';
import 'package:reel_saver/features/home/screens/home_screen.dart';
import 'package:reel_saver/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubExtractionService extends ExtractionService {
  final VideoInfo stubResponse;

  const StubExtractionService({required this.stubResponse});

  @override
  Future<VideoInfo> fetchDetails(String url) async => stubResponse;
}

void main() {
  const sampleVideo = VideoInfo(
    title: 'Queue UI Test Reel',
    thumbnailUrl: '',
    durationSeconds: 90,
    formats: [
      VideoFormat(
        label: '1080p',
        type: FormatType.videoAndAudio,
        fileExtension: 'mp4',
        estimatedSizeMB: 30.0,
        height: 1080,
      ),
      VideoFormat(
        label: '720p',
        type: FormatType.videoOnly,
        fileExtension: 'mp4',
        estimatedSizeMB: 15.0,
        height: 720,
      ),
    ],
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Queue UI Integration Tests', () {
    testWidgets('checking and unchecking boxes in FetchingDetailsScreen adds and removes from queue', (tester) async {
      final container = ProviderContainer(
        overrides: [
          extractionServiceProvider.overrideWithValue(
            const StubExtractionService(stubResponse: sampleVideo),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: FetchingDetailsScreen(videoUrl: 'https://youtube.com/watch?v=queueTest'),
          ),
        ),
      );

      // Settle extraction
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Check initial state: no queued items
      expect(container.read(downloadQueueProvider), isEmpty);
      expect(find.widgetWithText(ElevatedButton, 'Download Selected'), findsOneWidget);

      // Check the first checkbox (1080p)
      final firstCheckboxFinder = find.byType(Checkbox).first;
      await tester.tap(firstCheckboxFinder);
      await tester.pumpAndSettle();

      // Verify item was added to queue with status queued
      final queueAfterAdd = container.read(downloadQueueProvider);
      expect(queueAfterAdd.length, equals(1));
      expect(queueAfterAdd.first.selectedFormat?.label, equals('1080p'));
      expect(queueAfterAdd.first.status, equals(QueueItemStatus.queued));
      expect(find.widgetWithText(ElevatedButton, 'Download Selected (1)'), findsOneWidget);

      // Tap Download Selected
      await tester.tap(find.widgetWithText(ElevatedButton, 'Download Selected (1)'));
      await tester.pump();

      // Status should transition to downloading
      expect(
        container.read(downloadQueueProvider).first.status,
        equals(QueueItemStatus.downloading),
      );

      // Advance through simulated download timers
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('HomeScreen displays persistent bottom sheet when downloads are active and opens modal sheet', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No active downloads -> no bottom banner
      expect(find.textContaining('downloads in progress'), findsNothing);

      // Add a queued item to the queue provider
      container.read(downloadQueueProvider.notifier).addQueueItem(
            sampleVideo,
            sampleVideo.formats.first,
          );
      await tester.pumpAndSettle();

      // Now persistent banner appears on HomeScreen
      expect(find.text('1 download in progress'), findsOneWidget);
      expect(find.byIcon(Icons.downloading_rounded), findsOneWidget);

      // Tap the banner to open the bottom sheet
      await tester.tap(find.text('1 download in progress'));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.text('Download Queue'), findsOneWidget);
      expect(find.text('Queue UI Test Reel'), findsOneWidget);
      expect(find.text('Queued'), findsOneWidget);
      expect(find.text('Clear Completed'), findsOneWidget);
    });

    testWidgets('HomeScreen bottom sheet displays Select Quality button when selectedFormat is null', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add shared queue item with null format
      container.read(downloadQueueProvider.notifier).addSharedQueueItem(
            sampleVideo,
            videoUrl: 'https://instagram.com/reel/shared123',
          );
      await tester.pumpAndSettle();

      // Banner appears
      expect(find.text('1 download in progress'), findsOneWidget);

      // Open bottom sheet
      await tester.tap(find.text('1 download in progress'));
      await tester.pumpAndSettle();

      // Verifications for shared item awaiting format selection
      expect(find.text('Download Queue'), findsOneWidget);
      expect(find.text('Queue UI Test Reel'), findsOneWidget);
      expect(find.text('Quality not selected'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Select Quality'), findsOneWidget);
    });

    testWidgets('HomeScreen bottom sheet displays Failed badge and Retry button on error and shows dialog on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add item to queue
      final id = container.read(downloadQueueProvider.notifier).addQueueItem(
            sampleVideo,
            sampleVideo.formats.first,
          );

      // Simulate download failure on the item
      final currentQueue = container.read(downloadQueueProvider);
      container.read(downloadQueueProvider.notifier).state = [
        for (final it in currentQueue)
          if (it.id == id)
            it.copyWith(
              status: QueueItemStatus.failed,
              errorMessage: 'Network timeout connection aborted.',
            )
          else
            it,
      ];
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('1 download in progress'));
      await tester.pumpAndSettle();

      // Verify "Failed" indicator and "Retry" button
      expect(find.text('Failed'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

      // Tap "Failed" indicator to open error dialog
      await tester.tap(find.text('Failed'));
      await tester.pumpAndSettle();

      // Dialog is displayed with error message
      expect(find.text('Download Failed'), findsOneWidget);
      expect(find.text('Network timeout connection aborted.'), findsOneWidget);
      expect(find.text('Retry Download'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Download Failed'), findsNothing);
    });
  });
}
