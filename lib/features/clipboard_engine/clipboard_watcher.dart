import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clipboard_service.dart';
import 'models/clipboard_state.dart';
import 'models/clipboard_status.dart';
import 'models/url_type.dart';

/// Riverpod StateNotifier that monitors system clipboard changes across app lifecycle events.
class ClipboardWatcher extends StateNotifier<ClipboardState>
    with WidgetsBindingObserver {
  final ClipboardService _clipboardService;

  /// In-memory cache of the last inspected text to prevent duplicate triggers.
  String? _lastInspectedClipboardText;

  /// Flag indicating whether automatic clipboard detection is active.
  bool isEnabled;

  ClipboardWatcher({
    ClipboardService? clipboardService,
    bool initialEnabled = true,
    WidgetsBinding? widgetsBinding,
  })  : _clipboardService = clipboardService ?? const ClipboardService(),
        isEnabled = initialEnabled,
        super(const ClipboardState.idle()) {
    final activeBinding = widgetsBinding ?? WidgetsBinding.instance;
    activeBinding.addObserver(this);
  }

  /// Enables or disables automatic clipboard detection.
  void setEnabled(bool enabled) {
    isEnabled = enabled;
    debugPrint('[ClipboardWatcher] Automatic detection set to: $isEnabled');
  }

  /// Resets the watcher state back to idle.
  void resetToIdle() {
    state = const ClipboardState.idle();
    debugPrint('[ClipboardWatcher] State reset to idle.');
  }

  /// Clears the cached clipboard string so the same URL can be re-evaluated if desired.
  void clearLastInspectedText() {
    _lastInspectedClipboardText = null;
  }

  /// Updates state directly, intended for testing state transitions.
  @visibleForTesting
  void updateState(ClipboardState newState) {
    state = newState;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      inspectClipboard();
    }
  }

  /// Inspects the current clipboard content and updates state.
  Future<void> inspectClipboard() async {
    if (!isEnabled) {
      debugPrint('[ClipboardWatcher] Inspection skipped: detection is disabled.');
      return;
    }

    final clipboardContent = await _clipboardService.readClipboard();
    if (clipboardContent == null || clipboardContent.trim().isEmpty) {
      return;
    }

    final trimmedContent = clipboardContent.trim();
    if (trimmedContent == _lastInspectedClipboardText) {
      debugPrint(
        '[ClipboardWatcher] Inspection skipped: content matches last seen clipboard text.',
      );
      return;
    }

    _lastInspectedClipboardText = trimmedContent;
    final detectedUrlType = _clipboardService.detectUrlType(trimmedContent);

    if (detectedUrlType == UrlType.invalid) {
      state = ClipboardState(
        status: ClipboardDetectionStatus.invalid,
        url: trimmedContent,
        type: UrlType.invalid,
      );
      debugPrint(
        '[ClipboardWatcher] State changed: status=${state.status}, url=${state.url}, type=${state.type}',
      );
    } else {
      state = ClipboardState(
        status: ClipboardDetectionStatus.newUrlFound,
        url: trimmedContent,
        type: detectedUrlType,
      );
      debugPrint(
        '[ClipboardWatcher] State changed: status=${state.status}, url=${state.url}, type=${state.type}',
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Provider for [ClipboardService].
final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return const ClipboardService();
});

/// Provider for [ClipboardWatcher] and its [ClipboardState].
final clipboardWatcherProvider =
    StateNotifierProvider<ClipboardWatcher, ClipboardState>((ref) {
  final clipboardService = ref.watch(clipboardServiceProvider);
  return ClipboardWatcher(clipboardService: clipboardService);
});
