import 'video_format.dart';
import 'video_info.dart';

/// Represents the status of an item in the download queue.
enum QueueItemStatus {
  queued,
  downloading,
  completed,
  failed,
}

/// Represents an individual video format entry queued for download.
class QueueItem {
  final String id;
  final VideoInfo videoInfo;
  final VideoFormat selectedFormat;
  final QueueItemStatus status;
  final double progressPercent;

  const QueueItem({
    required this.id,
    required this.videoInfo,
    required this.selectedFormat,
    this.status = QueueItemStatus.queued,
    this.progressPercent = 0.0,
  });

  QueueItem copyWith({
    QueueItemStatus? status,
    double? progressPercent,
  }) {
    return QueueItem(
      id: id,
      videoInfo: videoInfo,
      selectedFormat: selectedFormat,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueueItem &&
        other.id == id &&
        other.videoInfo == videoInfo &&
        other.selectedFormat == selectedFormat &&
        other.status == status &&
        other.progressPercent == progressPercent;
  }

  @override
  int get hashCode =>
      Object.hash(id, videoInfo, selectedFormat, status, progressPercent);

  @override
  String toString() =>
      'QueueItem(id: $id, title: ${videoInfo.title}, format: ${selectedFormat.label}, status: $status, progress: $progressPercent%)';
}
