import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reel_saver/features/auth/instagram_session_service.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';

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
}

void main() {
  group('ExtractionService Instagram Authentication & Cookie Tests', () {
    test('sends Cookie header and parses video info when authenticated', () async {
      final fakeStorage = FakeSecureStorage();
      final sessionService = InstagramSessionService(secureStorage: fakeStorage);
      await sessionService.saveSession(
        sessionId: 'test_session_secret',
        csrfToken: 'csrf_secret',
        dsUserId: '1001',
      );

      String? capturedCookieHeader;

      final mockClient = MockClient((request) async {
        if (request.url.toString().contains('instagram.com')) {
          capturedCookieHeader = request.headers['Cookie'];

          final jsonResponse = {
            'items': [
              {
                'caption': {'text': 'Awesome Authenticated Reel'},
                'video_versions': [
                  {
                    'url': 'https://instagram.fsnc1-1.fna.fbcdn.net/v/test_video.mp4',
                  }
                ],
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://instagram.fsnc1-1.fna.fbcdn.net/v/thumb.jpg'}
                  ]
                }
              }
            ]
          };

          return http.Response(jsonEncode(jsonResponse), 200);
        }
        return http.Response('Not Found', 404);
      });

      final extractionService = ExtractionService(
        httpClient: mockClient,
        sessionService: sessionService,
      );

      final result = await extractionService.fetchDetails(
        'https://www.instagram.com/reel/C_Z4sQeM6_N/',
      );

      expect(capturedCookieHeader, contains('sessionid=test_session_secret'));
      expect(result.title, equals('Awesome Authenticated Reel'));
      expect(result.formats, isNotEmpty);
      expect(
        result.formats.first.downloadUrl,
        equals('https://instagram.fsnc1-1.fna.fbcdn.net/v/test_video.mp4'),
      );
    });

    test('throws InstagramSessionExpiredException when authenticated session encounters login wall', () async {
      final fakeStorage = FakeSecureStorage();
      final sessionService = InstagramSessionService(secureStorage: fakeStorage);
      await sessionService.saveSession(
        sessionId: 'expired_session_token',
      );

      final mockClient = MockClient((request) async {
        // Return Instagram login redirect HTML shell
        return http.Response(
          '<!DOCTYPE html><html class="_9dls _ar44"><title>Instagram</title>accounts/login</html>',
          200,
        );
      });

      final extractionService = ExtractionService(
        httpClient: mockClient,
        sessionService: sessionService,
      );

      expect(
        () => extractionService.fetchDetails(
          'https://www.instagram.com/reel/C_Z4sQeM6_N/',
        ),
        throwsA(isA<InstagramSessionExpiredException>()),
      );
    });

    test('throws InstagramAuthRequiredException when unauthenticated request encounters login wall', () async {
      final fakeStorage = FakeSecureStorage();
      final sessionService = InstagramSessionService(secureStorage: fakeStorage);

      final mockClient = MockClient((request) async {
        return http.Response(
          '<!DOCTYPE html><html class="_9dls _ar44"><title>Login - Instagram</title>accounts/login</html>',
          200,
        );
      });

      final extractionService = ExtractionService(
        httpClient: mockClient,
        sessionService: sessionService,
      );

      expect(
        () => extractionService.fetchDetails(
          'https://www.instagram.com/reel/C_Z4sQeM6_N/',
        ),
        throwsA(isA<InstagramAuthRequiredException>()),
      );
    });
  });
}
