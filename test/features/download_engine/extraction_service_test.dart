import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/download_engine/extraction_service.dart';
import 'package:reel_saver/features/download_engine/models/video_format.dart';
import 'package:reel_saver/features/download_engine/models/video_info.dart';

void main() {
  group('VideoInfo and VideoFormat Model Tests', () {
    test('formats duration correctly', () {
      const videoInfo = VideoInfo(
        title: 'Test Video',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        durationSeconds: 215,
        formats: [],
      );

      expect(videoInfo.formattedDuration, equals('03:35'));
    });

    test('generates exact format type descriptions and labels', () {
      const videoOnly = VideoFormat(
        label: '144p',
        type: FormatType.videoOnly,
        fileExtension: 'mp4',
      );
      expect(videoOnly.typeDescription, equals('Video Only'));
      expect(videoOnly.formattedDisplayLabel, equals('144p (Video Only)'));

      const videoAndAudio = VideoFormat(
        label: '1080p',
        type: FormatType.videoAndAudio,
        fileExtension: 'mp4',
        estimatedSizeMB: 45.0,
      );
      expect(videoAndAudio.typeDescription, equals('Video + Audio'));
      expect(videoAndAudio.formattedDisplayLabel, equals('1080p (Video + Audio)'));
      expect(videoAndAudio.formattedEstimatedSize, equals('~45.0 MB'));

      const audioOnly = VideoFormat(
        label: '128kbps',
        type: FormatType.audioOnly,
        fileExtension: 'mp3',
      );
      expect(audioOnly.typeDescription, equals('Audio Only - MP3'));
      expect(audioOnly.formattedDisplayLabel, equals('128kbps (Audio Only - MP3)'));
    });
  });

  group('ExtractionService JSON Parsing & Deduplication', () {
    const service = ExtractionService();

    test('correctly parses, deduplicates, and sorts raw yt-dlp format entries', () {
      final sampleYtDlpJson = {
        'title': 'Sample Dynamic Video',
        'thumbnail': 'https://example.com/test.jpg',
        'duration': 130,
        'formats': [
          // Storyboard format - should be ignored
          {
            'format_id': 'sb0',
            'vcodec': 'none',
            'acodec': 'none',
          },
          // 720p webm video-only
          {
            'format_id': '1',
            'vcodec': 'vp9',
            'acodec': 'none',
            'ext': 'webm',
            'height': 720,
            'filesize': 10485760, // ~10 MB
          },
          // 720p mp4 video-only (should replace webm due to mp4 preference)
          {
            'format_id': '2',
            'vcodec': 'avc1',
            'acodec': 'none',
            'ext': 'mp4',
            'height': 720,
            'filesize': 12582912, // ~12 MB
          },
          // 1080p videoAndAudio
          {
            'format_id': '3',
            'vcodec': 'avc1',
            'acodec': 'mp4a',
            'ext': 'mp4',
            'height': 1080,
            'filesize': 52428800, // ~50 MB
          },
          // 4K video-only
          {
            'format_id': '4',
            'vcodec': 'vp9',
            'acodec': 'none',
            'ext': 'webm',
            'height': 2160,
            'filesize': 209715200,
          },
          // Audio 128kbps
          {
            'format_id': '5',
            'vcodec': 'none',
            'acodec': 'mp4a',
            'ext': 'm4a',
            'abr': 128,
            'filesize': 2097152,
          },
          // Audio 320kbps
          {
            'format_id': '6',
            'vcodec': 'none',
            'acodec': 'mp3',
            'ext': 'mp3',
            'abr': 320,
            'filesize': 5242880,
          },
        ],
      };

      final videoInfo = service.parseYtDlpJson(sampleYtDlpJson);

      expect(videoInfo.title, equals('Sample Dynamic Video'));
      expect(videoInfo.durationSeconds, equals(130));
      expect(videoInfo.formattedDuration, equals('02:10'));

      final formats = videoInfo.formats;

      // Ensure 4K is top, followed by 1080p, 720p, then audios sorted by bitrate
      expect(formats[0].label, equals('4K'));
      expect(formats[0].type, equals(FormatType.videoOnly));

      expect(formats[1].label, equals('1080p'));
      expect(formats[1].type, equals(FormatType.videoAndAudio));

      expect(formats[2].label, equals('720p'));
      expect(formats[2].type, equals(FormatType.videoOnly));
      expect(formats[2].fileExtension, equals('mp4'), reason: 'Preferred mp4 over webm');

      // Audio formats should be at bottom sorted descending
      expect(formats[3].label, equals('320kbps'));
      expect(formats[3].type, equals(FormatType.audioOnly));

      expect(formats[4].label, equals('128kbps'));
      expect(formats[4].type, equals(FormatType.audioOnly));
    });

    test('throws descriptive exception when URL is invalid or unavailable', () async {
      expect(
        () => service.fetchDetails('https://youtube.com/watch?v=nonexistent_invalid_url_12345'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Could not fetch video details'),
          ),
        ),
      );
    });
  });
}
