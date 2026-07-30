import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final traps = await fs.getSavedTraps(user.savedTraps);
    final schools = await fs.getSavedSchools(user.savedSchools);
    if (mounted) {
      setState(() {
        _savedTraps = traps;
        _savedSchools = schools;
        _loadingSaved = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    if (ref.read(devLoginProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Edycja jest wyłączona w trybie podglądu.'),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: user.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Edytuj profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.length >= 2) Navigator.pop(dialogContext, value);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName == user.displayName || !mounted) return;

    try {
      await ref.read(authServiceProvider).updateDisplayName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil został zaktualizowany.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się zapisać zmian.')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Usuń konto',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Czy na pewno chcesz usunąć swoje konto? Ta operacja jest nieodwracalna.',
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (ref.read(devLoginProvider)) {
        ref.read(devLoginProvider.notifier).state = false;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        context.go('/login');
        return;
      }
      try {
        await ref.read(authServiceProvider).deleteAccount();
        if (mounted) context.go('/login');
      } on FirebaseAuthException catch (error) {
        if (!mounted) return;
        final requiresLogin = error.code == 'requires-recent-login';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              requiresLogin
                  ? 'Dla bezpieczeństwa wyloguj się, zaloguj ponownie i od razu ponów usunięcie konta.'
                  : 'Nie udało się usunąć konta. Spróbuj ponownie.',
            ),
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się usunąć konta. Spróbuj ponownie.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final adminAccess = ref.watch(adminAccessProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Mój profil'),
        backgroundColor: AppTheme.bgDark,
        actions: [
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
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
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
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
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
        error: (_, _) => const Center(
          child: Text(
            'Błąd ładowania profilu',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ),
      bottomSheet: _buildSettingsSheet(),
    );
  }

  Widget _buildSavedTraps() {
    if (_savedTraps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_outline,
              color: AppTheme.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Brak zapisanych pułapek',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
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
        childAspectRatio: 0.85,
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
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trap.photoUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      trap.photoUrl!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 100,
                        color: AppTheme.bgDark,
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
                    decoration: const BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
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
                          color: Colors.white,
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
    if (_savedSchools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              color: AppTheme.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Brak zapisanych szkół',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
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
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.bgDark,
                  backgroundImage: school.logoUrl != null
                      ? NetworkImage(school.logoUrl!)
                      : null,
                  child: school.logoUrl == null
                      ? const Icon(
                          Icons.school_rounded,
                          color: AppTheme.textSecondary,
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
                          color: Colors.white,
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
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.play_circle_outline,
            color: AppTheme.textSecondary,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Wideo – wkrótce dostępne',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, color: AppTheme.premiumGold, size: 48),
          const SizedBox(height: 12),
          Text(
            'Filmy instruktażowe w Premium',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Odblokuj nieograniczony dostęp do filmów',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
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

  Widget _buildSettingsSheet() {
    return Container(
      color: AppTheme.bgCard,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1, color: AppTheme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edytuj profil'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      label: const Text(
                        'Usuń konto',
                        style: TextStyle(color: AppTheme.primary),
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
  }
}
