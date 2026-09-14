import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/queue_item.dart';
import 'models/video_format.dart';
import 'models/video_info.dart';

/// StateNotifier responsible for managing the download queue.
class DownloadQueueNotifier extends StateNotifier<List<QueueItem>> {
  DownloadQueueNotifier() : super(const <QueueItem>[]);

  /// Adds a format to the queue with status [QueueItemStatus.queued].
  String addQueueItem(VideoInfo videoInfo, VideoFormat selectedFormat) {
    // Avoid duplicate queued entry for identical video and format
    final existingIndex = state.indexWhere(
      (item) =>
          item.videoInfo.title == videoInfo.title &&
          item.selectedFormat == selectedFormat &&
          item.status == QueueItemStatus.queued,
    );
    if (existingIndex != -1) {
      return state[existingIndex].id;
    }

    final uniqueId =
        '${DateTime.now().microsecondsSinceEpoch}_${selectedFormat.label}';
    final newItem = QueueItem(
      id: uniqueId,
      videoInfo: videoInfo,
      selectedFormat: selectedFormat,
      status: QueueItemStatus.queued,
      progressPercent: 0.0,
    );

    state = [...state, newItem];
    debugPrint(
      '[DownloadQueueNotifier] Added to queue: ${videoInfo.title} (${selectedFormat.label})',
    );
    return uniqueId;
  }

  /// Removes a format from the queue if it has not yet completed.
  void removeQueueItem(VideoInfo videoInfo, VideoFormat selectedFormat) {
    state = state
        .where(
          (item) => !(item.videoInfo.title == videoInfo.title &&
              item.selectedFormat == selectedFormat &&
              item.status == QueueItemStatus.queued),
        )
        .toList();
    debugPrint(
      '[DownloadQueueNotifier] Removed from queue: ${videoInfo.title} (${selectedFormat.label})',
    );
  }

  /// Checks whether a specific format of a video is currently queued.
  bool isFormatQueued(VideoInfo videoInfo, VideoFormat selectedFormat) {
    return state.any(
      (item) =>
          item.videoInfo.title == videoInfo.title &&
          item.selectedFormat == selectedFormat &&
          item.status == QueueItemStatus.queued,
    );
  }

  /// Starts downloading all queued items concurrently, simulating progress over 2 seconds.
  Future<void> startQueuedDownloads() async {
    final queuedItems =
        state.where((item) => item.status == QueueItemStatus.queued).toList();

    if (queuedItems.isEmpty) return;

    debugPrint(
      '[DownloadQueueNotifier] Starting downloads for ${queuedItems.length} queued items.',
    );

    final queuedIds = queuedItems.map((item) => item.id).toSet();
    state = [
      for (final item in state)
        if (queuedIds.contains(item.id))
          item.copyWith(
            status: QueueItemStatus.downloading,
            progressPercent: 15.0,
          )
        else
          item,
    ];

    await Future.wait([
      for (final item in queuedItems) _advanceSimulatedProgress(item.id),
    ]);
  }

  /// Starts download immediately for a single format item.
  Future<void> startSingleDownload(
    VideoInfo videoInfo,
    VideoFormat selectedFormat,
  ) async {
    String targetId;
    final existingIndex = state.indexWhere(
      (item) =>
          item.videoInfo.title == videoInfo.title &&
          item.selectedFormat == selectedFormat &&
          (item.status == QueueItemStatus.queued ||
              item.status == QueueItemStatus.downloading),
    );

    if (existingIndex != -1) {
      targetId = state[existingIndex].id;
    } else {
      targetId = addQueueItem(videoInfo, selectedFormat);
    }

    state = [
      for (final item in state)
        if (item.id == targetId)
          item.copyWith(
            status: QueueItemStatus.downloading,
            progressPercent: 15.0,
          )
        else
          item,
    ];

    await _advanceSimulatedProgress(targetId);
  }

  /// Advances progress through simulated steps over ~2 seconds before marking completed.
  Future<void> _advanceSimulatedProgress(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Step 2: Intermediate progress
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            progressPercent: 55.0,
          )
        else
          item,
    ];

    await Future.delayed(const Duration(milliseconds: 700));

    // Step 3: High progress
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            progressPercent: 90.0,
          )
        else
          item,
    ];

    await Future.delayed(const Duration(milliseconds: 700));

    // Step 4: Completion
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            status: QueueItemStatus.completed,
            progressPercent: 100.0,
          )
        else
          item,
    ];

    debugPrint('[DownloadQueueNotifier] Item $itemId completed download simulation.');
  }

  /// Clears completed downloads from the queue list.
  void clearCompleted() {
    state = state
        .where((item) => item.status != QueueItemStatus.completed)
        .toList();
  }
}

/// Provider for [DownloadQueueNotifier].
final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, List<QueueItem>>((ref) {
  return DownloadQueueNotifier();
});
