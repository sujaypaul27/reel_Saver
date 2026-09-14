import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_execution_service.dart';
import 'models/queue_item.dart';
import 'models/video_format.dart';
import 'models/video_info.dart';

/// StateNotifier responsible for managing the download queue.
class DownloadQueueNotifier extends StateNotifier<List<QueueItem>> {
  final DownloadExecutionService? executionService;
  final Future<bool> Function()? requestStoragePermission;

  DownloadQueueNotifier({
    this.executionService,
    this.requestStoragePermission,
  }) : super(const <QueueItem>[]);

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

  /// Starts downloading all queued items that have a format selected.
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

    if (requestStoragePermission != null) {
      final isGranted = await requestStoragePermission!();
      if (!isGranted) {
        debugPrint(
          '[DownloadQueueNotifier] Storage permission not granted. Aborting queued downloads.',
        );
        return;
      }
    }

    debugPrint(
      '[DownloadQueueNotifier] Starting downloads for ${queuedItems.length} queued items with selected formats.',
    );

    await Future.wait([
      for (final item in queuedItems) _executeDownload(item.id),
    ]);
  }

  /// Starts download immediately for a single format item.
  Future<void> startSingleDownload(
    VideoInfo videoInfo,
    VideoFormat selectedFormat, {
    String? videoUrl,
  }) async {
    if (requestStoragePermission != null) {
      final isGranted = await requestStoragePermission!();
      if (!isGranted) return;
    }

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
      targetId = addQueueItem(videoInfo, selectedFormat, videoUrl: videoUrl);
    }

    await _executeDownload(targetId);
  }

  /// Retries a previously failed download.
  Future<void> retryDownload(String itemId) async {
    final targetIndex = state.indexWhere((item) => item.id == itemId);
    if (targetIndex == -1) return;

    final targetItem = state[targetIndex];
    if (targetItem.selectedFormat == null) return;

    if (requestStoragePermission != null) {
      final isGranted = await requestStoragePermission!();
      if (!isGranted) return;
    }

    debugPrint(
      '[DownloadQueueNotifier] Retrying download for item $itemId (${targetItem.videoInfo.title})',
    );
    await _executeDownload(itemId);
  }

  /// Executes download using [DownloadExecutionService] or simulation fallback.
  Future<void> _executeDownload(String itemId) async {
    final targetIndex = state.indexWhere((item) => item.id == itemId);
    if (targetIndex == -1) return;

    final targetItem = state[targetIndex];
    if (targetItem.selectedFormat == null) return;

    // Transition state to downloading
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            status: QueueItemStatus.downloading,
            progressPercent: 0.0,
            clearErrorMessage: true,
          )
        else
          item,
    ];

    if (executionService == null) {
      await _advanceSimulatedProgress(itemId);
      return;
    }

    try {
      final targetUrl =
          targetItem.videoUrl ?? 'https://youtube.com/watch?v=sample';
      final downloadedPath = await executionService!.executeDownload(
        url: targetUrl,
        videoInfo: targetItem.videoInfo,
        format: targetItem.selectedFormat!,
        onProgress: (progressPercent) {
          state = [
            for (final item in state)
              if (item.id == itemId)
                item.copyWith(progressPercent: progressPercent)
              else
                item,
          ];
        },
      );

      state = [
        for (final item in state)
          if (item.id == itemId)
            item.copyWith(
              status: QueueItemStatus.completed,
              progressPercent: 100.0,
              downloadedFilePath: downloadedPath,
              clearErrorMessage: true,
            )
          else
            item,
      ];
      debugPrint('[DownloadQueueNotifier] Download completed: $downloadedPath');
    } catch (downloadError) {
      debugPrint(
        '[DownloadQueueNotifier] Download failed for item $itemId: $downloadError',
      );
      state = [
        for (final item in state)
          if (item.id == itemId)
            item.copyWith(
              status: QueueItemStatus.failed,
              errorMessage:
                  downloadError.toString().replaceFirst('Exception: ', ''),
            )
          else
            item,
      ];
    }
  }

  /// Advances progress through simulated steps over ~2 seconds before marking completed (dev/test fallback).
  Future<void> _advanceSimulatedProgress(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 600));

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
  return DownloadQueueNotifier(
    executionService: ref.watch(downloadExecutionServiceProvider),
  );
});
