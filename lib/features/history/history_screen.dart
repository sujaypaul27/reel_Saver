import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../l10n/app_localizations.dart';
import 'history_service.dart';
import 'models/history_item.dart';

/// Screen displaying completed download history, allowing users to play files
/// in their default media player or delete downloads permanently.
class HistoryScreen extends ConsumerStatefulWidget {
  final Future<void> Function(String filePath)? onOpenFile;
  final HistoryService? customHistoryService;
  final List<HistoryItem>? initialItems;

  const HistoryScreen({
    super.key,
    this.onOpenFile,
    this.customHistoryService,
    this.initialItems,
  });

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<HistoryItem>? _historyItems;
  bool _isLoading = true;

  HistoryService get _historyService =>
      widget.customHistoryService ?? ref.read(historyServiceProvider);

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null) {
      _historyItems = widget.initialItems;
      _isLoading = false;
    } else {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_historyItems == null) {
      setState(() {
        _isLoading = true;
      });
    }

    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOpenFile(HistoryItem item) async {
    bool exists = false;
    try {
      final file = File(item.filePath);
      exists = file.existsSync();
    } catch (_) {
      exists = false;
    }

    if (!exists) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileNotFoundAt(item.filePath)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    try {
      if (widget.onOpenFile != null) {
        await widget.onOpenFile!(item.filePath);
      } else {
        final openResult = await OpenFilex.open(item.filePath);
        if (openResult.type != ResultType.done && mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.couldNotOpenFile(openResult.message)),
            ),
          );
        }
      }
    } catch (openError) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.couldNotOpenFile('No supported media player app found.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteItem(HistoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteDownloadTitle),
          content: Text(l10n.deleteConfirmationMessage),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deleteButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final targetFile = File(item.filePath);
        if (targetFile.existsSync()) {
          targetFile.deleteSync(recursive: true);
        }
      } catch (fileDeleteError) {
        debugPrint(
            '[HistoryScreen] Error deleting physical file: $fileDeleteError');
      }

      await _historyService.deleteHistoryEntry(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deletedItemSnackbar(item.title)),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        _loadHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.downloadHistoryTitle),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final items = _historyItems ?? [];
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDownloadsYet,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final formattedDate =
              DateFormat('MMM d, y • h:mm a').format(item.downloadedAt);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 72,
                    height: 72,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: item.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            item.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.video_file_outlined, size: 36),
                          )
                        : const Icon(Icons.video_file_outlined, size: 36),
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.format} • ${item.fileSizeMB.toStringAsFixed(1)} MB',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Buttons: Open & Delete
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      tooltip: l10n.playOpenTooltip,
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 32,
                      onPressed: () => _handleOpenFile(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: l10n.deleteTooltip,
                      color: Theme.of(context).colorScheme.error,
                      iconSize: 22,
                      onPressed: () => _confirmAndDeleteItem(item),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
