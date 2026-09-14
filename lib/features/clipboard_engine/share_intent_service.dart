import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../download_engine/extraction_service.dart';
import '../download_engine/queue_service.dart';
import 'clipboard_service.dart';
import 'clipboard_watcher.dart';
import 'models/url_type.dart';

/// Abstract receiver interface for receiving shared media from the OS.
/// Allows clean unit and integration testing without platform channels.
abstract class SharingIntentReceiver {
  Future<List<SharedMediaFile>> getInitialMedia();
  Stream<List<SharedMediaFile>> getMediaStream();
  Future<void> reset();
}

/// Default implementation delegating to [ReceiveSharingIntent.instance].
class DefaultSharingIntentReceiver implements SharingIntentReceiver {
  const DefaultSharingIntentReceiver();

  @override
  Future<List<SharedMediaFile>> getInitialMedia() =>
      ReceiveSharingIntent.instance.getInitialMedia();

  @override
  Stream<List<SharedMediaFile>> getMediaStream() =>
      ReceiveSharingIntent.instance.getMediaStream();

  @override
  Future<void> reset() => ReceiveSharingIntent.instance.reset();
}

/// Service that listens for incoming shared text from Android share intents,
/// validates the link using [ClipboardService.detectUrlType], extracts video details
/// in the background, and adds the item to the download cart with no format selected.
class ShareIntentService {
  final ClipboardService clipboardService;
  final ExtractionService extractionService;
  final DownloadQueueNotifier downloadQueueNotifier;
  final int Function() getQueueLength;
  final SharingIntentReceiver sharingReceiver;
  final void Function(String message)? onConfirmation;
  final bool showNativeToast;

  StreamSubscription<List<SharedMediaFile>>? _intentSubscription;
  bool _isInitialized = false;

  ShareIntentService({
    required this.clipboardService,
    required this.extractionService,
    required this.downloadQueueNotifier,
    required this.getQueueLength,
    this.sharingReceiver = const DefaultSharingIntentReceiver(),
    this.onConfirmation,
    this.showNativeToast = true,
  });

  /// Initializes the share intent listener for both cold start and warm start.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Cold-start: App opened via share sheet when terminated
    try {
      final initialFiles = await sharingReceiver.getInitialMedia();
      if (initialFiles.isNotEmpty) {
        debugPrint(
          '[ShareIntentService] Received ${initialFiles.length} file(s) via cold-start intent.',
        );
        for (final file in initialFiles) {
          await handleSharedText(file.path);
        }
        await sharingReceiver.reset();
      }
    } catch (error) {
      debugPrint('[ShareIntentService] Error handling initial media: $error');
    }

    // 2. Warm-start: App was already running/backgrounded when shared
    _intentSubscription = sharingReceiver.getMediaStream().listen(
      (List<SharedMediaFile> files) async {
        debugPrint(
          '[ShareIntentService] Received ${files.length} file(s) via warm-start stream.',
        );
        for (final file in files) {
          await handleSharedText(file.path);
        }
      },
      onError: (error) {
        debugPrint('[ShareIntentService] Stream error: $error');
      },
    );
  }

  /// Processes shared text, validates URL, extracts video info, and adds to queue.
  Future<void> handleSharedText(String text) async {
    final validUrl = _extractValidUrl(text);
    if (validUrl == null) {
      // Silently ignore invalid or unsupported content
      debugPrint('[ShareIntentService] Ignored non-media or unsupported share content.');
      return;
    }

    debugPrint('[ShareIntentService] Valid shared URL detected: $validUrl');

    try {
      // Fetch details in background (title, thumbnail, formats)
      final videoInfo = await extractionService.fetchDetails(validUrl);

      // Add to download cart with selectedFormat = null (format choice pending)
      downloadQueueNotifier.addSharedQueueItem(
        videoInfo,
        videoUrl: validUrl,
      );

      final totalQueuedCount = getQueueLength();
      final confirmationMessage =
          'Added to Download Cart ($totalQueuedCount ${totalQueuedCount == 1 ? 'item' : 'items'})';

      // Trigger callback if provided (useful for tests)
      onConfirmation?.call(confirmationMessage);

      // Show native Android toast (visible even when app remains backgrounded)
      _showNativeToast(confirmationMessage);
    } catch (extractionError) {
      debugPrint(
        '[ShareIntentService] Error extracting details for shared URL: $extractionError',
      );
      const failureMessage =
          'Could not fetch shared video. Please check your connection or link.';
      onConfirmation?.call(failureMessage);
      _showNativeToast(failureMessage);
    }
  }

  /// Extracts a valid YouTube or Instagram URL from the shared text.
  /// Reuses [ClipboardService.detectUrlType] to avoid duplicating regex logic.
  String? _extractValidUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    if (clipboardService.detectUrlType(trimmed) != UrlType.invalid) {
      return trimmed;
    }

    // Fallback: extract embedded URL from shared text string (e.g. "Check out this reel: https://...")
    final urlRegex = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);
    final match = urlRegex.firstMatch(trimmed);
    if (match != null) {
      final candidateUrl = match.group(0)!;
      if (clipboardService.detectUrlType(candidateUrl) != UrlType.invalid) {
        return candidateUrl;
      }
    }

    return null;
  }

  void _showNativeToast(String message) {
    if (!showNativeToast) return;
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (toastError) {
      debugPrint('[ShareIntentService] Toast display failed: $toastError');
    }
  }

  /// Disposes stream subscriptions.
  void dispose() {
    _intentSubscription?.cancel();
    _intentSubscription = null;
    _isInitialized = false;
  }
}

/// Provider exposing [ShareIntentService].
final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  final service = ShareIntentService(
    clipboardService: ref.watch(clipboardServiceProvider),
    extractionService: ref.watch(extractionServiceProvider),
    downloadQueueNotifier: ref.watch(downloadQueueProvider.notifier),
    getQueueLength: () => ref.read(downloadQueueProvider).length,
  );
  ref.onDispose(service.dispose);
  return service;
});
