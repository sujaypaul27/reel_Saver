import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../clipboard_engine/clipboard_watcher.dart';
import '../../clipboard_engine/models/clipboard_state.dart';
import '../../clipboard_engine/models/clipboard_status.dart';
import '../../clipboard_engine/models/url_type.dart';
import '../../download_engine/models/queue_item.dart';
import '../../download_engine/queue_service.dart';
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

    final downloadQueue = ref.watch(downloadQueueProvider);
    final activeDownloads = downloadQueue
        .where((item) =>
            item.status == QueueItemStatus.downloading ||
            item.status == QueueItemStatus.queued ||
            item.status == QueueItemStatus.failed)
        .toList();

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
      bottomSheet: activeDownloads.isEmpty
          ? null
          : Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: InkWell(
                onTap: () => _openQueueProgressBottomSheet(context),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.downloading_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${activeDownloads.length} download${activeDownloads.length == 1 ? '' : 's'} in progress',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_up_rounded),
                      ],
                    ),
                  ),
                ),
              ),
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

  void _openQueueProgressBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final queue = ref.watch(downloadQueueProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Download Queue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(downloadQueueProvider.notifier).clearCompleted();
                            },
                            child: const Text('Clear Completed'),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (queue.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No items in download queue.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: queue.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final item = queue[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.videoInfo.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.selectedFormat == null) ...[
                                      Row(
                                        children: [
                                          Text(
                                            'Quality not selected',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange.shade800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const Spacer(),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                            ),
                                            icon: const Icon(Icons.tune_rounded, size: 16),
                                            label: const Text('Select Quality'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              context.push(
                                                '/fetching-details',
                                                extra: item.videoUrl,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        children: [
                                          Text(
                                            '${item.selectedFormat!.label} (${item.selectedFormat!.typeDescription})',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const Spacer(),
                                          _buildQueueStatusIndicator(item),
                                        ],
                                      ),
                                      if (item.status == QueueItemStatus.downloading) ...[
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: item.progressPercent / 100,
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQueueStatusIndicator(QueueItem item) {
    switch (item.status) {
      case QueueItemStatus.queued:
        return const Text(
          'Queued',
          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
        );
      case QueueItemStatus.downloading:
        return Text(
          '${item.progressPercent.toInt()}%',
          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
        );
      case QueueItemStatus.completed:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        );
      case QueueItemStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _showErrorDetailsDialog(item),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Failed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),
              onPressed: () => _retryDownloadWithPermission(item.id),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
    }
  }

  void _showErrorDetailsDialog(QueueItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Download Failed'),
        content: Text(
          item.errorMessage ??
              'An unknown error occurred while downloading this video.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _retryDownloadWithPermission(item.id);
            },
            child: const Text('Retry Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryDownloadWithPermission(String itemId) async {
    final hasPermission = await _checkAndRequestStoragePermission();
    if (hasPermission) {
      ref.read(downloadQueueProvider.notifier).retryDownload(itemId);
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        return true;
      }

      if (mounted) {
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'Reel Saver requires storage access to save downloaded videos and audio to your device. Please grant permission in App Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    } catch (_) {
      // Fallback on platforms where permission_handler is not needed or mocked
      return true;
    }
  }
}
