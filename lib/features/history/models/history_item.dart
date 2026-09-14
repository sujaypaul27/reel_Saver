/// Represents an entry in the download history store.
class HistoryItem {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String filePath;
  final String format;
  final double fileSizeMB;
  final DateTime downloadedAt;

  const HistoryItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.filePath,
    required this.format,
    required this.fileSizeMB,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'filePath': filePath,
      'format': format,
      'fileSizeMB': fileSizeMB,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      filePath: json['filePath'] as String,
      format: json['format'] as String,
      fileSizeMB: (json['fileSizeMB'] as num?)?.toDouble() ?? 0.0,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryItem &&
        other.id == id &&
        other.title == title &&
        other.thumbnailUrl == thumbnailUrl &&
        other.filePath == filePath &&
        other.format == format &&
        other.fileSizeMB == fileSizeMB &&
        other.downloadedAt == downloadedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        thumbnailUrl,
        filePath,
        format,
        fileSizeMB,
        downloadedAt,
      );

  @override
  String toString() =>
      'HistoryItem(id: $id, title: $title, filePath: $filePath, format: $format, size: ${fileSizeMB}MB, date: $downloadedAt)';
}
