import 'dart:async';
import 'dart:io';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/video_cache.dart';
import 'package:drivio/features/theory_exam/video_playback.dart';
import 'package:drivio/features/theory_exam/progress_repository.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MemoryRepo implements TheoryProgressRepository {
  MemoryRepo([TheoryProgress? initial])
    : stored = initial ?? TheoryProgress.empty();
  TheoryProgress stored;
  @override
  Future<TheoryProgress> load() async => stored;
  @override
  Future<void> save(TheoryProgress progress) async => stored = progress;
}

/// Like [harnessBank]; basic questions in [videoBasics] get a film. With
/// [extraPlainBasics] each basic group also gets that many film-free ones.
QuestionBank videoBank({int extraPlainBasics = 0}) {
  final base = harnessBank();
  var id = 1000;
  return QuestionBank(
    sourceVersion: base.sourceVersion,
    questions: [
      for (final q in base.questions)
        q.isBasic
            ? TheoryQuestion(
                id: q.id,
                text: q.text,
                part: q.part,
                points: q.points,
                answers: q.answers,
                correctIndex: q.correctIndex,
                video: 'theory_exam/videos/2026-07/v${q.id}.mp4',
                videoBytes: 1000,
              )
            : q,
      for (final points in [3, 2, 1])
        for (var i = 0; i < extraPlainBasics; i++)
          TheoryQuestion(
            id: id++,
            text: 'Pytanie bez filmu $id?',
            part: TheoryPart.basic,
            points: points,
            answers: const ['TAK', 'NIE'],
            correctIndex: 0,
          ),
    ],
  );
}

/// Bank with enough questions for a full exam. Basic questions: correct
/// answer is TAK (index 0); specialist: A (index 0).
QuestionBank harnessBank({int perGroup = 12}) {
  final questions = <TheoryQuestion>[];
  var id = 1;
  for (final part in TheoryPart.values) {
    for (final points in [3, 2, 1]) {
      for (var i = 0; i < perGroup; i++) {
        questions.add(
          TheoryQuestion(
            id: id,
            text: 'Pytanie numer $id?',
            part: part,
            points: points,
            answers: part == TheoryPart.basic
                ? const ['TAK', 'NIE']
                : ['Odp A$id', 'Odp B$id', 'Odp C$id'],
            correctIndex: 0,
          ),
        );
        id++;
      }
    }
  }
  return QuestionBank(questions: questions, sourceVersion: '2026-07');
}

/// In-memory video cache: no real files, so it works under fake async.
class FakeVideoStore implements TheoryVideoStore {
  final local = <String>{};
  final ensured = <int>[];

  /// Ids of questions whose download fails, as if offline.
  final offline = <int>{};

  /// When set, downloads wait for it, so tests can see the progress screen.
  Completer<void>? hold;

  @override
  Future<File?> localFile(TheoryQuestion q) async =>
      local.contains(q.video) ? File(q.video!) : null;

  @override
  Future<File> ensure(TheoryQuestion q) async {
    ensured.add(q.id);
    await hold?.future;
    if (offline.contains(q.id)) throw const SocketException('offline');
    local.add(q.video!);
    return File(q.video!);
  }

  @override
  Stream<double> prepare(List<TheoryQuestion> questions) async* {
    final missing = [
      for (final q in questions)
        if (q.hasVideo && !local.contains(q.video)) q,
    ];
    for (var i = 0; i < missing.length; i++) {
      yield i / missing.length;
      await ensure(missing[i]);
    }
    yield 1.0;
  }

  @override
  Future<int> sizeBytes() async => local.length * 1000000;

  @override
  Future<void> clear() async => local.clear();
}

class FakeVideoController implements TheoryVideoController {
  FakeVideoController(this.file, this.onEnded);

  final File file;
  final VoidCallback onEnded;
  int plays = 0;
  bool disposed = false;

  /// Simulates the film reaching its end.
  void end() => onEnded();

  @override
  Future<void> initialize() async {}

  @override
  Duration get duration => const Duration(seconds: 8);

  @override
  double get aspectRatio => 16 / 9;

  @override
  Future<void> playFromStart() async => plays++;

  @override
  Widget view() => const SizedBox(key: Key('video-view'));

  @override
  Future<void> dispose() async => disposed = true;
}

class Harness {
  Harness({QuestionBank? bank, TheoryProgress? progress, FakeVideoStore? videos})
    : bank = bank ?? harnessBank(),
      repo = MemoryRepo(progress),
      videos = videos ?? FakeVideoStore();

  final QuestionBank bank;
  final MemoryRepo repo;
  final FakeVideoStore videos;
  final controllers = <FakeVideoController>[];
  DateTime now = DateTime(2026, 11, 13, 10);

  void advance(Duration d) => now = now.add(d);

  Widget app(String initialLocation, List<RouteBase> routes) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('start')),
        ...routes,
      ],
    );
    return ProviderScope(
      overrides: [
        theoryQuestionBankProvider.overrideWith((ref) async => bank),
        theoryProgressRepositoryProvider.overrideWithValue(repo),
        theoryClockProvider.overrideWithValue(() => now),
        theoryVideoCacheProvider.overrideWithValue(videos),
        theoryVideoControllerFactoryProvider.overrideWithValue(
          (file, {required onEnded}) {
            final c = FakeVideoController(file, onEnded);
            controllers.add(c);
            return c;
          },
        ),
        theoryAdsPremiumProvider.overrideWithValue(true),
        isPremiumProvider.overrideWithValue(true),
        premiumStatusResolvedProvider.overrideWithValue(true),
        theoryInterstitialProvider.overrideWithValue(
          TheoryInterstitial(preload: () async {}, show: () async => false),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }
}
