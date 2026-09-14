import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_service.dart';
import 'package:reel_saver/features/clipboard_engine/clipboard_watcher.dart';
import 'package:reel_saver/features/clipboard_engine/models/clipboard_status.dart';
import 'package:reel_saver/features/clipboard_engine/models/url_type.dart';

class FakeClipboardService extends ClipboardService {
  String? mockClipboardText;

  FakeClipboardService({this.mockClipboardText});

  @override
  Future<String?> readClipboard() async {
    return mockClipboardText;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardService URL Detection', () {
    const clipboardService = ClipboardService();

    test('detects valid YouTube URLs correctly', () {
      final validYoutubeUrls = [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'http://youtube.com/watch?v=dQw4w9WgXcQ',
        'youtube.com/watch?v=dQw4w9WgXcQ',
        'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'http://youtu.be/dQw4w9WgXcQ',
        'youtu.be/dQw4w9WgXcQ',
        'https://www.youtube.com/shorts/3O2f8nQv6A8',
        'http://youtube.com/shorts/3O2f8nQv6A8',
        'youtube.com/shorts/3O2f8nQv6A8',
        'HTTPS://YOUTU.BE/ABCDEF12345',
        '  https://www.youtube.com/watch?v=trimmed  ',
      ];

      for (final url in validYoutubeUrls) {
        expect(
          clipboardService.detectUrlType(url),
          equals(UrlType.youtube),
          reason: 'Expected $url to be detected as YouTube URL',
        );
      }
    });

    test('detects valid Instagram URLs correctly', () {
      final validInstagramUrls = [
        'https://www.instagram.com/reel/C8XYZ123/',
        'http://instagram.com/reel/C8XYZ123/',
        'instagram.com/reel/C8XYZ123/',
        'https://www.instagram.com/p/C8XYZ123/',
        'http://instagram.com/p/C8XYZ123/',
        'instagram.com/p/C8XYZ123/',
        'https://www.instagram.com/tv/C8XYZ123/',
        'http://instagram.com/tv/C8XYZ123/',
        'instagram.com/tv/C8XYZ123/',
        'HTTPS://INSTAGRAM.COM/REEL/UPPERCASE/',
        '  https://instagram.com/reel/trimmed/  ',
      ];

      for (final url in validInstagramUrls) {
        expect(
          clipboardService.detectUrlType(url),
          equals(UrlType.instagram),
          reason: 'Expected $url to be detected as Instagram URL',
        );
      }
    });

    test('returns invalid for unsupported URLs and plain text', () {
      final invalidUrls = [
        'https://facebook.com/watch?v=123',
        'https://twitter.com/user/status/123',
        'https://tiktok.com/@user/video/123',
        'https://notyoutube.com/watch?v=123',
        'https://fakeinstagram.com/reel/123/',
        'Just a random message copied by the user',
        '',
        '   ',
      ];

      for (final url in invalidUrls) {
        expect(
          clipboardService.detectUrlType(url),
          equals(UrlType.invalid),
          reason: 'Expected "$url" to be detected as invalid',
        );
      }
    });

    test('reads text from system clipboard using platform channel', () async {
      const testClipboardText = 'https://youtu.be/sample-test-id';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': testClipboardText};
        }
        return null;
      });

      final result = await clipboardService.readClipboard();
      expect(result, equals(testClipboardText));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });

  group('ClipboardWatcher StateNotifier', () {
    test('initializes with idle status', () {
      final fakeService = FakeClipboardService(mockClipboardText: null);
      final watcher = ClipboardWatcher(clipboardService: fakeService);

      expect(watcher.state.status, equals(ClipboardDetectionStatus.idle));
      expect(watcher.state.url, isNull);
      expect(watcher.state.type, equals(UrlType.invalid));
      expect(watcher.isEnabled, isTrue);

      watcher.dispose();
    });

    test('detects new YouTube URL on lifecycle resumed', () async {
      const targetUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      final fakeService = FakeClipboardService(mockClipboardText: targetUrl);
      final watcher = ClipboardWatcher(clipboardService: fakeService);

      watcher.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(watcher.state.status, equals(ClipboardDetectionStatus.newUrlFound));
      expect(watcher.state.url, equals(targetUrl));
      expect(watcher.state.type, equals(UrlType.youtube));

      watcher.dispose();
    });

    test('detects new Instagram URL on inspectClipboard call', () async {
      const targetUrl = 'https://www.instagram.com/reel/C8XYZ123/';
      final fakeService = FakeClipboardService(mockClipboardText: targetUrl);
      final watcher = ClipboardWatcher(clipboardService: fakeService);

      await watcher.inspectClipboard();

      expect(watcher.state.status, equals(ClipboardDetectionStatus.newUrlFound));
      expect(watcher.state.url, equals(targetUrl));
      expect(watcher.state.type, equals(UrlType.instagram));

      watcher.dispose();
    });

    test('does not re-trigger for identical URL twice in a row', () async {
      const targetUrl = 'https://youtu.be/first-video';
      final fakeService = FakeClipboardService(mockClipboardText: targetUrl);
      final watcher = ClipboardWatcher(clipboardService: fakeService);

      await watcher.inspectClipboard();
      expect(watcher.state.status, equals(ClipboardDetectionStatus.newUrlFound));

      // Reset state to idle to observe if inspection re-triggers with the same text
      watcher.resetToIdle();
      expect(watcher.state.status, equals(ClipboardDetectionStatus.idle));

      await watcher.inspectClipboard();
      // Status should remain idle because the URL matches the cached last seen text
      expect(watcher.state.status, equals(ClipboardDetectionStatus.idle));

      watcher.dispose();
    });

    test('skips inspection entirely when isEnabled is false', () async {
      const targetUrl = 'https://www.youtube.com/shorts/example';
      final fakeService = FakeClipboardService(mockClipboardText: targetUrl);
      final watcher = ClipboardWatcher(
        clipboardService: fakeService,
        initialEnabled: false,
      );

      await watcher.inspectClipboard();
      expect(watcher.state.status, equals(ClipboardDetectionStatus.idle));
      expect(watcher.state.url, isNull);

      // Enable and re-test
      watcher.setEnabled(true);
      await watcher.inspectClipboard();
      expect(watcher.state.status, equals(ClipboardDetectionStatus.newUrlFound));
      expect(watcher.state.url, equals(targetUrl));

      watcher.dispose();
    });

    test('sets status to invalid when copied text is not a supported URL', () async {
      const plainText = 'Hello, this is a plain message with no links.';
      final fakeService = FakeClipboardService(mockClipboardText: plainText);
      final watcher = ClipboardWatcher(clipboardService: fakeService);

      await watcher.inspectClipboard();

      expect(watcher.state.status, equals(ClipboardDetectionStatus.invalid));
      expect(watcher.state.url, equals(plainText));
      expect(watcher.state.type, equals(UrlType.invalid));

      watcher.dispose();
    });
  });
}
