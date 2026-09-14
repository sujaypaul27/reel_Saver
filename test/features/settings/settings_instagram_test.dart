import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/auth/instagram_session_service.dart';
import 'package:reel_saver/features/settings/settings_screen.dart';
import 'package:reel_saver/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  }) async =>
      values[key];

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

class FakeWebviewCookieManager extends Fake implements WebViewCookieManager {
  bool cookiesCleared = false;

  @override
  Future<bool> clearCookies() async {
    cookiesCleared = true;
    return true;
  }
}

Widget buildTestableWidget({
  required InstagramSessionService sessionService,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      instagramSessionServiceProvider.overrideWithValue(sessionService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders Instagram Login tile when unauthenticated', (tester) async {
    final fakeStorage = FakeSecureStorage();
    final sessionService = InstagramSessionService(secureStorage: fakeStorage);

    await tester.pumpWidget(
      buildTestableWidget(
        sessionService: sessionService,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Instagram Authentication'), findsOneWidget);
    expect(
      find.text('Instagram Login (for private/restricted content)'),
      findsOneWidget,
    );
    expect(
      find.text('Log in via Instagram to download restricted reels and avoid login walls'),
      findsOneWidget,
    );
    expect(find.text('Logout / Clear Instagram Session'), findsNothing);
  });

  testWidgets('renders active session badge and logout tile when authenticated', (tester) async {
    final fakeStorage = FakeSecureStorage();
    final sessionService = InstagramSessionService(secureStorage: fakeStorage);
    await sessionService.saveSession(
      sessionId: 'valid_session_abc',
      dsUserId: 'test_user_789',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        sessionService: sessionService,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Instagram Authentication'), findsOneWidget);
    expect(find.text('Instagram Session Active'), findsOneWidget);
    expect(find.text('Logged in (User ID: test_user_789)'), findsOneWidget);
    expect(find.text('Logged In'), findsOneWidget);
    expect(find.text('Logout / Clear Instagram Session'), findsOneWidget);
  });

  testWidgets('tapping Logout shows confirmation dialog and clears session on confirm', (tester) async {
    final fakeStorage = FakeSecureStorage();
    final fakeCookieManager = FakeWebviewCookieManager();
    final sessionService = InstagramSessionService(
      secureStorage: fakeStorage,
      webviewCookieManager: fakeCookieManager,
    );
    await sessionService.saveSession(
      sessionId: 'session_to_delete',
      dsUserId: 'user_to_delete',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        sessionService: sessionService,
        child: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the logout tile
    final logoutTile = find.text('Logout / Clear Instagram Session');
    expect(logoutTile, findsOneWidget);
    await tester.ensureVisible(logoutTile);
    await tester.pumpAndSettle();
    await tester.tap(logoutTile);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Logout from Instagram?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Confirm logout
    await tester.tap(find.text('Logout'));
    // Allow dialog transition to complete so showDialog returns
    await tester.pumpAndSettle();

    // Verify session was cleared
    expect(await sessionService.hasValidSession(), isFalse);
    expect(fakeCookieManager.cookiesCleared, isTrue);

    // Verify UI reflects unauthenticated state
    final loginTile =
        find.text('Instagram Login (for private/restricted content)');
    await tester.ensureVisible(loginTile);
    await tester.pumpAndSettle();
    expect(loginTile, findsOneWidget);
  });
}
