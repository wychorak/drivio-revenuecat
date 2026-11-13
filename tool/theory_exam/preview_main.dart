// Standalone preview of the theory exam section, without Firebase or ads.
// Run: flutter run -d chrome -t tool/theory_exam/preview_main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/screens/theory_exam/theory_exam_result_screen.dart';
import 'package:drivio/screens/theory_exam/theory_exam_screen.dart';
import 'package:drivio/screens/theory_exam/theory_home_screen.dart';
import 'package:drivio/screens/theory_exam/theory_practice_screen.dart';
import 'package:drivio/theme/app_theme.dart';

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
