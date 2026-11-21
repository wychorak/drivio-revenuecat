import 'dart:io';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/video_cache.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDownloader implements VideoDownloader {
  final calls = <String>[];
  final failing = <String>{};

  @override
  Future<void> download(String storagePath, File target) async {
    calls.add(storagePath);
    await target.writeAsBytes(List.filled(10, 1));
    if (failing.contains(storagePath)) throw const SocketException('offline');
  }
}

TheoryQuestion videoQuestion(int id, String name, {int bytes = 10}) =>
    TheoryQuestion(
      id: id,
      text: 'Pytanie $id?',
      part: TheoryPart.basic,
      points: 3,
      answers: const ['TAK', 'NIE'],
      correctIndex: 0,
      video: 'theory_exam/videos/2026-07/$name',
      videoBytes: bytes,
    );

void main() {
  late Directory dir;
  late FakeDownloader downloader;
  late TheoryVideoCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('theory_videos');
    downloader = FakeDownloader();
    cache = TheoryVideoCache(
      directory: () async => dir,
      downloader: downloader,
    );
  });

  tearDown(() => dir.delete(recursive: true));

  test('reads the video fields from JSON', () {
    final q = TheoryQuestion.fromJson({
      'id': 1,
      'text': 't',
      'part': 'basic',
      'points': 3,
      'answers': ['TAK', 'NIE'],
      'correct': 0,
      'image': null,
      'video': 'theory_exam/videos/2026-07/a.mp4',
      'videoBytes': 1234,
    });
    expect(q.hasVideo, isTrue);
    expect(q.videoBytes, 1234);
  });

  test('a video is downloaded only once', () async {
    final q = videoQuestion(1, 'a.mp4');
    expect(await cache.localFile(q), isNull);
    final file = await cache.ensure(q);
    await cache.ensure(q);
    expect(downloader.calls, ['theory_exam/videos/2026-07/a.mp4']);
    expect(file.existsSync(), isTrue);
    expect((await cache.localFile(q))!.path, file.path);
  });

  test('a failed download leaves no file behind', () async {
    final q = videoQuestion(1, 'bad.mp4');
    downloader.failing.add(q.video!);
    await expectLater(cache.ensure(q), throwsA(isA<SocketException>()));
    expect(await cache.localFile(q), isNull);
    expect(dir.listSync(), isEmpty);
  });

  test('prepare downloads only missing videos and reports progress', () async {
    final a = videoQuestion(1, 'a.mp4', bytes: 30);
    final b = videoQuestion(2, 'b.mp4', bytes: 10);
    final shared = videoQuestion(3, 'b.mp4', bytes: 10);
    final noVideo = TheoryQuestion(
      id: 4,
      text: 't',
      part: TheoryPart.basic,
      points: 1,
      answers: const ['TAK', 'NIE'],
      correctIndex: 0,
    );
    await cache.ensure(a);
    downloader.calls.clear();

    final progress = await cache.prepare([a, b, shared, noVideo]).toList();
    expect(downloader.calls, ['theory_exam/videos/2026-07/b.mp4']);
    expect(progress.last, 1.0);
    expect(await cache.prepare([a, b]).toList(), [1.0]);
  });

  test('size and clear', () async {
    await cache.ensure(videoQuestion(1, 'a.mp4'));
    await cache.ensure(videoQuestion(2, 'b.mp4'));
    expect(await cache.sizeBytes(), 20);
    await cache.clear();
    expect(await cache.sizeBytes(), 0);
    expect(await cache.localFile(videoQuestion(1, 'a.mp4')), isNull);
  });
}
