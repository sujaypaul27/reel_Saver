import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reel_saver/features/history/history_service.dart';
import 'package:reel_saver/features/history/models/history_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late File testHistoryFile;
  late HistoryService historyService;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('history_test_');
    testHistoryFile = File('${temporaryDirectory.path}/test_history.json');
    historyService = HistoryService(customHistoryFile: testHistoryFile);
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  group('HistoryItem Model Tests', () {
    test('serializes to and from json accurately', () {
      final now = DateTime.now();
      final item = HistoryItem(
        id: 'hist_123',
        title: 'Amazing Reel',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        filePath: '/storage/downloads/reel.mp4',
        format: '1080p (Video + Audio)',
        fileSizeMB: 24.5,
        downloadedAt: now,
      );

      final json = item.toJson();
      expect(json['id'], equals('hist_123'));
      expect(json['title'], equals('Amazing Reel'));
      expect(json['fileSizeMB'], equals(24.5));

      final deserialized = HistoryItem.fromJson(json);
      expect(deserialized, equals(item));
    });
  });

  group('HistoryService Storage Tests', () {
    test('returns empty list when history file does not exist', () async {
      final history = await historyService.getHistory();
      expect(history, isEmpty);
    });

    test('saves new history entries and reads them latest first', () async {
      final item1 = HistoryItem(
        id: '1',
        title: 'First Video',
        thumbnailUrl: '',
        filePath: '/storage/first.mp4',
        format: '720p',
        fileSizeMB: 12.0,
        downloadedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final item2 = HistoryItem(
        id: '2',
        title: 'Second Video',
        thumbnailUrl: '',
        filePath: '/storage/second.mp4',
        format: '1080p',
        fileSizeMB: 30.0,
        downloadedAt: DateTime.now(),
      );

      await historyService.addHistoryEntry(item1);
      await historyService.addHistoryEntry(item2);

      final history = await historyService.getHistory();
      expect(history.length, equals(2));
      // Latest added should be first
      expect(history.first.id, equals('2'));
      expect(history.last.id, equals('1'));
    });

    test('deletes a single entry by id', () async {
      final item1 = HistoryItem(
        id: 'del_1',
        title: 'Delete Me',
        thumbnailUrl: '',
        filePath: '/storage/del1.mp4',
        format: '720p',
        fileSizeMB: 10.0,
        downloadedAt: DateTime.now(),
      );
      final item2 = HistoryItem(
        id: 'keep_2',
        title: 'Keep Me',
        thumbnailUrl: '',
        filePath: '/storage/keep2.mp4',
        format: '1080p',
        fileSizeMB: 20.0,
        downloadedAt: DateTime.now(),
      );

      await historyService.addHistoryEntry(item1);
      await historyService.addHistoryEntry(item2);

      await historyService.deleteHistoryEntry('del_1');

      final history = await historyService.getHistory();
      expect(history.length, equals(1));
      expect(history.first.id, equals('keep_2'));
    });

    test('clears all history entries', () async {
      final item = HistoryItem(
        id: 'item_1',
        title: 'Reel',
        thumbnailUrl: '',
        filePath: '/storage/reel.mp4',
        format: '1080p',
        fileSizeMB: 15.0,
        downloadedAt: DateTime.now(),
      );
      await historyService.addHistoryEntry(item);
      expect(await historyService.getHistory(), isNotEmpty);

      await historyService.clearHistory();
      expect(await historyService.getHistory(), isEmpty);
    });
  });
}
