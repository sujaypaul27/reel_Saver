import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'models/queue_item.dart';

/// Service responsible for persisting and retrieving download queue entries
/// from a local JSON file (download_queue.json) in the application documents directory.
class QueueStorageService {
  final File? customQueueFile;
  File? _resolvedFile;

  QueueStorageService({this.customQueueFile}) {
    if (customQueueFile != null) {
      _resolvedFile = customQueueFile;
    }
  }

  /// Resolves the storage JSON file for the download queue.
  Future<File?> getFile() async {
    if (_resolvedFile != null) {
      return _resolvedFile;
    }
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      _resolvedFile = File('${documentsDirectory.path}/download_queue.json');
      return _resolvedFile;
    } catch (storageError) {
      debugPrint('[QueueStorageService] Could not resolve documents directory: $storageError');
      return null;
    }
  }

  /// Loads all persisted queue items.
  /// Any item interrupted mid-download (status == downloading) is automatically
  /// reset to status == queued with progressPercent == 0.0 so the user can re-trigger it.
  Future<List<QueueItem>> loadQueue() async {
    try {
      final file = await getFile();
      if (file == null || !file.existsSync()) {
        return const <QueueItem>[];
      }

      final content = file.readAsStringSync();
      if (content.trim().isEmpty) {
        return const <QueueItem>[];
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((itemJson) => QueueItem.fromJson(itemJson))
            .map((item) {
              if (item.status == QueueItemStatus.downloading) {
                return item.copyWith(
                  status: QueueItemStatus.queued,
                  progressPercent: 0.0,
                  clearErrorMessage: true,
                );
              }
              return item;
            })
            .toList();
      }
      return const <QueueItem>[];
    } catch (loadError) {
      debugPrint('[QueueStorageService] Error reading queue from storage: $loadError');
      return const <QueueItem>[];
    }
  }

  /// Serializes and writes the current queue state to disk.
  Future<void> saveQueue(List<QueueItem> items) async {
    try {
      final file = await getFile();
      if (file == null) return;

      final jsonString = const JsonEncoder.withIndent('  ').convert(
        items.map((item) => item.toJson()).toList(),
      );

      file.writeAsStringSync(jsonString, flush: true);
      debugPrint('[QueueStorageService] Saved ${items.length} queue item(s) to storage.');
    } catch (saveError) {
      debugPrint('[QueueStorageService] Error saving queue to storage: $saveError');
    }
  }

  /// Clears the persisted download queue file.
  Future<void> clearQueue() async {
    try {
      final file = await getFile();
      if (file != null && file.existsSync()) {
        file.writeAsStringSync('[]', flush: true);
        debugPrint('[QueueStorageService] Cleared persisted queue storage.');
      }
    } catch (clearError) {
      debugPrint('[QueueStorageService] Error clearing queue storage: $clearError');
    }
  }
}

/// Provider for [QueueStorageService].
final queueStorageServiceProvider = Provider<QueueStorageService>((ref) {
  return QueueStorageService();
});
