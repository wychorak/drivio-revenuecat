import 'dart:async';
import 'dart:io';

import 'package:drivio/features/theory_exam/models.dart';

/// Fetches one video from Firebase Storage into [target]; replaced in tests.
abstract class VideoDownloader {
  Future<void> download(String storagePath, File target);
}

/// What the screens need from the video cache; a fake replaces it in widget
/// tests, which cannot do real file I/O.
abstract class TheoryVideoStore {
  Future<File?> localFile(TheoryQuestion question);
  Future<File> ensure(TheoryQuestion question);
  Stream<double> prepare(List<TheoryQuestion> questions);
  Future<int> sizeBytes();
  Future<void> clear();
}

/// Keeps the exam videos on the device for good: each one is downloaded at
/// most once. File names are content hashes, so a changed video in a new
/// question bank gets a new name instead of reusing a stale copy.
class TheoryVideoCache implements TheoryVideoStore {
  TheoryVideoCache({
    required Future<Directory> Function() directory,
    required VideoDownloader downloader,
  }) : _directory = directory,
       _downloader = downloader;

  final Future<Directory> Function() _directory;
  final VideoDownloader _downloader;
  final _inFlight = <String, Future<File>>{};

  Future<File> _fileFor(String storagePath) async {
    final dir = await _directory();
    return File('${dir.path}${Platform.pathSeparator}'
        '${storagePath.split('/').last}');
  }

  /// The downloaded video of [question], or null when it is not on the device.
  @override
  Future<File?> localFile(TheoryQuestion question) async {
    final path = question.video;
    if (path == null) return null;
    final file = await _fileFor(path);
    return file.existsSync() ? file : null;
  }

  /// Returns the video file, downloading it first when needed. Concurrent
  /// calls for the same video share one download.
  @override
  Future<File> ensure(TheoryQuestion question) {
    final path = question.video;
    if (path == null) {
      throw ArgumentError('Question ${question.id} has no video');
    }
    // The block body matters: `=> _inFlight.remove(path)` would return this
    // very future, and whenComplete would then wait on itself forever.
    return _inFlight[path] ??= _download(path).whenComplete(() {
      _inFlight.remove(path);
    });
  }

  Future<File> _download(String storagePath) async {
    final file = await _fileFor(storagePath);
    if (file.existsSync()) return file;
    await file.parent.create(recursive: true);
    // Written next to the target and renamed only when complete, so a cut
    // connection never leaves a broken video that looks downloaded.
    final part = File('${file.path}.part');
    try {
      await _downloader.download(storagePath, part);
      return await part.rename(file.path);
    } catch (_) {
      if (part.existsSync()) await part.delete();
      rethrow;
    }
  }

  /// Downloads the missing videos of [questions]; emits progress from 0 to 1
  /// by size and ends with 1.0. Errors are passed on to the listener.
  @override
  Stream<double> prepare(List<TheoryQuestion> questions) async* {
    final missing = <String, TheoryQuestion>{};
    for (final q in questions.where((q) => q.hasVideo)) {
      if (missing.containsKey(q.video)) continue;
      if (await localFile(q) == null) missing[q.video!] = q;
    }
    final total = missing.values.fold<int>(
      0,
      (sum, q) => sum + (q.videoBytes ?? 1),
    );
    var done = 0;
    for (final q in missing.values) {
      if (total > 0) yield done / total;
      await ensure(q);
      done += q.videoBytes ?? 1;
    }
    yield 1.0;
  }

  /// Bytes taken by downloaded videos.
  @override
  Future<int> sizeBytes() async {
    final dir = await _directory();
    if (!dir.existsSync()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Removes every downloaded video.
  @override
  Future<void> clear() async {
    final dir = await _directory();
    if (!dir.existsSync()) return;
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }
  }
}
