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
  /// If a placeholder item with null format exists for this video, it is upgraded with the selected format.
  String addQueueItem(
    VideoInfo videoInfo,
    VideoFormat selectedFormat, {
    String? videoUrl,
  }) {
    // If an unselected placeholder exists for this video, upgrade it
    final unselectedIndex = state.indexWhere(
      (item) =>
          item.selectedFormat == null &&
          (item.videoInfo.title == videoInfo.title ||
              (videoUrl != null && item.videoUrl == videoUrl)) &&
          item.status == QueueItemStatus.queued,
    );
    if (unselectedIndex != -1) {
      final placeholder = state[unselectedIndex];
      final upgradedItem = placeholder.copyWith(
        selectedFormat: selectedFormat,
        videoUrl: videoUrl ?? placeholder.videoUrl,
      );
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == unselectedIndex) upgradedItem else state[i],
      ];
      debugPrint(
        '[DownloadQueueNotifier] Upgraded shared placeholder to: ${videoInfo.title} (${selectedFormat.label})',
      );
      return upgradedItem.id;
    }

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
      videoUrl: videoUrl,
    );

    state = [...state, newItem];
    debugPrint(
      '[DownloadQueueNotifier] Added to queue: ${videoInfo.title} (${selectedFormat.label})',
    );
    return uniqueId;
  }

  /// Adds an item shared from Instagram or YouTube to the queue with no format selected yet.
  String addSharedQueueItem(
    VideoInfo videoInfo, {
    required String videoUrl,
  }) {
    // Prevent duplicate entry for same URL if still active in queue
    final existingIndex = state.indexWhere(
      (item) =>
          item.videoUrl == videoUrl &&
          (item.status == QueueItemStatus.queued ||
              item.status == QueueItemStatus.downloading),
    );
    if (existingIndex != -1) {
      debugPrint(
        '[DownloadQueueNotifier] Shared item already in cart: $videoUrl',
      );
      return state[existingIndex].id;
    }

    final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_shared';
    final newItem = QueueItem(
      id: uniqueId,
      videoInfo: videoInfo,
      selectedFormat: null,
      status: QueueItemStatus.queued,
      progressPercent: 0.0,
      videoUrl: videoUrl,
    );

    state = [...state, newItem];
    debugPrint(
      '[DownloadQueueNotifier] Added shared item to cart: ${videoInfo.title} (Quality pending)',
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

  /// Starts downloading all queued items that have a format selected, simulating progress over 2 seconds.
  /// Items with no format chosen are skipped silently and kept in the cart.
  Future<void> startQueuedDownloads() async {
    final queuedItems = state
        .where(
          (item) =>
              item.status == QueueItemStatus.queued &&
              item.selectedFormat != null,
        )
        .toList();

    if (queuedItems.isEmpty) return;

    debugPrint(
      '[DownloadQueueNotifier] Starting downloads for ${queuedItems.length} queued items with selected formats.',
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
