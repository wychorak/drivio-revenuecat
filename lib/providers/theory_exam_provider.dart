import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/progress_repository.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/features/theory_exam/video_cache.dart';

/// Wall clock used by the theory section; overridden in tests.
final theoryClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final theoryQuestionBankProvider = FutureProvider<QuestionBank>(
  (ref) => QuestionBank.load(rootBundle),
);

final theoryProgressRepositoryProvider = Provider<TheoryProgressRepository>(
  (ref) => SharedPrefsTheoryProgressRepository(),
);

/// Downloads through the Firebase SDK, so the request carries the user's
/// sign-in and App Check token that the Storage rules require.
class FirebaseVideoDownloader implements VideoDownloader {
  /// Firebase retries a lost connection for up to 10 minutes by default;
  /// a learner offline should hear about it much sooner.
  static const timeout = Duration(seconds: 60);

  @override
  Future<void> download(String storagePath, File target) async {
    final task = FirebaseStorage.instance.ref(storagePath).writeToFile(target);
    try {
      await task.timeout(timeout);
    } on TimeoutException {
      await task.cancel();
      rethrow;
    }
  }
}

/// Videos live in the cache directory: iOS keeps it out of iCloud backups
/// (Apple asks that re-downloadable data is not backed up) and may clear it
/// when space runs low, in which case the videos are fetched again.
final theoryVideoCacheProvider = Provider<TheoryVideoStore>(
  (ref) => TheoryVideoCache(
    directory: () async => Directory(
      '${(await getApplicationCacheDirectory()).path}'
      '${Platform.pathSeparator}theory_videos',
    ),
    downloader: FirebaseVideoDownloader(),
  ),
);

/// Bytes of downloaded videos; invalidate after downloads or clearing.
final theoryVideoCacheSizeProvider = FutureProvider<int>(
  (ref) => ref.watch(theoryVideoCacheProvider).sizeBytes(),
);

final theoryProgressProvider =
    AsyncNotifierProvider<TheoryProgressNotifier, TheoryProgress>(
      TheoryProgressNotifier.new,
    );

class TheoryProgressNotifier extends AsyncNotifier<TheoryProgress> {
  @override
  Future<TheoryProgress> build() =>
      ref.watch(theoryProgressRepositoryProvider).load();

  Future<void> _update(TheoryProgress Function(TheoryProgress) change) async {
    final current = state.value ?? await future;
    final next = change(current);
    state = AsyncData(next);
    await ref.read(theoryProgressRepositoryProvider).save(next);
  }

  Future<void> recordAnswer(int id, bool correct) => _update(
    (p) => p.recordAnswer(id, correct, ref.read(theoryClockProvider)()),
  );

  Future<void> addExam(ExamRecord record) => _update((p) => p.addExam(record));

  Future<void> setLearnCursor(int index) =>
      _update((p) => p.copyWith(learnCursor: index));
}

enum PracticeMode { random, learn, mistakes }

class PracticeFilter {
  const PracticeFilter({this.part, this.points, this.onlyUnseen = false});

  final TheoryPart? part;
  final int? points;
  final bool onlyUnseen;

  bool get isEmpty => part == null && points == null && !onlyUnseen;
}

/// Questions for a practice session: random = whole bank shuffled,
/// learn = filtered and in catalogue order, mistakes = last answered wrong.
List<TheoryQuestion> practiceQueue(
  QuestionBank bank,
  TheoryProgress progress,
  PracticeMode mode,
  PracticeFilter filter,
  Random rng,
) {
  switch (mode) {
    case PracticeMode.random:
      return [...bank.questions]..shuffle(rng);
    case PracticeMode.learn:
      return bank.questions
          .where(
            (q) =>
                (filter.part == null || q.part == filter.part) &&
                (filter.points == null || q.points == filter.points) &&
                (!filter.onlyUnseen || !progress.stats.containsKey(q.id)),
          )
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    case PracticeMode.mistakes:
      final ids = progress.mistakes;
      return bank.questions.where((q) => ids.contains(q.id)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  }
}
