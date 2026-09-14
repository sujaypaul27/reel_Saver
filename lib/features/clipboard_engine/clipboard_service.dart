import 'package:flutter/services.dart';

import 'models/url_type.dart';

/// Plain Dart service responsible for reading system clipboard data
/// and detecting supported video platform URLs.
class ClipboardService {
  const ClipboardService();

  /// Regex pattern matching YouTube video, short, and shortened URLs.
  /// Matches: youtube.com/watch?v=, youtu.be/, youtube.com/shorts/
  static final RegExp _youtubeUrlPattern = RegExp(
    r'^(?:https?:\/\/)?(?:[a-zA-Z0-9-]+\.)*(?:youtube\.com\/(?:watch\?v=|shorts\/)|youtu\.be\/)',
    caseSensitive: false,
  );

  /// Regex pattern matching Instagram reels, posts, and TV links.
  /// Matches: instagram.com/reel/, instagram.com/p/, instagram.com/tv/
  static final RegExp _instagramUrlPattern = RegExp(
    r'^(?:https?:\/\/)?(?:[a-zA-Z0-9-]+\.)*instagram\.com\/(?:reel|p|tv)\/',
    caseSensitive: false,
  );

  /// Reads plain text from the system clipboard.
  Future<String?> readClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (clipboardError) {
      // In case clipboard access fails on platform
      return null;
    }
  }

  /// Detects whether the provided [text] represents a YouTube, Instagram, or invalid URL.
  ///
  /// Trims whitespace before evaluation and operates case-insensitively.
  UrlType detectUrlType(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return UrlType.invalid;
    }

    if (_youtubeUrlPattern.hasMatch(trimmedText)) {
      return UrlType.youtube;
    }

    if (_instagramUrlPattern.hasMatch(trimmedText)) {
      return UrlType.instagram;
    }

    return UrlType.invalid;
  }
}
