import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _rankingTrapsProvider = FutureProvider<List<TrapModel>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final city = prefs.getString('selectedCity') ?? AppConfig.defaultCity;
  if (ref.read(devLoginProvider)) {
    final traps = DevDataService.traps(city);
    traps.sort((a, b) => b.difficulty.compareTo(a.difficulty));
    return traps;
  }
  return ref.read(firestoreServiceProvider).getRankingTraps(city);
});

final _rankingSchoolsProvider = FutureProvider<List<SchoolModel>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final city = prefs.getString('selectedCity') ?? AppConfig.defaultCity;
  if (ref.read(devLoginProvider)) {
    final schools = DevDataService.schools(city);
    schools.sort((a, b) => b.rating.compareTo(a.rating));
    return schools;
  }
  return ref.read(firestoreServiceProvider).getRankingSchools(city);
});

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Ranking'),
        backgroundColor: AppTheme.bgDark,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Najtrudniejsze pułapki'),
            Tab(text: 'Najlepsze szkoły'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_TrapsRankingTab(), _SchoolsRankingTab()],
      ),
    );
  }
}

class _TrapsRankingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(_rankingTrapsProvider);

    return rankingAsync.when(
      data: (traps) {
        if (traps.isEmpty) {
          return Center(
            child: Text(
              'Brak danych',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: traps.length,
          itemBuilder: (ctx, i) {
            final trap = traps[i];
            final rank = i + 1;
            return _TrapRankItem(trap: trap, rank: rank);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, _) => Center(
        child: Text(
          'Błąd ładowania rankingu',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _TrapRankItem extends StatelessWidget {
  final TrapModel trap;
  final int rank;

  const _TrapRankItem({required this.trap, required this.rank});

  @override
  Widget build(BuildContext context) {
    Color rankColor = AppTheme.textSecondary;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return GestureDetector(
      onTap: () => context.push('/trap/${trap.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rank <= 3 ? rankColor.withAlpha(60) : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: rankColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (trap.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: trap.photoUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 52,
                    height: 52,
                    color: AppTheme.bgDark,
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trap.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        trap.difficulty,
                        (_) => const Icon(
                          Icons.star,
                          color: AppTheme.primary,
                          size: 13,
                        ),
                      ),
                      ...List.generate(
                        5 - trap.difficulty,
                        (_) => const Icon(
                          Icons.star_outline,
                          color: AppTheme.textSecondary,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trap.city,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolsRankingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(_rankingSchoolsProvider);

    return rankingAsync.when(
      data: (schools) {
        if (schools.isEmpty) {
          return Center(
            child: Text(
              'Brak danych',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: schools.length,
          itemBuilder: (ctx, i) {
            final school = schools[i];
            final rank = i + 1;
            return _SchoolRankItem(school: school, rank: rank);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (_, _) => Center(
        child: Text(
          'Błąd ładowania rankingu',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SchoolRankItem extends StatelessWidget {
  final SchoolModel school;
  final int rank;

  const _SchoolRankItem({required this.school, required this.rank});

  @override
  Widget build(BuildContext context) {
    Color rankColor = AppTheme.textSecondary;
    if (rank == 1) rankColor = const Color(0xFFFFD700);
    if (rank == 2) rankColor = const Color(0xFFC0C0C0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return GestureDetector(
      onTap: () => context.push('/school/${school.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rank <= 3 ? rankColor.withAlpha(60) : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: rankColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.bgDark,
              backgroundImage: school.logoUrl != null
                  ? CachedNetworkImageProvider(school.logoUrl!)
                  : null,
              child: school.logoUrl == null
                  ? const Icon(
                      Icons.school_rounded,
                      color: AppTheme.textSecondary,
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(
                        school.rating.floor(),
                        (_) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${school.rating.toStringAsFixed(1)} (${school.reviewCount})',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
