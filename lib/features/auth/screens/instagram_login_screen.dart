import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../instagram_session_provider.dart';

/// Screen hosting an official Instagram login page within a WebView.
///
/// Once the user successfully signs in, Instagram session cookies (sessionid,
/// csrftoken, ds_user_id) are extracted from the native cookie store and
/// stored securely without plaintext logging.
class InstagramLoginScreen extends ConsumerStatefulWidget {
  final WebViewController? customController;
  final WebviewCookieManager? customCookieManager;

  const InstagramLoginScreen({
    super.key,
    this.customController,
    this.customCookieManager,
  });

  @override
  ConsumerState<InstagramLoginScreen> createState() =>
      _InstagramLoginScreenState();
}

class _InstagramLoginScreenState extends ConsumerState<InstagramLoginScreen> {
  late final WebViewController _controller;
  late final WebviewCookieManager _cookieManager;
  bool _isLoading = true;
  bool _isProcessingLogin = false;

  @override
  void initState() {
    super.initState();
    _cookieManager = widget.customCookieManager ?? WebviewCookieManager();

    if (widget.customController != null) {
      _controller = widget.customController!;
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (url) async {
              if (mounted) setState(() => _isLoading = false);
              await _checkForSessionCookies(url);
            },
            onNavigationRequest: (request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(
          Uri.parse('https://www.instagram.com/accounts/login/'),
        );
    }
  }

  /// Checks if the WebView has acquired the Instagram sessionid cookie.
  Future<void> _checkForSessionCookies(String currentUrl) async {
    if (_isProcessingLogin) return;

    try {
      final cookies =
          await _cookieManager.getCookies('https://www.instagram.com');
      String? sessionId;
      String? csrfToken;
      String? dsUserId;

      for (final cookie in cookies) {
        final name = cookie.name.toLowerCase().trim();
        if (name == 'sessionid') {
          sessionId = cookie.value.trim();
        } else if (name == 'csrftoken') {
          csrfToken = cookie.value.trim();
        } else if (name == 'ds_user_id') {
          dsUserId = cookie.value.trim();
        }
      }

      if (sessionId != null && sessionId.isNotEmpty) {
        _isProcessingLogin = true;
        await ref.read(instagramSessionProvider.notifier).setAuthenticated(
              sessionId: sessionId,
              csrfToken: csrfToken,
              dsUserId: dsUserId,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged into Instagram successfully.'),
              duration: Duration(milliseconds: 2000),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (_) {
      // Avoid printing or re-throwing sensitive errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram Login'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isProcessingLogin)
            Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
