import 'video_format.dart';

/// Represents metadata extracted for a video link.
class VideoInfo {
  final String title;
  final String thumbnailUrl;
  final int durationSeconds;
  final List<VideoFormat> formats;

  const VideoInfo({
    required this.title,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.formats,
  });

  /// Formats duration into a readable "mm:ss" string (e.g. 215s -> "03:35").
  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoInfo &&
        other.title == title &&
        other.thumbnailUrl == thumbnailUrl &&
        other.durationSeconds == durationSeconds;
  }

  @override
  int get hashCode => Object.hash(title, thumbnailUrl, durationSeconds);

  @override
  String toString() =>
      'VideoInfo(title: $title, duration: $formattedDuration, formatsCount: ${formats.length})';
}
