import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/download_execution_service.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';
import 'package:reel_saver/features/history/history_service.dart';

void main() {
  const sampleVideo = VideoInfo(
    title: 'Test Queue Reel',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    durationSeconds: 60,
    formats: [],
  );

  const format1080 = VideoFormat(
    label: '1080p',
    type: FormatType.videoAndAudio,
    fileExtension: 'mp4',
  );

  const format720 = VideoFormat(
    label: '720p',
    type: FormatType.videoOnly,
    fileExtension: 'mp4',
  );

  group('DownloadQueueNotifier Unit Tests', () {
    late DownloadQueueNotifier queueNotifier;

    setUp(() {
      queueNotifier = DownloadQueueNotifier();
    });

    test('adding an item stores it with status queued and 0% progress', () {
      final id = queueNotifier.addQueueItem(sampleVideo, format1080);

      expect(queueNotifier.state.length, equals(1));
      final item = queueNotifier.state.first;
      expect(item.id, equals(id));
      expect(item.videoInfo.title, equals('Test Queue Reel'));
      expect(item.selectedFormat?.label, equals('1080p'));
      expect(item.status, equals(QueueItemStatus.queued));
      expect(item.progressPercent, equals(0.0));
      expect(queueNotifier.isFormatQueued(sampleVideo, format1080), isTrue);
    });

    test('does not add duplicate entry for same video and format if already queued', () {
      final id1 = queueNotifier.addQueueItem(sampleVideo, format1080);
      final id2 = queueNotifier.addQueueItem(sampleVideo, format1080);

      expect(queueNotifier.state.length, equals(1));
      expect(id1, equals(id2));
    });

    test('removing an item removes it from the queue', () {
      queueNotifier.addQueueItem(sampleVideo, format1080);
      queueNotifier.addQueueItem(sampleVideo, format720);
      expect(queueNotifier.state.length, equals(2));

      queueNotifier.removeQueueItem(sampleVideo, format1080);
      expect(queueNotifier.state.length, equals(1));
      expect(queueNotifier.state.first.selectedFormat?.label, equals('720p'));
      expect(queueNotifier.isFormatQueued(sampleVideo, format1080), isFalse);
    });

    test('startQueuedDownloads transitions items to downloading then completed', () async {
      queueNotifier.addQueueItem(sampleVideo, format1080);
      queueNotifier.addQueueItem(sampleVideo, format720);

      final future = queueNotifier.startQueuedDownloads();

      // Check immediate downloading state
      expect(
        queueNotifier.state.every((item) => item.status == QueueItemStatus.downloading),
        isTrue,
      );

      await future;

      // Check completed state
      expect(
        queueNotifier.state.every((item) => item.status == QueueItemStatus.completed),
        isTrue,
      );
      expect(
        queueNotifier.state.every((item) => item.progressPercent == 100.0),
        isTrue,
      );
    });

    test('clearCompleted removes completed items while retaining queued ones', () async {
      queueNotifier.addQueueItem(sampleVideo, format1080);
      await queueNotifier.startQueuedDownloads();

      // Add another queued item
      queueNotifier.addQueueItem(sampleVideo, format720);
      expect(queueNotifier.state.length, equals(2));

      queueNotifier.clearCompleted();
      expect(queueNotifier.state.length, equals(1));
      expect(queueNotifier.state.first.selectedFormat?.label, equals('720p'));
    });

    test('addSharedQueueItem adds item with status queued and null selectedFormat', () {
      final id = queueNotifier.addSharedQueueItem(
        sampleVideo,
        videoUrl: 'https://instagram.com/reel/test',
      );

      expect(queueNotifier.state.length, equals(1));
      final item = queueNotifier.state.first;
      expect(item.id, equals(id));
      expect(item.selectedFormat, isNull);
      expect(item.videoUrl, equals('https://instagram.com/reel/test'));
      expect(item.status, equals(QueueItemStatus.queued));
    });

    test('startQueuedDownloads excludes items with null format, keeping them in cart', () async {
      // Add one item with format and one shared item with null format
      queueNotifier.addQueueItem(sampleVideo, format1080);
      queueNotifier.addSharedQueueItem(
        sampleVideo,
        videoUrl: 'https://instagram.com/reel/test',
      );

      expect(queueNotifier.state.length, equals(2));

      await queueNotifier.startQueuedDownloads();

      // Item with format completed download
      final formatItem = queueNotifier.state.firstWhere((i) => i.selectedFormat != null);
      expect(formatItem.status, equals(QueueItemStatus.completed));
      expect(formatItem.progressPercent, equals(100.0));

      // Item with null format was skipped and remained queued
      final sharedItem = queueNotifier.state.firstWhere((i) => i.selectedFormat == null);
      expect(sharedItem.status, equals(QueueItemStatus.queued));
      expect(sharedItem.progressPercent, equals(0.0));
    });

    test('addQueueItem upgrades existing unselected placeholder item with chosen format', () {
      // User shared item to cart
      final sharedId = queueNotifier.addSharedQueueItem(
        sampleVideo,
        videoUrl: 'https://instagram.com/reel/test',
      );
      expect(queueNotifier.state.length, equals(1));
      expect(queueNotifier.state.first.selectedFormat, isNull);

      // User later selects format via format selector
      final upgradedId = queueNotifier.addQueueItem(
        sampleVideo,
        format1080,
        videoUrl: 'https://instagram.com/reel/test',
      );

      expect(queueNotifier.state.length, equals(1));
      expect(upgradedId, equals(sharedId));
      expect(queueNotifier.state.first.selectedFormat?.label, equals('1080p'));
    });

    test('handles download execution failure and updates item status and errorMessage', () async {
      final failingExecutionService = _FailingExecutionService();
      final failingNotifier = DownloadQueueNotifier(
        executionService: failingExecutionService,
      );

      final id = failingNotifier.addQueueItem(sampleVideo, format1080);
      await failingNotifier.startQueuedDownloads();

      expect(failingNotifier.state.length, equals(1));
      final failedItem = failingNotifier.state.first;
      expect(failedItem.id, equals(id));
      expect(failedItem.status, equals(QueueItemStatus.failed));
      expect(failedItem.errorMessage, contains('Simulated download network error'));
    });

    test('retryDownload re-triggers execution for a failed item', () async {
      final mockExecutionService = _TogglingExecutionService();
      final retryNotifier = DownloadQueueNotifier(
        executionService: mockExecutionService,
      );

      final id = retryNotifier.addQueueItem(sampleVideo, format1080);
      // First attempt fails
      await retryNotifier.startQueuedDownloads();
      expect(retryNotifier.state.first.status, equals(QueueItemStatus.failed));

      // Retry attempt succeeds
      await retryNotifier.retryDownload(id);
      expect(retryNotifier.state.first.status, equals(QueueItemStatus.completed));
      expect(retryNotifier.state.first.progressPercent, equals(100.0));
      expect(retryNotifier.state.first.errorMessage, isNull);
    });
  });
}

class _FailingExecutionService extends DownloadExecutionService {
  _FailingExecutionService()
      : super(
          historyService: HistoryService(customHistoryFile: null),
        );

  @override
  Future<String> executeDownload({
    required String url,
    required VideoInfo videoInfo,
    required VideoFormat format,
    required void Function(double progressPercent) onProgress,
  }) async {
    throw Exception('Simulated download network error');
  }
}

class _TogglingExecutionService extends DownloadExecutionService {
  bool shouldFail = true;

  _TogglingExecutionService()
      : super(
          historyService: HistoryService(customHistoryFile: null),
        );

  @override
  Future<String> executeDownload({
    required String url,
    required VideoInfo videoInfo,
    required VideoFormat format,
    required void Function(double progressPercent) onProgress,
  }) async {
    if (shouldFail) {
      shouldFail = false;
      throw Exception('Initial attempt failed');
    }
    onProgress(100.0);
    return '/storage/sample.mp4';
  }
}

