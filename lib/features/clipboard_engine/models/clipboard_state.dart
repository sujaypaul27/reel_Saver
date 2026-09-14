import 'clipboard_status.dart';
import 'url_type.dart';

/// Holds the state emitted by the clipboard watcher.
class ClipboardState {
  final ClipboardDetectionStatus status;
  final String? url;
  final UrlType type;

  const ClipboardState({
    required this.status,
    this.url,
    this.type = UrlType.invalid,
  });

  const ClipboardState.idle()
      : status = ClipboardDetectionStatus.idle,
        url = null,
        type = UrlType.invalid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClipboardState &&
        other.status == status &&
        other.url == url &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(status, url, type);

  @override
  String toString() =>
      'ClipboardState(status: $status, url: $url, type: $type)';
}
