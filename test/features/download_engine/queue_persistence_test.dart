import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_service.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_watcher.dart';
import 'package:reel_saver/features/clipboard_engine/models/url_type.dart';
import 'package:reel_saver/features/clipboard_engine/share_intent_service.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';
import 'package:reel_saver/features/download_engine/queue_storage_service.dart';

class FakeClipboardService extends ClipboardService {
  @override
  UrlType detectUrlType(String url) {
    if (url.contains('instagram.com')) return UrlType.instagram;
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return UrlType.youtube;
    }
    return UrlType.invalid;
  }
}

class FakeExtractionService extends ExtractionService {
  @override
  Future<VideoInfo> fetchDetails(String url) async {
    return const VideoInfo(
      title: 'Shared Cold Start Video',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      durationSeconds: 45,
      formats: [
        VideoFormat(
          label: '1080p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
          estimatedSizeMB: 25.0,
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late File queueStorageFile;
  late QueueStorageService storageService;

  final sampleFormat = const VideoFormat(
    label: '1080p',
    type: FormatType.videoAndAudio,
    fileExtension: 'mp4',
    estimatedSizeMB: 42.5,
    height: 1080,
    bitrate: 4500,
  );

  final sampleVideoInfo = VideoInfo(
    title: 'Test Reel Video',
    thumbnailUrl: 'https://example.com/thumbnail.jpg',
    durationSeconds: 90,
    formats: [sampleFormat],
  );

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('reel_saver_queue_test_');
    queueStorageFile = File('${tempDirectory.path}/download_queue.json');
    storageService = QueueStorageService(customQueueFile: queueStorageFile);
  });

  tearDown(() async {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Phase 4.5b: Model JSON Serialization', () {
    test('VideoFormat serializes and deserializes accurately', () {
      final json = sampleFormat.toJson();
      final roundTrip = VideoFormat.fromJson(json);

      expect(roundTrip.label, equals(sampleFormat.label));
      expect(roundTrip.type, equals(sampleFormat.type));
      expect(roundTrip.fileExtension, equals(sampleFormat.fileExtension));
      expect(roundTrip.estimatedSizeMB, equals(sampleFormat.estimatedSizeMB));
      expect(roundTrip.height, equals(sampleFormat.height));
      expect(roundTrip.bitrate, equals(sampleFormat.bitrate));
      expect(roundTrip, equals(sampleFormat));
    });

    test('VideoInfo serializes and deserializes accurately', () {
      final json = sampleVideoInfo.toJson();
      final roundTrip = VideoInfo.fromJson(json);

      expect(roundTrip.title, equals(sampleVideoInfo.title));
      expect(roundTrip.thumbnailUrl, equals(sampleVideoInfo.thumbnailUrl));
      expect(roundTrip.durationSeconds, equals(sampleVideoInfo.durationSeconds));
      expect(roundTrip.formats.length, equals(1));
      expect(roundTrip.formats.first, equals(sampleFormat));
    });

    test('QueueItem serializes and deserializes accurately', () {
      final item = QueueItem(
        id: 'test_item_123',
        videoInfo: sampleVideoInfo,
        selectedFormat: sampleFormat,
        status: QueueItemStatus.completed,
        progressPercent: 100.0,
        videoUrl: 'https://instagram.com/reel/abc',
        downloadedFilePath: '/path/to/download.mp4',
      );

      final json = item.toJson();
      final roundTrip = QueueItem.fromJson(json);

      expect(roundTrip.id, equals(item.id));
      expect(roundTrip.videoInfo.title, equals(sampleVideoInfo.title));
      expect(roundTrip.selectedFormat, equals(sampleFormat));
      expect(roundTrip.status, equals(QueueItemStatus.completed));
      expect(roundTrip.progressPercent, equals(100.0));
      expect(roundTrip.videoUrl, equals('https://instagram.com/reel/abc'));
      expect(roundTrip.downloadedFilePath, equals('/path/to/download.mp4'));
      expect(roundTrip, equals(item));
    });
  });

  group('Phase 4.5b: QueueStorageService File Operations', () {
    test('returns empty list when storage file does not exist', () async {
      final items = await storageService.loadQueue();
      expect(items, isEmpty);
    });

    test('returns empty list when storage file is blank or corrupted', () async {
      queueStorageFile.writeAsStringSync('   ');
      final itemsFromBlank = await storageService.loadQueue();
      expect(itemsFromBlank, isEmpty);

      queueStorageFile.writeAsStringSync('{ invalid json [');
      final itemsFromCorrupted = await storageService.loadQueue();
      expect(itemsFromCorrupted, isEmpty);
    });

    test('saves and loads multiple queue items correctly', () async {
      final item1 = QueueItem(
        id: 'item_1',
        videoInfo: sampleVideoInfo,
        selectedFormat: sampleFormat,
        status: QueueItemStatus.queued,
      );
      final item2 = QueueItem(
        id: 'item_2',
        videoInfo: sampleVideoInfo,
        selectedFormat: sampleFormat,
        status: QueueItemStatus.completed,
        downloadedFilePath: '/path/video.mp4',
      );

      await storageService.saveQueue([item1, item2]);
      expect(queueStorageFile.existsSync(), isTrue);

      final loaded = await storageService.loadQueue();
      expect(loaded.length, equals(2));
      expect(loaded[0].id, equals('item_1'));
      expect(loaded[0].status, equals(QueueItemStatus.queued));
      expect(loaded[1].id, equals('item_2'));
      expect(loaded[1].status, equals(QueueItemStatus.completed));
    });

    test('resets status=downloading items to status=queued on load', () async {
      final itemInProgress = QueueItem(
        id: 'interrupted_dl_1',
        videoInfo: sampleVideoInfo,
        selectedFormat: sampleFormat,
        status: QueueItemStatus.downloading,
        progressPercent: 65.5,
      );

      await storageService.saveQueue([itemInProgress]);

      final loaded = await storageService.loadQueue();
      expect(loaded.length, equals(1));
      expect(loaded.first.id, equals('interrupted_dl_1'));
      // Requirement 3: Reset status=downloading to status=queued
      expect(loaded.first.status, equals(QueueItemStatus.queued));
      expect(loaded.first.progressPercent, equals(0.0));
      expect(loaded.first.errorMessage, isNull);
    });

    test('clearQueue writes empty list and wipes persisted file contents', () async {
      final item = QueueItem(
        id: 'to_clear',
        videoInfo: sampleVideoInfo,
        selectedFormat: sampleFormat,
      );
      await storageService.saveQueue([item]);
      expect(await storageService.loadQueue(), isNotEmpty);

      await storageService.clearQueue();
      expect(await storageService.loadQueue(), isEmpty);
    });
  });

  group('Phase 4.5b: DownloadQueueNotifier Persistence Across Mutations', () {
    test('adding item automatically serializes to JSON file', () async {
      final notifier = DownloadQueueNotifier(storageService: storageService);

      notifier.addQueueItem(
        sampleVideoInfo,
        sampleFormat,
        videoUrl: 'https://youtube.com/watch?v=123',
      );

      await notifier.saveToStorage();

      final reloadedItems = await storageService.loadQueue();
      expect(reloadedItems.length, equals(1));
      expect(reloadedItems.first.videoInfo.title, equals('Test Reel Video'));
      expect(reloadedItems.first.selectedFormat?.label, equals('1080p'));
      expect(reloadedItems.first.status, equals(QueueItemStatus.queued));
    });

    test('removing item automatically updates persistent storage', () async {
      final notifier = DownloadQueueNotifier(storageService: storageService);

      notifier.addQueueItem(sampleVideoInfo, sampleFormat);
      await notifier.saveToStorage();
      expect(await storageService.loadQueue(), hasLength(1));

      notifier.removeQueueItem(sampleVideoInfo, sampleFormat);
      await notifier.saveToStorage();
      expect(await storageService.loadQueue(), isEmpty);
    });

    test('upgrading shared placeholder item persists selectedFormat', () async {
      final notifier = DownloadQueueNotifier(storageService: storageService);

      notifier.addSharedQueueItem(
        sampleVideoInfo,
        videoUrl: 'https://instagram.com/reel/xyz',
      );
      await notifier.saveToStorage();

      final sharedLoaded = await storageService.loadQueue();
      expect(sharedLoaded.first.selectedFormat, isNull);

      notifier.addQueueItem(
        sampleVideoInfo,
        sampleFormat,
        videoUrl: 'https://instagram.com/reel/xyz',
      );
      await notifier.saveToStorage();

      final upgradedLoaded = await storageService.loadQueue();
      expect(upgradedLoaded.first.selectedFormat?.label, equals('1080p'));
    });
  });

  group('Phase 4.5b: Explicit Force-Kill and Cold Restart Verification', () {
    test(
        'Requirement 5: add items -> simulate force kill mid-download -> reopen app -> confirm items restored with correct status',
        () async {
      // 1. App running: User has 3 items in queue (one queued, one downloading, one completed)
      var activeNotifier = DownloadQueueNotifier(storageService: storageService);

      final idQueued = activeNotifier.addQueueItem(
        sampleVideoInfo,
        sampleFormat,
        videoUrl: 'https://youtube.com/watch?v=queued1',
      );

      final otherVideo = VideoInfo(
        title: 'Downloading Reel',
        thumbnailUrl: 'https://example.com/thumb2.jpg',
        durationSeconds: 30,
        formats: [sampleFormat],
      );
      final idDownloading = activeNotifier.addQueueItem(
        otherVideo,
        sampleFormat,
        videoUrl: 'https://youtube.com/watch?v=downloading2',
      );

      final completedVideo = VideoInfo(
        title: 'Completed Reel',
        thumbnailUrl: 'https://example.com/thumb3.jpg',
        durationSeconds: 60,
        formats: [sampleFormat],
      );
      final idCompleted = activeNotifier.addQueueItem(
        completedVideo,
        sampleFormat,
        videoUrl: 'https://youtube.com/watch?v=completed3',
      );

      // Simulate download status transition
      activeNotifier.state = [
        for (final item in activeNotifier.state)
          if (item.id == idDownloading)
            item.copyWith(
              status: QueueItemStatus.downloading,
              progressPercent: 54.0,
            )
          else if (item.id == idCompleted)
            item.copyWith(
              status: QueueItemStatus.completed,
              progressPercent: 100.0,
              downloadedFilePath: '/storage/ReelSaver/Completed Reel.mp4',
            )
          else
            item,
      ];

      // Explicitly wait for write flush
      await activeNotifier.saveToStorage();

      // 2. SIMULATE FORCE KILL: Process dies, notifier destroyed, memory wiped
      // Memory state is completely abandoned.

      // 3. REOPEN APP (COLD BOOT):
      // On app startup, QueueStorageService.loadQueue() is called before UI renders
      final coldStartQueue = await storageService.loadQueue();

      expect(coldStartQueue.length, equals(3));

      // Assert Item 1: was queued, remains queued
      final restoredQueued =
          coldStartQueue.firstWhere((item) => item.id == idQueued);
      expect(restoredQueued.status, equals(QueueItemStatus.queued));

      // Assert Item 2 (Requirement 3): was downloading mid-air, reset to queued with 0% progress
      final restoredDownloading =
          coldStartQueue.firstWhere((item) => item.id == idDownloading);
      expect(restoredDownloading.status, equals(QueueItemStatus.queued));
      expect(restoredDownloading.progressPercent, equals(0.0));
      expect(restoredDownloading.videoInfo.title, equals('Downloading Reel'));

      // Assert Item 3 (Requirement 4): was completed, remains completed
      final restoredCompleted =
          coldStartQueue.firstWhere((item) => item.id == idCompleted);
      expect(restoredCompleted.status, equals(QueueItemStatus.completed));
      expect(restoredCompleted.downloadedFilePath,
          equals('/storage/ReelSaver/Completed Reel.mp4'));

      // 4. Inject coldStartQueue into new DownloadQueueNotifier on startup
      final restartedNotifier = DownloadQueueNotifier(
        storageService: storageService,
        initialItems: coldStartQueue,
      );

      expect(restartedNotifier.state.length, equals(3));
    });

    test(
        'Requirement 4: completed items stay until user taps Clear Completed, which persists cleared state',
        () async {
      var notifier = DownloadQueueNotifier(storageService: storageService);

      notifier.addQueueItem(sampleVideoInfo, sampleFormat);
      // Mark as completed
      notifier.state = [
        notifier.state.first.copyWith(
          status: QueueItemStatus.completed,
          progressPercent: 100.0,
        ),
      ];
      await notifier.saveToStorage();

      // Cold restart: verify completed item remains
      var reloadedQueue = await storageService.loadQueue();
      expect(reloadedQueue.length, equals(1));
      expect(reloadedQueue.first.status, equals(QueueItemStatus.completed));

      // Tap Clear Completed
      notifier = DownloadQueueNotifier(
        storageService: storageService,
        initialItems: reloadedQueue,
      );
      notifier.clearCompleted();
      await notifier.saveToStorage();

      // Cold restart again: verify completed items are permanently removed from storage
      final finalQueue = await storageService.loadQueue();
      expect(finalQueue, isEmpty);
    });

    test(
        'Requirement 2: Share-intent while app terminated restores previous queue and appends new shared item',
        () async {
      // 1. User had 2 items saved previously
      await storageService.saveQueue([
        QueueItem(
          id: 'prev_item_1',
          videoInfo: sampleVideoInfo,
          selectedFormat: sampleFormat,
          status: QueueItemStatus.queued,
        ),
        QueueItem(
          id: 'prev_item_2',
          videoInfo: sampleVideoInfo,
          selectedFormat: sampleFormat,
          status: QueueItemStatus.completed,
        ),
      ]);

      // 2. Cold start: load queue from storage
      final startupQueue = await storageService.loadQueue();
      expect(startupQueue.length, equals(2));

      // 3. ProviderScope container configured with restored queue
      final container = ProviderContainer(
        overrides: [
          initialDownloadQueueProvider.overrideWithValue(startupQueue),
          queueStorageServiceProvider.overrideWithValue(storageService),
          clipboardServiceProvider.overrideWithValue(FakeClipboardService()),
          extractionServiceProvider.overrideWithValue(FakeExtractionService()),
        ],
      );

      // Verify queue is initialized with restored items BEFORE share intent runs
      final queueNotifier = container.read(downloadQueueProvider.notifier);
      expect(container.read(downloadQueueProvider).length, equals(2));

      // 4. Share intent received while app was opening
      final shareService = container.read(shareIntentServiceProvider);
      await shareService.handleSharedText('https://instagram.com/reel/shared_cold_start');

      // 5. Verify total queue length is now 3 (2 restored + 1 newly shared)
      final updatedQueue = container.read(downloadQueueProvider);
      expect(updatedQueue.length, equals(3));
      expect(updatedQueue.last.videoInfo.title, equals('Shared Cold Start Video'));
      expect(updatedQueue.last.selectedFormat, isNull); // Pending format selection

      await queueNotifier.saveToStorage();

      // 6. Verify storage file now has all 3 items persisted
      final storedOnDisk = await storageService.loadQueue();
      expect(storedOnDisk.length, equals(3));
      expect(storedOnDisk.last.videoInfo.title, equals('Shared Cold Start Video'));
    });
  });
}
