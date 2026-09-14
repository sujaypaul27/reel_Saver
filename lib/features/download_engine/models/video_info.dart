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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'formats': formats.map((format) => format.toJson()).toList(),
    };
  }

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      formats: (json['formats'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((formatJson) => VideoFormat.fromJson(formatJson))
              .toList() ??
          const <VideoFormat>[],
    );
  }

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
