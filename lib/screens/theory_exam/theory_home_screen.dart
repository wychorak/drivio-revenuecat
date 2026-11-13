import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/exam_engine.dart';
import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/providers/theory_ad_provider.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/services/analytics_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/ads/premium_aware_banner_ad.dart';
import 'package:drivio/widgets/common/loading_widget.dart';

const theorySourceNote =
    'Pytania: Ministerstwo Infrastruktury, stan 07.2026. '
    'Pytania z filmami nie są uwzględnione.';

class TheoryHomeScreen extends ConsumerStatefulWidget {
  const TheoryHomeScreen({super.key});

  @override
  ConsumerState<TheoryHomeScreen> createState() => _TheoryHomeScreenState();
}

class _TheoryHomeScreenState extends ConsumerState<TheoryHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Starts the ad warm-up clock and preloads the first interstitial.
    ref.read(theoryAdControllerProvider);
  }

  void _open(String mode, String path) {
    AnalyticsService.instance.theoryModeOpen(mode);
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(theoryQuestionBankProvider);
    final progress = ref.watch(theoryProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Egzamin teoretyczny')),
      bottomNavigationBar: const PremiumAwareBannerAd(),
      body: switch ((bank, progress)) {
        (AsyncData(value: final b), AsyncData(value: final p)) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ProgressCard(total: b.questions.length, progress: p),
            const SizedBox(height: 16),
            _ModeTile(
              icon: Icons.shuffle_rounded,
              title: 'Losuj pytanie',
              subtitle: 'Losowe pytania bez limitu czasu',
              onTap: () => _open('random', '/theory/random'),
            ),
            _ModeTile(
              icon: Icons.timer_outlined,
              title: 'Pełny egzamin',
              subtitle: '32 pytania, 25 minut, jak w WORD',
              highlight: true,
              onTap: () => _open('exam', '/theory/exam'),
            ),
            _ModeTile(
              icon: Icons.menu_book_rounded,
              title: 'Nauka',
              subtitle: 'Wszystkie pytania po kolei, z filtrami',
              onTap: () => _open('learn', '/theory/learn'),
            ),
            _ModeTile(
              icon: Icons.replay_rounded,
              title: 'Powtórka błędów',
              subtitle: p.mistakes.isEmpty
                  ? 'Brak błędów do powtórki'
                  : 'Pytań do powtórki: ${p.mistakes.length}',
              onTap: () => _open('mistakes', '/theory/mistakes'),
            ),
            const SizedBox(height: 16),
            Text(
              theorySourceNote,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        (AsyncError(), _) || (_, AsyncError()) => const Center(
          child: Text('Nie udało się wczytać pytań.'),
        ),
        _ => const LoadingWidget(),
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.total, required this.progress});

  final int total;
  final TheoryProgress progress;

  int get _passStreak {
    var streak = 0;
    for (final exam in progress.exams) {
      if (!exam.passed) break;
      streak++;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final last = progress.exams.isEmpty ? null : progress.exams.first;
    final label = GoogleFonts.poppins(
      fontSize: 13,
      color: AppTheme.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Przerobione pytania',
            style: label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.seenCount} / $total',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : progress.seenCount / total,
              minHeight: 6,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Skuteczność: ${(progress.accuracy * 100).round()}%',
            style: label.copyWith(color: Colors.white),
          ),
          if (last != null)
            Text(
              'Ostatni egzamin: ${last.score}/$examMaxScore · '
              '${last.passed ? 'zdany' : 'niezdany'}'
              '${_passStreak > 1 ? ' · zdane z rzędu: $_passStreak' : ''}',
              style: label.copyWith(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highlight ? AppTheme.primary : AppTheme.dividerColor,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryBright),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
