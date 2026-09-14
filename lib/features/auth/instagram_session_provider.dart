import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'instagram_session_service.dart';

/// State representation for Instagram authentication session.
class InstagramAuthState {
  final bool isAuthenticated;
  final String? userId;
  final bool isLoading;

  const InstagramAuthState({
    required this.isAuthenticated,
    this.userId,
    this.isLoading = false,
  });

  InstagramAuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    bool? isLoading,
  }) {
    return InstagramAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State notifier managing Instagram authentication session state.
class InstagramSessionNotifier extends StateNotifier<InstagramAuthState> {
  final InstagramSessionService sessionService;

  InstagramSessionNotifier({
    required this.sessionService,
  }) : super(const InstagramAuthState(isAuthenticated: false, isLoading: true)) {
    loadSession();
  }

  /// Refreshes and loads current session state from secure storage.
  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);
    final isAuthenticated = await sessionService.hasValidSession();
    final userId = isAuthenticated ? await sessionService.getUserId() : null;
    state = InstagramAuthState(
      isAuthenticated: isAuthenticated,
      userId: userId,
      isLoading: false,
    );
  }

  /// Sets session tokens as authenticated and refreshes state.
  Future<void> setAuthenticated({
    required String sessionId,
    String? csrfToken,
    String? dsUserId,
  }) async {
    await sessionService.saveSession(
      sessionId: sessionId,
      csrfToken: csrfToken,
      dsUserId: dsUserId,
    );
    state = InstagramAuthState(
      isAuthenticated: true,
      userId: dsUserId,
      isLoading: false,
    );
  }

  /// Wipes session tokens and resets state to unauthenticated.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await sessionService.clearSession();
    state = const InstagramAuthState(
      isAuthenticated: false,
      userId: null,
      isLoading: false,
    );
  }
}

/// Provider for [InstagramSessionNotifier].
final instagramSessionProvider =
    StateNotifierProvider<InstagramSessionNotifier, InstagramAuthState>((ref) {
  final sessionService = ref.watch(instagramSessionServiceProvider);
  return InstagramSessionNotifier(sessionService: sessionService);
});
