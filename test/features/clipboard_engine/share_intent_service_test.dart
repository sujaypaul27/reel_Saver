import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_service.dart';
import 'package:reel_saver/features/clipboard_engine/share_intent_service.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/queue_item.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';
import 'package:reel_saver/features/download_engine/queue_service.dart';

class MockSharingIntentReceiver implements SharingIntentReceiver {
  List<SharedMediaFile> initialMedia = [];
  final StreamController<List<SharedMediaFile>> mediaStreamController =
      StreamController<List<SharedMediaFile>>.broadcast();
  bool resetCalled = false;

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async => initialMedia;

  @override
  Stream<List<SharedMediaFile>> getMediaStream() => mediaStreamController.stream;

  @override
  Future<void> reset() async {
    resetCalled = true;
  }

  void dispose() {
    mediaStreamController.close();
  }
}

class FakeExtractionService extends ExtractionService {
  final Map<String, VideoInfo> responses;

  const FakeExtractionService({required this.responses});

  @override
  Future<VideoInfo> fetchDetails(String url) async {
    if (responses.containsKey(url)) {
      return responses[url]!;
    }
    return VideoInfo(
      title: 'Extracted: $url',
      thumbnailUrl: 'https://example.com/thumb.jpg',
      durationSeconds: 45,
      formats: const [
        VideoFormat(
          label: '1080p',
          type: FormatType.videoAndAudio,
          fileExtension: 'mp4',
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareIntentService Tests', () {
    late ClipboardService clipboardService;
    late FakeExtractionService extractionService;
    late DownloadQueueNotifier queueNotifier;
    late MockSharingIntentReceiver mockReceiver;
    late List<String> confirmations;
    late ShareIntentService shareIntentService;

    setUp(() {
      clipboardService = const ClipboardService();
      extractionService = const FakeExtractionService(responses: {});
      queueNotifier = DownloadQueueNotifier();
      mockReceiver = MockSharingIntentReceiver();
      confirmations = [];

      shareIntentService = ShareIntentService(
        clipboardService: clipboardService,
        extractionService: extractionService,
        downloadQueueNotifier: queueNotifier,
        getQueueLength: () => queueNotifier.state.length,
        sharingReceiver: mockReceiver,
        onConfirmation: (message) => confirmations.add(message),
        showNativeToast: false,
      );
    });

    tearDown(() {
      shareIntentService.dispose();
      mockReceiver.dispose();
    });

    test('warm-start: shared Instagram Reel adds item to queue with null format and confirms', () async {
      await shareIntentService.initialize();

      const instagramUrl = 'https://www.instagram.com/reel/C8XYZ123/';
      mockReceiver.mediaStreamController.add([
        SharedMediaFile(
          path: instagramUrl,
          type: SharedMediaType.text,
        ),
      ]);

      // Allow async background extraction & queue addition to settle
      await pumpEventQueue();

      expect(queueNotifier.state.length, equals(1));
      final item = queueNotifier.state.first;
      expect(item.videoUrl, equals(instagramUrl));
      expect(item.selectedFormat, isNull);
      expect(item.status, equals(QueueItemStatus.queued));
      expect(item.progressPercent, equals(0.0));
      expect(confirmations, contains('Added to Download Cart (1 item)'));
    });

    test('warm-start: shared YouTube video adds to queue with null format and extracts title', () async {
      await shareIntentService.initialize();

      const youtubeUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      mockReceiver.mediaStreamController.add([
        SharedMediaFile(
          path: youtubeUrl,
          type: SharedMediaType.text,
        ),
      ]);

      await pumpEventQueue();

      expect(queueNotifier.state.length, equals(1));
      final item = queueNotifier.state.first;
      expect(item.videoUrl, equals(youtubeUrl));
      expect(item.selectedFormat, isNull);
      expect(item.videoInfo.title, contains(youtubeUrl));
      expect(item.status, equals(QueueItemStatus.queued));
    });

    test('cold-start: initial shared URL processes on initialize, adds to queue, and resets intent', () async {
      const initialInstagramUrl = 'https://www.instagram.com/p/C9ABC456/';
      mockReceiver.initialMedia = [
        SharedMediaFile(
          path: initialInstagramUrl,
          type: SharedMediaType.text,
        ),
      ];

      await shareIntentService.initialize();
      await pumpEventQueue();

      expect(queueNotifier.state.length, equals(1));
      final item = queueNotifier.state.first;
      expect(item.videoUrl, equals(initialInstagramUrl));
      expect(item.selectedFormat, isNull);
      expect(mockReceiver.resetCalled, isTrue);
      expect(confirmations, contains('Added to Download Cart (1 item)'));
    });

    test('invalid content: non-media or random text is silently ignored', () async {
      await shareIntentService.initialize();

      mockReceiver.mediaStreamController.add([
        SharedMediaFile(
          path: 'Hey check out this link: https://google.com/search?q=test',
          type: SharedMediaType.text,
        ),
        SharedMediaFile(
          path: 'Just plain text message without links',
          type: SharedMediaType.text,
        ),
      ]);

      await pumpEventQueue();

      expect(queueNotifier.state, isEmpty);
      expect(confirmations, isEmpty);
    });

    test('embedded URL: extracts valid reel URL even when wrapped in text', () async {
      await shareIntentService.initialize();

      mockReceiver.mediaStreamController.add([
        SharedMediaFile(
          path: 'Look at this funny reel! https://www.instagram.com/reel/D12345/ shared via Instagram',
          type: SharedMediaType.text,
        ),
      ]);

      await pumpEventQueue();

      expect(queueNotifier.state.length, equals(1));
      expect(
        queueNotifier.state.first.videoUrl,
        equals('https://www.instagram.com/reel/D12345/'),
      );
    });

    test('duplicate shared URL is not added twice', () async {
      await shareIntentService.initialize();

      const reelUrl = 'https://www.instagram.com/reel/C8XYZ123/';
      await shareIntentService.handleSharedText(reelUrl);
      await shareIntentService.handleSharedText(reelUrl);

      expect(queueNotifier.state.length, equals(1));
    });

    test('does NOT trigger automatic downloading upon share intent', () async {
      await shareIntentService.initialize();

      await shareIntentService.handleSharedText('https://youtu.be/sample123');

      expect(queueNotifier.state.length, equals(1));
      expect(queueNotifier.state.first.status, equals(QueueItemStatus.queued));
      expect(queueNotifier.state.first.progressPercent, equals(0.0));
    });
  });
}
