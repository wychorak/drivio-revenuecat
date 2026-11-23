import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/models.dart';
import 'package:drivio/features/theory_exam/question_bank.dart';
import 'package:drivio/providers/theory_exam_provider.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/ads/premium_aware_banner_ad.dart';
import 'package:drivio/widgets/common/loading_widget.dart';

const _topicIcons = <TheoryTopic, IconData>{
  TheoryTopic.priority: Icons.alt_route_rounded,
  TheoryTopic.overtaking: Icons.swap_horiz_rounded,
  TheoryTopic.pedestrians: Icons.directions_walk_rounded,
  TheoryTopic.speed: Icons.speed_rounded,
  TheoryTopic.parking: Icons.local_parking_rounded,
  TheoryTopic.signs: Icons.traffic_rounded,
  TheoryTopic.vehicle: Icons.directions_car_rounded,
  TheoryTopic.general: Icons.route_rounded,
  TheoryTopic.railway: Icons.train_rounded,
  TheoryTopic.conditions: Icons.wb_twilight_rounded,
  TheoryTopic.firstAid: Icons.medical_services_rounded,
  TheoryTopic.motorway: Icons.add_road_rounded,
  TheoryTopic.alcohol: Icons.no_drinks_rounded,
};

IconData _iconFor(LearnSection s) => switch (s.key) {
  'all' => Icons.menu_book_rounded,
  'video' => Icons.movie_rounded,
  _ => _topicIcons[s.topic] ?? Icons.label_rounded,
};

/// Picks what to learn or review: all questions, questions with a film, or
/// one topic. Learning shows progress per category, mistakes their count.
class TheorySectionsScreen extends ConsumerWidget {
  const TheorySectionsScreen({super.key, required this.mode})
    : assert(mode != PracticeMode.random);

  final PracticeMode mode;

  bool get _mistakes => mode == PracticeMode.mistakes;

  List<LearnSection> _sections(QuestionBank bank) => [
    LearnSection.all,
    if (bank.questions.any((q) => q.hasVideo)) LearnSection.video,
    for (final t in TheoryTopic.values)
      if (bank.questions.any((q) => q.topic == t)) LearnSection.topic(t),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(theoryQuestionBankProvider);
    final progress = ref.watch(theoryProgressProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_mistakes ? 'Powtórka błędów' : 'Nauka')),
      bottomNavigationBar: const PremiumAwareBannerAd(),
      body: switch ((bank, progress)) {
        (AsyncData(value: final b), AsyncData(value: final p)) => _list(
          context,
          b,
          p,
        ),
        (AsyncError(), _) || (_, AsyncError()) => const Center(
          child: Text('Nie udało się wczytać pytań.'),
        ),
        _ => const LoadingWidget(),
      },
    );
  }

  Widget _list(BuildContext context, QuestionBank bank, TheoryProgress p) {
    final mistakes = p.mistakes;
    final tiles = <Widget>[];
    for (final section in _sections(bank)) {
      final questions = bank.questions.where(section.contains).toList();
      if (_mistakes) {
        final count = questions.where((q) => mistakes.contains(q.id)).length;
        if (count == 0) continue;
        tiles.add(
          _SectionTile(
            icon: _iconFor(section),
            title: section == LearnSection.all
                ? 'Wszystkie błędy'
                : section.label,
            trailing: '$count',
            onTap: () => context.push('/theory/mistakes/${section.key}'),
          ),
        );
      } else {
        final seen = questions.where((q) => p.stats.containsKey(q.id)).length;
        tiles.add(
          _SectionTile(
            icon: _iconFor(section),
            title: section.label,
            trailing: '$seen / ${questions.length}',
            progress: questions.isEmpty ? 0 : seen / questions.length,
            onTap: () => context.push('/theory/learn/${section.key}'),
          ),
        );
      }
    }

    if (tiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.celebration_rounded,
                size: 56,
                color: AppTheme.primaryBright,
              ),
              const SizedBox(height: 14),
              Text(
                'Brak błędów do powtórki',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: tiles,
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  /// Share of the section already answered; learning only.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryBright),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppTheme.bgElevated,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  trailing,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
