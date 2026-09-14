import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../auth/instagram_session_service.dart';
import 'models/video_format.dart';
import 'models/video_info.dart';

/// Service responsible for extracting video metadata and stream formats
/// using YoutubeExplode and bundled yt-dlp binary with no mock fallbacks.
class ExtractionService {
  final String? ytDlpBinaryPath;
  final YoutubeExplode? youtubeExplodeClient;
  final http.Client? httpClient;
  final InstagramSessionService? sessionService;

  const ExtractionService({
    this.ytDlpBinaryPath,
    this.youtubeExplodeClient,
    this.httpClient,
    this.sessionService,
  });

  /// Fetches real video details and format options for the provided [url].
  Future<VideoInfo> fetchDetails(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      throw Exception('Video URL cannot be empty.');
    }

    final isYouTube = _isYouTubeUrl(trimmedUrl);
    final isInstagram = _isInstagramUrl(trimmedUrl);

    if (isYouTube) {
      return _fetchYouTubeDetails(trimmedUrl);
    } else if (isInstagram) {
      return _fetchInstagramDetails(trimmedUrl);
    } else {
      // For any other supported URL, attempt yt-dlp binary
      return _fetchViaYtDlp(trimmedUrl);
    }
  }

  /// Checks if [url] belongs to YouTube.
  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('youtube.com/shorts');
  }

  /// Checks if [url] belongs to Instagram.
  bool _isInstagramUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('instagram.com') || lower.contains('instagr.am');
  }

  /// Normalizes YouTube video URLs by extracting the video ID and forming
  /// a clean watch URL, stripping problematic query parameters (like `?si=...`
  /// or `?feature=...` which cause YoutubeExplode parser failures on shorts).
  String _normalizeYouTubeUrl(String url) {
    final match = RegExp(
      r'(?:v=|\/shorts\/|\/embed\/|\/v\/|\/live\/|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    ).firstMatch(url);
    if (match != null && match.group(1) != null) {
      return 'https://www.youtube.com/watch?v=${match.group(1)}';
    }
    return url;
  }

  /// Extracts YouTube details using [YoutubeExplode].
  Future<VideoInfo> _fetchYouTubeDetails(String url) async {
    final yt = youtubeExplodeClient ?? YoutubeExplode();
    final normalizedUrl = _normalizeYouTubeUrl(url);
    try {
      final video = await yt.videos.get(normalizedUrl);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);

      final extractedFormats = <VideoFormat>[];

      // 1. Muxed streams (Video + Audio)
      for (final muxedStream in manifest.muxed) {
        final height = muxedStream.videoResolution.height;
        final sizeMB = muxedStream.size.totalBytes / (1024 * 1024);
        extractedFormats.add(
          VideoFormat(
            label: '${height}p',
            type: FormatType.videoAndAudio,
            fileExtension: muxedStream.container.name,
            estimatedSizeMB: double.parse(sizeMB.toStringAsFixed(1)),
            height: height,
            bitrate: muxedStream.bitrate.kiloBitsPerSecond.round(),
            downloadUrl: muxedStream.url.toString(),
            tag: muxedStream.tag.toString(),
          ),
        );
      }

      // 2. Video-only streams (High resolutions like 1080p, 1440p, 4K)
      for (final videoStream in manifest.videoOnly) {
        final height = videoStream.videoResolution.height;
        final sizeMB = videoStream.size.totalBytes / (1024 * 1024);
        final label = height >= 2160 ? '4K' : '${height}p';

        extractedFormats.add(
          VideoFormat(
            label: label,
            type: FormatType.videoOnly,
            fileExtension: videoStream.container.name,
            estimatedSizeMB: double.parse(sizeMB.toStringAsFixed(1)),
            height: height,
            bitrate: videoStream.bitrate.kiloBitsPerSecond.round(),
            downloadUrl: videoStream.url.toString(),
            tag: videoStream.tag.toString(),
          ),
        );
      }

      // 3. Audio-only streams
      for (final audioStream in manifest.audioOnly) {
        final bitrateKbps = audioStream.bitrate.kiloBitsPerSecond.round();
        final sizeMB = audioStream.size.totalBytes / (1024 * 1024);

        extractedFormats.add(
          VideoFormat(
            label: '${bitrateKbps}kbps',
            type: FormatType.audioOnly,
            fileExtension: audioStream.container.name == 'mp4' ? 'm4a' : audioStream.container.name,
            estimatedSizeMB: double.parse(sizeMB.toStringAsFixed(1)),
            bitrate: bitrateKbps,
            downloadUrl: audioStream.url.toString(),
            tag: audioStream.tag.toString(),
          ),
        );
      }

      final deduplicatedFormats = _deduplicateAndSortFormats(extractedFormats);

      final thumbnailUrl = video.thumbnails.highResUrl.isNotEmpty
          ? video.thumbnails.highResUrl
          : video.thumbnails.mediumResUrl;

      return VideoInfo(
        title: video.title,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: video.duration?.inSeconds ?? 0,
        formats: deduplicatedFormats,
      );
    } catch (ytError, ytStack) {
      debugPrint('[ExtractionService] YoutubeExplode error (${ytError.runtimeType}): $ytError');
      if (kDebugMode) {
        debugPrint('[ExtractionService] YoutubeExplode stackTrace: $ytStack');
      }
      try {
        debugPrint('[ExtractionService] Attempting yt-dlp fallback for: $url');
        return await _fetchViaYtDlp(url);
      } catch (fallbackError) {
        debugPrint('[ExtractionService] yt-dlp fallback also failed: $fallbackError');
        if (ytError is RequestLimitExceededException) {
          throw Exception(
            'Could not fetch video details: YouTube blocked this request with bot detection / rate limiting. '
            'Please wait a while or try from another network.',
          );
        }
        throw Exception(
          'Could not fetch video details: $ytError',
        );
      }
    } finally {
      if (youtubeExplodeClient == null) {
        yt.close();
      }
    }
  }

  /// Extracts Instagram reel details using pure-Dart HTTP endpoints with optional
  /// authenticated session cookies.
  Future<VideoInfo> _fetchInstagramDetails(String url) async {
    final shortcodeMatch =
        RegExp(r'(?:reel|reels|p)/([A-Za-z0-9_-]+)').firstMatch(url);
    final shortcode = shortcodeMatch?.group(1);

    if (shortcode == null) {
      throw Exception('Could not parse Instagram reel shortcode from URL.');
    }

    final cookieHeader = await sessionService?.getCookieHeader();
    final hasSession = cookieHeader != null && cookieHeader.isNotEmpty;

    debugPrint('[ExtractionService] Fetching Instagram shortcode: $shortcode (Has Session: $hasSession)');

    final client = httpClient ?? http.Client();
    bool encounteredLoginWall = false;
    int? lastStatusCode;
    String? lastErrorSnippet;

    try {
      final candidates = [
        'https://www.instagram.com/reel/$shortcode/?__a=1&__d=dis',
        'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis',
      ];

      final headers = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        'Accept': '*/*',
        'X-IG-App-ID': '936619743392459',
        'Sec-Fetch-Site': 'same-origin',
      };
      if (hasSession) {
        headers['Cookie'] = cookieHeader;
      }

      for (final candidateUrl in candidates) {
        try {
          debugPrint('[ExtractionService] Requesting Instagram endpoint: $candidateUrl');
          final response = await client.get(
            Uri.parse(candidateUrl),
            headers: headers,
          );

          lastStatusCode = response.statusCode;
          final preview = response.body.length > 200
              ? response.body.substring(0, 200).replaceAll('\n', ' ')
              : response.body;
          debugPrint(
            '[ExtractionService] Response code: ${response.statusCode}, Length: ${response.body.length} bytes, Preview: $preview',
          );

          if (response.statusCode == 200 &&
              response.body.isNotEmpty &&
              !response.body.startsWith('<!DOCTYPE html>')) {
            final dynamic data = jsonDecode(response.body);
            if (data is Map<String, dynamic>) {
              final videoInfo = _parseInstagramJson(data);
              if (videoInfo != null) {
                return videoInfo;
              }
            }
          } else if (response.statusCode == 401 ||
              response.statusCode == 403 ||
              response.body.contains('accounts/login') ||
              response.body.contains('checkpoint_required')) {
            debugPrint('[ExtractionService] Instagram authentication required or session rejected (HTTP ${response.statusCode})');
            encounteredLoginWall = true;
          } else {
            lastErrorSnippet = 'HTTP ${response.statusCode}: $preview';
          }
        } catch (e, stack) {
          debugPrint('[ExtractionService] Instagram candidate request failed: $e');
          if (kDebugMode) {
            debugPrint('[ExtractionService] Stack trace: $stack');
          }
        }
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }

    if (encounteredLoginWall) {
      if (hasSession) {
        throw const InstagramSessionExpiredException(
          'Instagram session expired. Please log in again.',
        );
      } else {
        throw const InstagramAuthRequiredException(
          'Instagram login required for this Reel. Please log in via Settings.',
        );
      }
    }

    throw Exception(
      'Could not fetch Instagram video details (${lastStatusCode != null ? "HTTP $lastStatusCode" : "Network error"}). '
      '${lastErrorSnippet ?? "The reel may be private, removed, or the endpoint was blocked."}',
    );
  }

  /// Parses Instagram web JSON response into [VideoInfo].
  VideoInfo? _parseInstagramJson(Map<String, dynamic> data) {
    try {
      String? videoUrl;
      String? thumbnailUrl;
      String title = 'Instagram Reel';

      // Pattern A: items list
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        final item = items.first as Map<String, dynamic>;
        final caption = item['caption'] as Map<String, dynamic>?;
        if (caption != null && caption['text'] != null) {
          title = caption['text'].toString().split('\n').first;
        }

        final videoVersions = item['video_versions'] as List<dynamic>?;
        if (videoVersions != null && videoVersions.isNotEmpty) {
          videoUrl = videoVersions.first['url'] as String?;
        }

        final imageVersions = item['image_versions2'] as Map<String, dynamic>?;
        final candidates = imageVersions?['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          thumbnailUrl = candidates.first['url'] as String?;
        }
      }

      // Pattern B: graphql shortcode_media
      if (videoUrl == null && data['graphql'] != null) {
        final graphql = data['graphql'] as Map<String, dynamic>;
        final media = graphql['shortcode_media'] as Map<String, dynamic>?;
        if (media != null) {
          videoUrl = media['video_url'] as String?;
          thumbnailUrl = media['display_url'] as String?;
          final edgeCaption = media['edge_media_to_caption'] as Map<String, dynamic>?;
          final edges = edgeCaption?['edges'] as List<dynamic>?;
          if (edges != null && edges.isNotEmpty) {
            final node = edges.first['node'] as Map<String, dynamic>?;
            if (node != null && node['text'] != null) {
              title = node['text'].toString().split('\n').first;
            }
          }
        }
      }

      if (videoUrl != null) {
        return VideoInfo(
          title: title.length > 80 ? '${title.substring(0, 80)}...' : title,
          thumbnailUrl: thumbnailUrl ?? '',
          durationSeconds: 30,
          formats: [
            VideoFormat(
              label: 'Original',
              type: FormatType.videoAndAudio,
              fileExtension: 'mp4',
              downloadUrl: videoUrl,
              estimatedSizeMB: 15.0,
            ),
          ],
        );
      }
    } catch (e) {
      debugPrint('[ExtractionService] Error parsing Instagram JSON: $e');
    }
    return null;
  }

  /// Executes yt-dlp process to extract metadata as JSON.
  Future<VideoInfo> _fetchViaYtDlp(String url) async {
    final binaryPath = ytDlpBinaryPath ?? await _locateBundledYtDlp();
    final targetUrl = _isYouTubeUrl(url) ? _normalizeYouTubeUrl(url) : url;

    if (binaryPath != null && await File(binaryPath).exists()) {
      final processResult = await Process.run(
        binaryPath,
        ['--dump-json', '--no-warnings', targetUrl],
      );

      if (processResult.exitCode == 0) {
        final dynamic parsedJson = jsonDecode(processResult.stdout.toString());
        if (parsedJson is Map<String, dynamic>) {
          return parseYtDlpJson(parsedJson);
        } else {
          throw const FormatException('Extractor returned unexpected data structure.');
        }
      } else {
        final stderrOutput = processResult.stderr.toString().trim();
        debugPrint('[ExtractionService] yt-dlp failed: $stderrOutput');
        throw Exception(
          stderrOutput.isNotEmpty
              ? 'Could not fetch video details: $stderrOutput'
              : 'Could not fetch video details. The video may be private, removed, or unavailable.',
        );
      }
    }

    throw Exception(
      'Could not fetch video details. Please check your internet connection and try again.',
    );
  }

  /// Parses raw JSON output from yt-dlp into a structured [VideoInfo] object.
  VideoInfo parseYtDlpJson(Map<String, dynamic> rawJson) {
    final title = (rawJson['title'] as String?) ?? 'Video';
    final thumbnailUrl = (rawJson['thumbnail'] as String?) ?? '';
    final durationSeconds = (rawJson['duration'] as num?)?.toInt() ?? 0;

    final rawFormats = rawJson['formats'] as List<dynamic>? ?? [];
    final extractedFormats = <VideoFormat>[];

    for (final rawFormat in rawFormats) {
      if (rawFormat is! Map<String, dynamic>) continue;

      final vcodec = rawFormat['vcodec'] as String?;
      final acodec = rawFormat['acodec'] as String?;

      final hasVideo = vcodec != null && vcodec != 'none';
      final hasAudio = acodec != null && acodec != 'none';

      // Ignore entries with neither video nor audio (metadata/storyboards)
      if (!hasVideo && !hasAudio) continue;

      final FormatType type;
      if (hasVideo && hasAudio) {
        type = FormatType.videoAndAudio;
      } else if (hasVideo && !hasAudio) {
        type = FormatType.videoOnly;
      } else {
        type = FormatType.audioOnly;
      }

      final extension = (rawFormat['ext'] as String?) ?? 'mp4';
      final height = (rawFormat['height'] as num?)?.toInt();
      final abr = (rawFormat['abr'] as num?)?.toInt();
      final tbr = (rawFormat['tbr'] as num?)?.toInt();
      final bitrate = abr ?? tbr;

      // Extract quality label
      final String label;
      if (hasVideo) {
        if (height != null) {
          if (height >= 2160) {
            label = '4K';
          } else {
            label = '${height}p';
          }
        } else {
          label = (rawFormat['format_note'] as String?) ?? 'Video';
        }
      } else {
        if (bitrate != null && bitrate > 0) {
          label = '${bitrate}kbps';
        } else {
          label = (rawFormat['format_note'] as String?) ?? 'Audio';
        }
      }

      // Calculate estimated file size in MB
      final rawFileSize = (rawFormat['filesize'] as num?)?.toDouble() ??
          (rawFormat['filesize_approx'] as num?)?.toDouble();
      final estimatedSizeMB =
          rawFileSize != null ? (rawFileSize / (1024 * 1024)) : null;

      extractedFormats.add(
        VideoFormat(
          label: label,
          type: type,
          fileExtension: extension,
          estimatedSizeMB: estimatedSizeMB,
          height: height,
          bitrate: bitrate,
          downloadUrl: rawFormat['url'] as String?,
          tag: rawFormat['format_id']?.toString(),
        ),
      );
    }

    final deduplicatedFormats = _deduplicateAndSortFormats(extractedFormats);

    return VideoInfo(
      title: title,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      formats: deduplicatedFormats,
    );
  }

  /// Deduplicates formats by (label + type) and sorts them appropriately.
  List<VideoFormat> _deduplicateAndSortFormats(List<VideoFormat> formats) {
    final deduplicatedFormatsMap = <String, VideoFormat>{};
    for (final format in formats) {
      final key = '${format.label}_${format.type.name}';
      final existing = deduplicatedFormatsMap[key];
      if (existing == null) {
        deduplicatedFormatsMap[key] = format;
      } else {
        final isExistingPreferred =
            existing.fileExtension.toLowerCase() == 'mp4' ||
                existing.fileExtension.toLowerCase() == 'm4a';
        final isCurrentPreferred =
            format.fileExtension.toLowerCase() == 'mp4' ||
                format.fileExtension.toLowerCase() == 'm4a';

        if (!isExistingPreferred && isCurrentPreferred) {
          deduplicatedFormatsMap[key] = format;
        }
      }
    }

    final uniqueFormats = deduplicatedFormatsMap.values.toList();

    final videoFormats = uniqueFormats
        .where((f) =>
            f.type == FormatType.videoAndAudio || f.type == FormatType.videoOnly)
        .toList()
      ..sort((a, b) {
        final heightA = a.height ?? 0;
        final heightB = b.height ?? 0;
        if (heightA != heightB) {
          return heightB.compareTo(heightA);
        }
        if (a.type == FormatType.videoAndAudio &&
            b.type != FormatType.videoAndAudio) {
          return -1;
        }
        if (b.type == FormatType.videoAndAudio &&
            a.type != FormatType.videoAndAudio) {
          return 1;
        }
        return 0;
      });

    final audioFormats = uniqueFormats
        .where((f) => f.type == FormatType.audioOnly)
        .toList()
      ..sort((a, b) {
        final bitrateA = a.bitrate ?? 0;
        final bitrateB = b.bitrate ?? 0;
        return bitrateB.compareTo(bitrateA);
      });

    return [...videoFormats, ...audioFormats];
  }

  /// Locates any bundled yt-dlp binary on the system (desktop only).
  Future<String?> _locateBundledYtDlp() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms enforce SELinux W^X restrictions and lack a Python runtime.
      // Native Dart extractors are used exclusively on mobile.
      return null;
    }
    const possiblePaths = [
      'assets/bin/yt-dlp.exe',
      'assets/bin/yt-dlp',
    ];
    for (final path in possiblePaths) {
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }
}

/// Provider for [ExtractionService].
final extractionServiceProvider = Provider<ExtractionService>((ref) {
  final sessionService = ref.watch(instagramSessionServiceProvider);
  return ExtractionService(sessionService: sessionService);
});
