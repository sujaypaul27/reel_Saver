import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

/// Exception thrown when an authenticated request to Instagram fails because the
/// session has expired or the token is no longer valid.
class InstagramSessionExpiredException implements Exception {
  final String message;
  const InstagramSessionExpiredException([
    this.message = 'Instagram session expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

/// Exception thrown when an Instagram Reel requires login/authentication to access
/// and the user is currently unauthenticated.
class InstagramAuthRequiredException implements Exception {
  final String message;
  const InstagramAuthRequiredException([
    this.message = 'Instagram login required for this Reel. Please log in via Settings.',
  ]);

  @override
  String toString() => message;
}

/// Service responsible for securely persisting, retrieving, and clearing
/// Instagram authentication session tokens.
///
/// Security: Session tokens (sessionid, csrftoken, ds_user_id) are stored exclusively
/// in [FlutterSecureStorage] (backed by Android Keystore / iOS Keychain).
/// Plaintext cookies are NEVER logged or printed anywhere.
class InstagramSessionService {
  static const String _keySessionId = 'instagram_session_id';
  static const String _keyCsrfToken = 'instagram_csrf_token';
  static const String _keyUserId = 'instagram_user_id';
  static const String _keyCookieHeader = 'instagram_cookie_header';

  final FlutterSecureStorage secureStorage;
  final WebviewCookieManager? webviewCookieManager;

  const InstagramSessionService({
    this.secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ),
    this.webviewCookieManager,
  });

  /// Checks if a valid, non-empty session ID is stored.
  Future<bool> hasValidSession() async {
    try {
      final sessionId = await secureStorage.read(key: _keySessionId);
      return sessionId != null && sessionId.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves the pre-formatted `Cookie: ...` header string for HTTP requests.
  /// Returns null if no valid session exists.
  Future<String?> getCookieHeader() async {
    try {
      final header = await secureStorage.read(key: _keyCookieHeader);
      if (header != null && header.trim().isNotEmpty) {
        return header.trim();
      }

      final sessionId = await secureStorage.read(key: _keySessionId);
      if (sessionId == null || sessionId.trim().isEmpty) {
        return null;
      }

      final csrfToken = await secureStorage.read(key: _keyCsrfToken);
      final userId = await secureStorage.read(key: _keyUserId);

      final buffer = StringBuffer('sessionid=$sessionId');
      if (csrfToken != null && csrfToken.trim().isNotEmpty) {
        buffer.write('; csrftoken=$csrfToken');
      }
      if (userId != null && userId.trim().isNotEmpty) {
        buffer.write('; ds_user_id=$userId');
      }

      final constructedHeader = buffer.toString();
      await secureStorage.write(
        key: _keyCookieHeader,
        value: constructedHeader,
      );
      return constructedHeader;
    } catch (_) {
      return null;
    }
  }

  /// Retrieves the saved Instagram User ID (`ds_user_id`), if available.
  Future<String?> getUserId() async {
    try {
      return await secureStorage.read(key: _keyUserId);
    } catch (_) {
      return null;
    }
  }

  /// Saves extracted session cookies securely.
  Future<void> saveSession({
    required String sessionId,
    String? csrfToken,
    String? dsUserId,
  }) async {
    final cleanSessionId = sessionId.trim();
    if (cleanSessionId.isEmpty) return;

    final buffer = StringBuffer('sessionid=$cleanSessionId');
    await secureStorage.write(key: _keySessionId, value: cleanSessionId);

    if (csrfToken != null && csrfToken.trim().isNotEmpty) {
      final cleanCsrf = csrfToken.trim();
      await secureStorage.write(key: _keyCsrfToken, value: cleanCsrf);
      buffer.write('; csrftoken=$cleanCsrf');
    }

    if (dsUserId != null && dsUserId.trim().isNotEmpty) {
      final cleanUser = dsUserId.trim();
      await secureStorage.write(key: _keyUserId, value: cleanUser);
      buffer.write('; ds_user_id=$cleanUser');
    }

    await secureStorage.write(
      key: _keyCookieHeader,
      value: buffer.toString(),
    );
  }

  /// Clears all stored Instagram session tokens from secure storage
  /// and wipes cookies from the WebView cookie store.
  Future<void> clearSession() async {
    try {
      await secureStorage.delete(key: _keySessionId);
      await secureStorage.delete(key: _keyCsrfToken);
      await secureStorage.delete(key: _keyUserId);
      await secureStorage.delete(key: _keyCookieHeader);
    } catch (_) {}

    try {
      final cookieManager = webviewCookieManager ?? WebviewCookieManager();
      await cookieManager.clearCookies();
    } catch (_) {}
  }
}

/// Riverpod provider for [InstagramSessionService].
final instagramSessionServiceProvider =
    Provider<InstagramSessionService>((ref) {
  return const InstagramSessionService();
});
