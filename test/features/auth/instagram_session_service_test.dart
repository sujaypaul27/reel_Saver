import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/auth/instagram_session_provider.dart';
import 'package:reel_saver/features/auth/instagram_session_service.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

class FakeWebviewCookieManager extends Fake implements WebviewCookieManager {
  bool cookiesCleared = false;

  @override
  Future<void> clearCookies() async {
    cookiesCleared = true;
  }
}

void main() {
  group('InstagramSessionService Tests', () {
    late FakeSecureStorage fakeStorage;
    late FakeWebviewCookieManager fakeCookieManager;
    late InstagramSessionService sessionService;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      fakeCookieManager = FakeWebviewCookieManager();
      sessionService = InstagramSessionService(
        secureStorage: fakeStorage,
        webviewCookieManager: fakeCookieManager,
      );
    });

    test('hasValidSession returns false when no session ID is stored', () async {
      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getCookieHeader(), isNull);
    });

    test('saveSession writes tokens and constructs cookie header', () async {
      await sessionService.saveSession(
        sessionId: 'test_session_123',
        csrfToken: 'test_csrf_456',
        dsUserId: '987654321',
      );

      expect(await sessionService.hasValidSession(), isTrue);
      expect(await sessionService.getUserId(), equals('987654321'));

      final cookieHeader = await sessionService.getCookieHeader();
      expect(cookieHeader, contains('sessionid=test_session_123'));
      expect(cookieHeader, contains('csrftoken=test_csrf_456'));
      expect(cookieHeader, contains('ds_user_id=987654321'));
    });

    test('clearSession wipes stored tokens and calls clearCookies', () async {
      await sessionService.saveSession(
        sessionId: 'temp_session',
        csrfToken: 'temp_csrf',
        dsUserId: '123',
      );

      expect(await sessionService.hasValidSession(), isTrue);

      await sessionService.clearSession();

      expect(await sessionService.hasValidSession(), isFalse);
      expect(await sessionService.getCookieHeader(), isNull);
      expect(await sessionService.getUserId(), isNull);
      expect(fakeCookieManager.cookiesCleared, isTrue);
    });
  });

  group('InstagramSessionNotifier Tests', () {
    late FakeSecureStorage fakeStorage;
    late InstagramSessionService sessionService;
    late InstagramSessionNotifier notifier;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      sessionService = InstagramSessionService(secureStorage: fakeStorage);
      notifier = InstagramSessionNotifier(sessionService: sessionService);
    });

    test('initializes as unauthenticated when storage is empty', () async {
      await notifier.loadSession();
      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.userId, isNull);
    });

    test('setAuthenticated updates state correctly', () async {
      await notifier.setAuthenticated(
        sessionId: 'new_session_abc',
        csrfToken: 'new_csrf_def',
        dsUserId: '555444',
      );

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.userId, equals('555444'));
      expect(await sessionService.hasValidSession(), isTrue);
    });

    test('logout resets state to unauthenticated', () async {
      await notifier.setAuthenticated(
        sessionId: 'session_to_logout',
        dsUserId: '111222',
      );

      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.logout();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.userId, isNull);
      expect(await sessionService.hasValidSession(), isFalse);
    });
  });
}
