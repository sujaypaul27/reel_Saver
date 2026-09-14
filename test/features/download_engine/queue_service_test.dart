import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';

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
      expect(item.selectedFormat.label, equals('1080p'));
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
      expect(queueNotifier.state.first.selectedFormat.label, equals('720p'));
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
      expect(queueNotifier.state.first.selectedFormat.label, equals('720p'));
    });
  });
}
