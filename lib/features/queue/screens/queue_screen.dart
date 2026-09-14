import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_drawer.dart';
import '../../download_engine/models/queue_item.dart';
import '../../download_engine/queue_service.dart';

/// Screen displaying the active and persisted download queue with real-time progress,
/// format selection, retry capabilities, and media playback.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final queueItems = ref.watch(downloadQueueProvider);
    final hasCompletedItems =
        queueItems.any((item) => item.status == QueueItemStatus.completed);
    final hasQueuedItems = queueItems.any(
      (item) =>
          item.status == QueueItemStatus.queued && item.selectedFormat != null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloadQueueTitle),
        actions: [
          if (hasCompletedItems)
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded),
              label: Text(l10n.clearCompletedButton),
              onPressed: () {
                ref.read(downloadQueueProvider.notifier).clearCompleted();
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: queueItems.isEmpty
          ? _buildEmptyView(context, l10n)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: queueItems.length,
              itemBuilder: (context, index) {
                final item = queueItems[index];
                return _buildQueueCard(context, ref, item, l10n);
              },
            ),
      floatingActionButton: hasQueuedItems
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(downloadQueueProvider.notifier).startQueuedDownloads();
              },
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.startDownloadsButton),
            )
          : null,
    );
  }

  /// Empty state view when no items are present in the queue.
  Widget _buildEmptyView(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noItemsInQueue,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Card widget for displaying each individual queue entry.
  Widget _buildQueueCard(
    BuildContext context,
    WidgetRef ref,
    QueueItem item,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    width: 85,
                    height: 60,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: item.videoInfo.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            item.videoInfo.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.movie_outlined, size: 28),
                          )
                        : const Icon(Icons.movie_outlined, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and format
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.videoInfo.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      if (item.selectedFormat != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            item.selectedFormat!.formattedDisplayLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.tune_rounded, size: 16),
                          label: Text(l10n.selectQualityButton),
                          onPressed: () {
                            _showQualityPickerModal(context, ref, item);
                          },
                        ),
                    ],
                  ),
                ),
                // Delete / Cancel Button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: l10n.deleteTooltip,
                  onPressed: () {
                    ref
                        .read(downloadQueueProvider.notifier)
                        .removeQueueItemById(item.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status row with progress or actions
            _buildStatusSection(context, ref, item, l10n),
          ],
        ),
      ),
    );
  }

  /// Builds the status section (Progress bar, Status chip, Play/Retry actions).
  Widget _buildStatusSection(
    BuildContext context,
    WidgetRef ref,
    QueueItem item,
    AppLocalizations l10n,
  ) {
    switch (item.status) {
      case QueueItemStatus.queued:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(
              avatar: const Icon(Icons.schedule_rounded, size: 16, color: Colors.orange),
              label: Text(
                l10n.statusQueued,
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.orange.withValues(alpha: 0.12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            if (item.selectedFormat != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.downloadFormatTooltip(item.selectedFormat!.label)),
                onPressed: () {
                  ref.read(downloadQueueProvider.notifier).startSingleDownload(
                        item.videoInfo,
                        item.selectedFormat!,
                        videoUrl: item.videoUrl,
                      );
                },
              ),
          ],
        );

      case QueueItemStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: Text(
                    '${item.progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  l10n.fetchingLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: item.progressPercent > 0 ? (item.progressPercent / 100.0) : null,
                minHeight: 6,
              ),
            ),
          ],
        );

      case QueueItemStatus.completed:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Chip(
              avatar: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
              label: Text(
                l10n.statusCompleted,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.green.withValues(alpha: 0.12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            if (item.downloadedFilePath != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(l10n.playOpenTooltip),
                onPressed: () async {
                  final file = File(item.downloadedFilePath!);
                  if (await file.exists()) {
                    await OpenFilex.open(item.downloadedFilePath!);
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.fileNotFoundAt(item.downloadedFilePath!),
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        );

      case QueueItemStatus.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                  label: Text(
                    l10n.statusFailed,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.retryButton),
                  onPressed: () {
                    ref.read(downloadQueueProvider.notifier).retryDownload(item.id);
                  },
                ),
              ],
            ),
            if (item.errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                item.errorMessage!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
              ),
            ],
          ],
        );
    }
  }

  /// Displays the quality picker modal sheet for items added via share intent.
  void _showQualityPickerModal(
    BuildContext context,
    WidgetRef ref,
    QueueItem item,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final formats = item.videoInfo.formats;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  l10n.selectFormatTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (formats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        l10n.unknownErrorMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: formats.length,
                      itemBuilder: (context, index) {
                        final format = formats[index];
                        return ListTile(
                          title: Text(format.formattedDisplayLabel),
                          subtitle: format.formattedEstimatedSize != null
                              ? Text(format.formattedEstimatedSize!)
                              : null,
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.of(bottomSheetContext).pop();
                            ref.read(downloadQueueProvider.notifier).addQueueItem(
                                  item.videoInfo,
                                  format,
                                  videoUrl: item.videoUrl,
                                );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
