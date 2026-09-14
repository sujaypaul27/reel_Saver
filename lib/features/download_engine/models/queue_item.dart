import 'video_format.dart';
import 'video_info.dart';

/// Represents the status of an item in the download queue.
enum QueueItemStatus {
  queued,
  downloading,
  completed,
  failed,
}

/// Represents an individual video entry queued for download.
class QueueItem {
  final String id;
  final VideoInfo videoInfo;
  final VideoFormat? selectedFormat;
  final QueueItemStatus status;
  final double progressPercent;
  final String? videoUrl;
  final String? errorMessage;
  final String? downloadedFilePath;

  const QueueItem({
    required this.id,
    required this.videoInfo,
    this.selectedFormat,
    this.status = QueueItemStatus.queued,
    this.progressPercent = 0.0,
    this.videoUrl,
    this.errorMessage,
    this.downloadedFilePath,
  });

  QueueItem copyWith({
    VideoFormat? selectedFormat,
    QueueItemStatus? status,
    double? progressPercent,
    String? videoUrl,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? downloadedFilePath,
  }) {
    return QueueItem(
      id: id,
      videoInfo: videoInfo,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
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
        other.progressPercent == progressPercent &&
        other.videoUrl == videoUrl &&
        other.errorMessage == errorMessage &&
        other.downloadedFilePath == downloadedFilePath;
  }

  @override
  int get hashCode => Object.hash(
        id,
        videoInfo,
        selectedFormat,
        status,
        progressPercent,
        videoUrl,
        errorMessage,
        downloadedFilePath,
      );

  @override
  String toString() =>
      'QueueItem(id: $id, title: ${videoInfo.title}, format: ${selectedFormat?.label ?? "none"}, status: $status, progress: $progressPercent%, url: $videoUrl, error: $errorMessage, file: $downloadedFilePath)';
}
