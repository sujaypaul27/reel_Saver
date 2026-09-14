import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

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
    final file = File(item.filePath);
    final exists = file.existsSync();

    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found at: ${item.filePath}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    if (widget.onOpenFile != null) {
      await widget.onOpenFile!(item.filePath);
    } else {
      final openResult = await OpenFilex.open(item.filePath);
      if (openResult.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${openResult.message}'),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteItem(HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Download'),
          content: const Text(
            'Delete this file permanently? This cannot be undone.',
          ),
          actions: [
            ElevatedButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
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
            content: Text('Deleted "${item.title}"'),
            duration: const Duration(milliseconds: 1500),
          ),
        );
        _loadHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download History'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final items = _historyItems ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No downloads yet.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.format} • ${item.fileSizeMB.toStringAsFixed(1)} MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 11,
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
                      tooltip: 'Play / Open',
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 32,
                      onPressed: () => _handleOpenFile(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Delete',
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
