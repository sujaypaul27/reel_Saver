import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'models/history_item.dart';

/// Service responsible for persisting and retrieving download history entries
/// from a local JSON file in the application documents directory.
class HistoryService {
  final File? customHistoryFile;

  const HistoryService({this.customHistoryFile});

  /// Retrieves the history storage JSON file.
  Future<File> get _historyFile async {
    if (customHistoryFile != null) {
      return customHistoryFile!;
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return File('${documentsDirectory.path}/download_history.json');
  }

  /// Retrieves all recorded download history entries, ordered latest first.
  Future<List<HistoryItem>> getHistory() async {
    try {
      final file = await _historyFile;
      if (!await file.exists()) {
        return const <HistoryItem>[];
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return const <HistoryItem>[];
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((itemJson) => HistoryItem.fromJson(itemJson))
            .toList();
      }
      return const <HistoryItem>[];
    } catch (historyReadError) {
      debugPrint('[HistoryService] Error reading history: $historyReadError');
      return const <HistoryItem>[];
    }
  }

  /// Appends a new download entry to the history store.
  Future<void> addHistoryEntry(HistoryItem newItem) async {
    try {
      final currentEntries = await getHistory();
      final updatedEntries = [newItem, ...currentEntries];

      final file = await _historyFile;
      final jsonString = const JsonEncoder.withIndent('  ').convert(
        updatedEntries.map((entry) => entry.toJson()).toList(),
      );

      await file.writeAsString(jsonString, flush: true);
      debugPrint('[HistoryService] Saved history entry: ${newItem.title}');
    } catch (historyWriteError) {
      debugPrint('[HistoryService] Error saving history entry: $historyWriteError');
    }
  }

  /// Deletes a specific history record by its identifier.
  Future<void> deleteHistoryEntry(String id) async {
    try {
      final currentEntries = await getHistory();
      final updatedEntries =
          currentEntries.where((item) => item.id != id).toList();

      final file = await _historyFile;
      final jsonString = const JsonEncoder.withIndent('  ').convert(
        updatedEntries.map((entry) => entry.toJson()).toList(),
      );

      await file.writeAsString(jsonString, flush: true);
    } catch (historyDeleteError) {
      debugPrint('[HistoryService] Error deleting history entry: $historyDeleteError');
    }
  }

  /// Clears all entries from the history store.
  Future<void> clearHistory() async {
    try {
      final file = await _historyFile;
      if (await file.exists()) {
        await file.writeAsString('[]', flush: true);
      }
    } catch (historyClearError) {
      debugPrint('[HistoryService] Error clearing history: $historyClearError');
    }
  }
}

/// Provider for [HistoryService].
final historyServiceProvider = Provider<HistoryService>((ref) {
  return const HistoryService();
});
