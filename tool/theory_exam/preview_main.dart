// Standalone preview of the theory exam section, without Firebase or ads.
// Run: flutter run -d chrome -t tool/theory_exam/preview_main.dart
// The browser has no local files, so films behave as on a phone without
// internet: practice skips film questions, the exam offers the variant
// without films.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/video_cache.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/screens/theory_exam/theory_exam_result_screen.dart';
import 'package:drivio/screens/theory_exam/theory_exam_screen.dart';
import 'package:drivio/screens/theory_exam/theory_home_screen.dart';
import 'package:drivio/screens/theory_exam/theory_practice_screen.dart';
import 'package:drivio/theme/app_theme.dart';

class _OfflineVideos implements TheoryVideoStore {
  @override
  Future<File?> localFile(TheoryQuestion question) async => null;

  @override
  Future<File> ensure(TheoryQuestion question) =>
      Future.error(const SocketException('preview is offline'));

  @override
  Stream<double> prepare(List<TheoryQuestion> questions) async* {
    if (questions.any((q) => q.hasVideo)) {
      throw const SocketException('preview is offline');
    }
    yield 1.0;
  }

  @override
  Future<int> sizeBytes() async => 0;

  @override
  Future<void> clear() async {}
}

void main() {
  final router = GoRouter(
    initialLocation: '/theory',
    routes: [
      GoRoute(path: '/theory', builder: (_, _) => const TheoryHomeScreen()),
      for (final mode in PracticeMode.values)
        GoRoute(
          path: '/theory/${mode.name}',
          builder: (_, _) => TheoryPracticeScreen(mode: mode),
        ),
      GoRoute(path: '/theory/exam', builder: (_, _) => const TheoryExamScreen()),
      GoRoute(
        path: '/theory/exam/result',
        builder: (_, state) =>
            TheoryExamResultScreen(record: state.extra! as ExamRecord),
      ),
    ],
  );
  runApp(
    ProviderScope(
      overrides: [
        isPremiumProvider.overrideWithValue(true),
        premiumStatusResolvedProvider.overrideWithValue(true),
        theoryAdsPremiumProvider.overrideWithValue(true),
        theoryVideoCacheProvider.overrideWithValue(_OfflineVideos()),
        theoryInterstitialProvider.overrideWithValue(
          TheoryInterstitial(preload: () async {}, show: () async => false),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
}
