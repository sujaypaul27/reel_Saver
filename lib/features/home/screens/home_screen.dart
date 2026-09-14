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
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_drawer.dart';
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
  bool _hasManualUrlError = false;
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
        _hasManualUrlError = true;
      });
    } else {
      setState(() {
        _hasManualUrlError = false;
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
          _hasManualUrlError = false;
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

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (scaffoldContext) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: l10n.menuTooltip,
            onPressed: () {
              Scaffold.of(scaffoldContext).openDrawer();
            },
          ),
        ),
        title: Text(l10n.appName),
      ),
      drawer: const AppDrawer(),
      bottomSheet: activeDownloads.isEmpty
          ? null
          : Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: InkWell(
                onTap: () => _openQueueProgressBottomSheet(context, l10n),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.downloading_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.downloadsInProgress(activeDownloads.length),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                title: Text(
                  l10n.autoDetectionTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  isAutomaticDetectionEnabled
                      ? l10n.autoDetectionSubtitleActive
                      : l10n.autoDetectionSubtitleInactive,
                  style: Theme.of(context).textTheme.bodyMedium,
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
                  content: Text(
                    l10n.invalidClipboardBanner,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showInvalidClipboardBanner = false;
                        });
                      },
                      child: Text(l10n.dismissAction),
                    ),
                  ],
                ),

              // 3. Manual mode: TextField for URL paste + Check URL button + Inline error
              if (!isAutomaticDetectionEnabled) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _urlTextController,
                  decoration: InputDecoration(
                    labelText: l10n.urlInputLabel,
                    hintText: l10n.urlInputHint,
                    border: const OutlineInputBorder(),
                    errorText: _hasManualUrlError ? l10n.invalidUrlError : null,
                    errorMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.clearTooltip,
                      onPressed: () {
                        _urlTextController.clear();
                        setState(() {
                          _hasManualUrlError = false;
                        });
                      },
                    ),
                  ),
                  onChanged: (text) {
                    if (_hasManualUrlError) {
                      setState(() {
                        _hasManualUrlError = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _validateAndCheckManualUrl,
                  child: Text(l10n.checkUrlButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openQueueProgressBottomSheet(BuildContext context, AppLocalizations l10n) {
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
                          Expanded(
                            child: Text(
                              l10n.downloadQueueTitle,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(downloadQueueProvider.notifier).clearCompleted();
                            },
                            child: Text(l10n.clearCompletedButton),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (queue.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(l10n.noItemsInQueue),
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
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (item.selectedFormat == null) ...[
                                      Row(
                                        children: [
                                          Text(
                                            l10n.qualityNotSelected,
                                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                                            label: Text(l10n.selectQualityButton),
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
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                          const Spacer(),
                                          _buildQueueStatusIndicator(item, l10n),
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

  Widget _buildQueueStatusIndicator(QueueItem item, AppLocalizations l10n) {
    switch (item.status) {
      case QueueItemStatus.queued:
        return Text(
          l10n.statusQueued,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
        );
      case QueueItemStatus.downloading:
        return Text(
          '${item.progressPercent.toInt()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
        );
      case QueueItemStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              l10n.statusCompleted,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      case QueueItemStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _showErrorDetailsDialog(item, l10n),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      l10n.statusFailed,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
              onPressed: () => _retryDownloadWithPermission(item.id, l10n),
              child: Text(
                l10n.retryButton,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        );
    }
  }

  void _showErrorDetailsDialog(QueueItem item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.downloadFailedTitle),
        content: Text(
          item.errorMessage ?? l10n.unknownErrorMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _retryDownloadWithPermission(item.id, l10n);
            },
            child: Text(l10n.retryDownloadButton),
          ),
        ],
      ),
    );
  }

  Future<void> _retryDownloadWithPermission(String itemId, AppLocalizations l10n) async {
    final hasPermission = await _checkAndRequestStoragePermission(l10n);
    if (hasPermission) {
      ref.read(downloadQueueProvider.notifier).retryDownload(itemId);
    }
  }

  Future<bool> _checkAndRequestStoragePermission(AppLocalizations l10n) async {
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
            title: Text(l10n.storagePermissionTitle),
            content: Text(
              l10n.storagePermissionContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openAppSettings();
                },
                child: Text(l10n.openSettingsButton),
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
