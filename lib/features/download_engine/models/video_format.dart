/// Categorization of a video or audio stream format.
enum FormatType {
  videoOnly,
  videoAndAudio,
  audioOnly,
}

/// Represents an available downloadable format for a video.
class VideoFormat {
  /// Quality or bitrate label (e.g., "1080p", "720p", "4K", "128kbps").
  final String label;

  /// Type of media stream (video only, combined video and audio, audio only).
  final FormatType type;

  /// File container extension (e.g., "mp4", "webm", "m4a", "mp3").
  final String fileExtension;

  /// Estimated download size in Megabytes, if available from metadata.
  final double? estimatedSizeMB;

  /// Vertical resolution in pixels (e.g., 1080, 720), used for sorting.
  final int? height;

  /// Approximate bitrate in kbps, used for audio stream sorting.
  final int? bitrate;

  const VideoFormat({
    required this.label,
    required this.type,
    required this.fileExtension,
    this.estimatedSizeMB,
    this.height,
    this.bitrate,
  });

  /// Description of the media stream type following exact specification.
  String get typeDescription {
    switch (type) {
      case FormatType.videoOnly:
        return 'Video Only';
      case FormatType.videoAndAudio:
        return 'Video + Audio';
      case FormatType.audioOnly:
        return 'Audio Only - MP3';
    }
  }

  /// Exact display pattern: "{quality} ({type description})".
  String get formattedDisplayLabel {
    return '$label ($typeDescription)';
  }

  /// Formatted size string (e.g. "~45.2 MB") or empty string if null.
  String? get formattedEstimatedSize {
    if (estimatedSizeMB == null) return null;
    return '~${estimatedSizeMB!.toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoFormat &&
        other.label == label &&
        other.type == type &&
        other.fileExtension == fileExtension &&
        other.estimatedSizeMB == estimatedSizeMB;
  }

  @override
  int get hashCode => Object.hash(label, type, fileExtension, estimatedSizeMB);

  @override
  String toString() =>
      'VideoFormat($formattedDisplayLabel, ext: $fileExtension, size: $formattedEstimatedSize)';
}
