import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/common/loading_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TrapModel> _savedTraps = [];
  List<SchoolModel> _savedSchools = [];
  bool _loadingSaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    setState(() => _loadingSaved = true);
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.value;
    if (user == null) {
      setState(() => _loadingSaved = false);
      return;
    }
    if (ref.read(devLoginProvider)) {
      if (mounted) {
        setState(() {
          _savedTraps = DevDataService.savedTraps(user.savedTraps);
          _savedSchools = DevDataService.savedSchools(user.savedSchools);
          _loadingSaved = false;
        });
      }
      return;
    }
    final fs = ref.read(firestoreServiceProvider);
    try {
      final traps = await fs.getSavedTraps(user.savedTraps);
      final schools = await fs.getSavedSchools(user.savedSchools);
      if (mounted) {
        setState(() {
          _savedTraps = traps;
          _savedSchools = schools;
        });
      }
    } catch (error) {
      debugPrint('Profile: saved items unavailable: $error');
    } finally {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The user document often arrives after the first frame, and saving from
    // another screen changes these lists, so reload when they change.
    ref.listen(currentUserProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (after == null) return;
      if (before == null ||
          !listEquals(before.savedTraps, after.savedTraps) ||
          !listEquals(before.savedSchools, after.savedSchools)) {
        _loadSaved();
      }
    });
    final userAsync = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final adminAccess = ref.watch(adminAccessProvider).value;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mój profil'),
        actions: [
          IconButton(
            tooltip: 'Ustawienia',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.primary),
            onPressed: () async {
              ref.read(devLoginProvider.notifier).state = false;
              await ref.read(authServiceProvider).signOut();
              await Future<void>.delayed(const Duration(milliseconds: 100));
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Zaloguj się'),
              ),
            );
          }

          final initials = user.displayName.isNotEmpty
              ? user.displayName
                    .split(' ')
                    .take(2)
                    .map((w) => w[0])
                    .join()
                    .toUpperCase()
              : 'U';

          return NestedScrollView(
            headerSliverBuilder: (_, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.primary.withAlpha(30),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                initials,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: GoogleFonts.poppins(
                          color: colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.poppins(
                          color: colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      if (adminAccess?.emailListed == true) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (adminAccess?.isAdmin == true
                                        ? Colors.green
                                        : Colors.orange)
                                    .withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: adminAccess?.isAdmin == true
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                          child: Text(
                            adminAccess?.isAdmin == true
                                ? 'Administrator zweryfikowany'
                                : 'Brak claimu administratora',
                            style: GoogleFonts.poppins(
                              color: adminAccess?.isAdmin == true
                                  ? AppTheme.successColor
                                  : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.premiumGold.withAlpha(30),
                                AppTheme.premiumGold.withAlpha(10),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.premiumGold.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.premiumGold,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Drivio Premium',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.premiumGold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (user.premiumUntil != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'do ${user.premiumUntil!.day}.${user.premiumUntil!.month.toString().padLeft(2, '0')}.${user.premiumUntil!.year}',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.premiumGold.withAlpha(180),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/premium'),
                            icon: const Icon(Icons.star_rounded, size: 16),
                            label: const Text('Kup Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.premiumGold,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Miejsca'),
                          Tab(text: 'Szkoły'),
                          Tab(text: 'Wideo'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _loadingSaved ? const LoadingWidget() : _buildSavedTraps(),
                _loadingSaved ? const LoadingWidget() : _buildSavedSchools(),
                isPremium ? _buildVideosTab() : _buildLockedTab(),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (_, _) => Center(
          child: Text(
            'Błąd ładowania profilu',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTraps() {
    final colors = Theme.of(context).colorScheme;
    if (_savedTraps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              color: colors.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Brak zapisanych pułapek',
              style: GoogleFonts.poppins(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Fixed height: photo (100) + two title lines + stars, on any width.
        mainAxisExtent: 176,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _savedTraps.length,
      itemBuilder: (ctx, i) {
        final trap = _savedTraps[i];
        return GestureDetector(
          onTap: () => context.push('/trap/${trap.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trap.photoUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      trap.photoUrl!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 100,
                        color: colors.surfaceContainerHighest,
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trap.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: colors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          trap.difficulty,
                          (_) => const Icon(
                            Icons.star,
                            color: AppTheme.primary,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedSchools() {
    final colors = Theme.of(context).colorScheme;
    if (_savedSchools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              color: colors.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Brak zapisanych szkół',
              style: GoogleFonts.poppins(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedSchools.length,
      itemBuilder: (ctx, i) {
        final school = _savedSchools[i];
        return GestureDetector(
          onTap: () => context.push('/school/${school.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outline.withAlpha(120)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.surfaceContainerHighest,
                  backgroundImage: school.logoUrl != null
                      ? NetworkImage(school.logoUrl!)
                      : null,
                  child: school.logoUrl == null
                      ? Icon(
                          Icons.school_rounded,
                          color: colors.onSurfaceVariant,
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
                        style: GoogleFonts.poppins(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          Text(
                            ' ${school.rating.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: colors.onSurfaceVariant,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Wideo – wkrótce dostępne',
            style: GoogleFonts.poppins(
              color: colors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedTab() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, color: AppTheme.premiumGold, size: 48),
          const SizedBox(height: 12),
          Text(
            'Filmy instruktażowe w Premium',
            style: GoogleFonts.poppins(color: colors.onSurface, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Odblokuj nieograniczony dostęp do filmów',
            style: GoogleFonts.poppins(
              color: colors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.premiumGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Kup Premium'),
          ),
        ],
      ),
    );
  }
}
