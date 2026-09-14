import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../clipboard_engine/clipboard_watcher.dart';
import '../../clipboard_engine/models/clipboard_state.dart';
import '../../clipboard_engine/models/clipboard_status.dart';
import '../../clipboard_engine/models/url_type.dart';
import '../providers/auto_mode_provider.dart';

/// Main home screen allowing users to toggle between automatic clipboard detection
/// and manual URL verification.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlTextController = TextEditingController();
  String? _manualUrlErrorMessage;
  bool _showInvalidClipboardBanner = false;

  @override
  void dispose() {
    _urlTextController.dispose();
    super.dispose();
  }

  void _validateAndCheckManualUrl() {
    final enteredUrl = _urlTextController.text;
    final clipboardService = ref.read(clipboardServiceProvider);
    final detectedUrlType = clipboardService.detectUrlType(enteredUrl);

    if (detectedUrlType == UrlType.invalid) {
      setState(() {
        _manualUrlErrorMessage =
            'Invalid link. Please paste a valid Instagram Reel or YouTube video URL.';
      });
    } else {
      setState(() {
        _manualUrlErrorMessage = null;
      });
      context.push('/fetching-details', extra: enteredUrl.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAutomaticDetectionEnabled = ref.watch(autoModeProvider);

    // Keep the clipboard watcher sync'd with the autoModeProvider
    ref.listen<bool>(autoModeProvider, (previousValue, nextValue) {
      ref.read(clipboardWatcherProvider.notifier).setEnabled(nextValue);
      if (nextValue) {
        setState(() {
          _manualUrlErrorMessage = null;
        });
      } else {
        setState(() {
          _showInvalidClipboardBanner = false;
        });
      }
    });

    // Listen to the clipboard watcher when automatic detection is active
    ref.listen<ClipboardState>(clipboardWatcherProvider, (previousState, currentState) {
      if (!isAutomaticDetectionEnabled) return;

      if (currentState.status == ClipboardDetectionStatus.newUrlFound &&
          currentState.url != null) {
        setState(() {
          _showInvalidClipboardBanner = false;
        });
        final detectedVideoUrl = currentState.url!;
        ref.read(clipboardWatcherProvider.notifier).resetToIdle();
        context.push('/fetching-details', extra: detectedVideoUrl);
      } else if (currentState.status == ClipboardDetectionStatus.invalid) {
        setState(() {
          _showInvalidClipboardBanner = true;
        });
        ref.read(clipboardWatcherProvider.notifier).resetToIdle();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () {
            // Placeholder menu button for upcoming settings drawer phase
          },
        ),
        title: const Text('Reel Saver'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top of screen: Labeled toggle switch for Automatic Detection
              SwitchListTile(
                title: const Text(
                  'Automatic Detection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  isAutomaticDetectionEnabled
                      ? 'Clipboard is monitored automatically'
                      : 'Manual URL paste mode active',
                ),
                value: isAutomaticDetectionEnabled,
                onChanged: (bool newToggleValue) {
                  ref.read(autoModeProvider.notifier).setAutoMode(newToggleValue);
                },
              ),
              const Divider(height: 24),

              // 2. Automatic mode: Dismissible invalid clipboard banner
              if (isAutomaticDetectionEnabled && _showInvalidClipboardBanner)
                MaterialBanner(
                  content: const Text(
                    'No valid Instagram or YouTube link found in clipboard.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showInvalidClipboardBanner = false;
                        });
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),

              // 3. Manual mode: TextField for URL paste + Check URL button + Inline error
              if (!isAutomaticDetectionEnabled) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _urlTextController,
                  decoration: InputDecoration(
                    labelText: 'Video or Reel URL',
                    hintText: 'Paste YouTube or Instagram link here',
                    border: const OutlineInputBorder(),
                    errorText: _manualUrlErrorMessage,
                    errorMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: () {
                        _urlTextController.clear();
                        setState(() {
                          _manualUrlErrorMessage = null;
                        });
                      },
                    ),
                  ),
                  onChanged: (text) {
                    if (_manualUrlErrorMessage != null) {
                      setState(() {
                        _manualUrlErrorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validateAndCheckManualUrl,
                  child: const Text('Check URL'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
