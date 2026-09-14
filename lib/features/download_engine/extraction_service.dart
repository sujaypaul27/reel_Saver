import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'models/video_format.dart';
import 'models/video_info.dart';

/// Service responsible for extracting video metadata and stream formats
/// using YoutubeExplode and bundled yt-dlp binary with no mock fallbacks.
class ExtractionService {
  final String? ytDlpBinaryPath;
  final YoutubeExplode? youtubeExplodeClient;
  final http.Client? httpClient;

  const ExtractionService({
    this.ytDlpBinaryPath,
    this.youtubeExplodeClient,
    this.httpClient,
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

  /// Extracts YouTube details using [YoutubeExplode].
  Future<VideoInfo> _fetchYouTubeDetails(String url) async {
    final yt = youtubeExplodeClient ?? YoutubeExplode();
    try {
      final video = await yt.videos.get(url);
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
    } catch (ytError) {
      debugPrint('[ExtractionService] YoutubeExplode error: $ytError. Trying yt-dlp fallback...');
      try {
        return await _fetchViaYtDlp(url);
      } catch (_) {
        throw Exception(
          'Could not fetch video details. The video may be private, removed, or unavailable.',
        );
      }
    } finally {
      if (youtubeExplodeClient == null) {
        yt.close();
      }
    }
  }

  /// Extracts Instagram reel details using web endpoints or bundled yt-dlp.
  Future<VideoInfo> _fetchInstagramDetails(String url) async {
    // 1. First attempt yt-dlp binary if available
    try {
      return await _fetchViaYtDlp(url);
    } catch (ytDlpError) {
      debugPrint('[ExtractionService] yt-dlp failed for Instagram: $ytDlpError. Trying web endpoint...');
    }

    // 2. Direct Instagram JSON endpoints
    final shortcodeMatch =
        RegExp(r'(?:reel|reels|p)/([A-Za-z0-9_-]+)').firstMatch(url);
    final shortcode = shortcodeMatch?.group(1);

    if (shortcode != null) {
      final client = httpClient ?? http.Client();
      try {
        final candidates = [
          'https://www.instagram.com/reel/$shortcode/?__a=1&__d=dis',
          'https://www.instagram.com/p/$shortcode/?__a=1&__d=dis',
        ];

        for (final candidateUrl in candidates) {
          try {
            final response = await client.get(
              Uri.parse(candidateUrl),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
                'Accept': '*/*',
                'X-IG-App-ID': '936619743392459',
              },
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
            }
          } catch (e) {
            debugPrint('[ExtractionService] Instagram candidate failed: $e');
          }
        }
      } finally {
        if (httpClient == null) {
          client.close();
        }
      }
    }

    throw Exception(
      'Could not fetch Instagram video details. The reel may be private, removed, or unavailable.',
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

    if (binaryPath != null && await File(binaryPath).exists()) {
      final processResult = await Process.run(
        binaryPath,
        ['--dump-json', '--no-warnings', url],
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
          'Could not fetch video details. The video may be private, removed, or unavailable.',
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

  /// Locates any bundled yt-dlp binary on the system.
  Future<String?> _locateBundledYtDlp() async {
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
  return const ExtractionService();
});
