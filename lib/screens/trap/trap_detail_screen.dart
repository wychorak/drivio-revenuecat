import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/traps_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/content_moderation_service.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/trap/difficulty_stars.dart';
import 'package:drivio/widgets/trap/comment_tile.dart';
import 'package:drivio/widgets/common/loading_widget.dart';

class TrapDetailScreen extends ConsumerStatefulWidget {
  final String trapId;
  const TrapDetailScreen({super.key, required this.trapId});

  @override
  ConsumerState<TrapDetailScreen> createState() => _TrapDetailScreenState();
}

class _TrapDetailScreenState extends ConsumerState<TrapDetailScreen> {
  TrapModel? _trap;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSaved = false;
  final _commentController = TextEditingController();
  bool _accessDenied = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTrap();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTrap() async {
    try {
      if (!ref.read(devLoginProvider)) {
        final user = ref.read(authStateProvider).value;
        if (user == null) {
          if (mounted) {
            setState(() {
              _loadError = 'Zaloguj się, aby zobaczyć szczegóły pułapki.';
              _isLoading = false;
            });
          }
          return;
        }

        final allowed = await ref
            .read(dailyLimitServiceProvider)
            .consumeTrapView(user.uid, ref.read(isPremiumProvider));
        if (!mounted) return;
        if (!allowed) {
          setState(() {
            _accessDenied = true;
            _isLoading = false;
          });
          return;
        }
        ref.invalidate(remainingViewsProvider);
      }

      final trap = ref.read(devLoginProvider)
          ? DevDataService.trapById(widget.trapId)
          : await ref.read(firestoreServiceProvider).getTrapById(widget.trapId);
      if (!mounted) return;
      setState(() {
        _trap = trap;
        _isLoading = false;
      });
      _checkSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Nie udało się załadować pułapki. Spróbuj ponownie.';
        _isLoading = false;
      });
    }
  }

  void _checkSaved() {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((user) {
      if (mounted && user != null && _trap != null) {
        setState(() => _isSaved = user.isTrapSavedById(_trap!.id));
      }
    });
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    if (ref.read(devLoginProvider)) {
      if (_trap == null) return;
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEV: zapis lokalny tylko do podgladu')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null || _trap == null) return;

    final willSave = !_isSaved;
    setState(() => _isSaving = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      if (_isSaved) {
        await fs.unsaveTrap(user.uid, _trap!.id);
      } else {
        await fs.saveTrap(user.uid, _trap!.id);
      }
      if (mounted) {
        setState(() => _isSaved = willSave);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willSave
                  ? 'Pułapka dodana do zapisanych.'
                  : 'Pułapka usunięta z zapisanych.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać pułapki. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _trap == null) return;
    final moderationError = ContentModerationService.validateText(text);
    if (moderationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(moderationError)));
      return;
    }

    if (ref.read(devLoginProvider)) {
      _commentController.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DEV: komentarz nie zapisuje Firestore'),
          ),
        );
      }
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final userAsync = ref.read(currentUserProvider);
    final userData = userAsync.value;

    final comment = CommentModel(
      id: '',
      itemId: _trap!.id,
      itemType: 'trap',
      userId: user.uid,
      userDisplayName:
          userData?.displayName ?? user.displayName ?? 'Użytkownik',
      text: text,
      timestamp: DateTime.now(),
    );

    try {
      await ref.read(firestoreServiceProvider).addComment(comment);
      _commentController.clear();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się dodać komentarza.')),
        );
      }
    }
  }

  Future<void> _blockUser(String blockedUid) async {
    if (ref.read(devLoginProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DEV: blokowanie jest wylaczone lokalnie'),
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null || blockedUid.isEmpty || user.uid == blockedUid) return;
    await ref.read(firestoreServiceProvider).blockUser(user.uid, blockedUid);
    ref.invalidate(currentUserProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Użytkownik został zablokowany.')),
      );
    }
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Dodaj komentarz',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Twój komentarz...',
            hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.bgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(onPressed: _addComment, child: const Text('Wyślij')),
        ],
      ),
    );
  }

  void _showCommentAccessMessage() {
    final user = ref.read(authStateProvider).value;
    final message = user?.isAnonymous == true
        ? 'Komentarze są dostępne po założeniu konta.'
        : 'Potwierdź adres e-mail, aby dodawać komentarze.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _reportTrap() {
    final reasons = ['Fałszywe informacje', 'Obraźliwa treść', 'Spam', 'Inne'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Zgłoś pułapkę',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...reasons.map(
              (r) => ListTile(
                title: Text(
                  r,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (ref.read(devLoginProvider)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('DEV: zgloszenie nie zapisuje Firestore'),
                      ),
                    );
                    return;
                  }
                  final authState = ref.read(authStateProvider);
                  final user = authState.value;
                  if (user == null || _trap == null) return;
                  await ref
                      .read(firestoreServiceProvider)
                      .reportContent(
                        ReportModel(
                          id: '',
                          itemId: _trap!.id,
                          itemType: 'trap',
                          reason: r,
                          reporterId: user.uid,
                          timestamp: DateTime.now(),
                        ),
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Zgłoszenie wysłane')),
                    );
                  }
                },
              ),
            ),
            if (_trap?.createdBy.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.block, color: AppTheme.primary),
                title: Text(
                  'Zablokuj autora',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _blockUser(_trap!.createdBy);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: LoadingWidget(),
      );
    }

    if (_accessDenied) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(backgroundColor: AppTheme.bgDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  color: AppTheme.premiumGold,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dzienny limit został wykorzystany',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wróć jutro albo odblokuj nielimitowany dostęp w Premium.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/premium'),
                  child: const Text('Zobacz Premium'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(backgroundColor: AppTheme.bgDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: AppTheme.textSecondary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadError = null;
                    });
                    _loadTrap();
                  },
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_trap == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(title: const Text('Nie znaleziono')),
        body: const Center(
          child: Text(
            'Pułapka nie istnieje',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final trap = _trap!;
    final isPremium = ref.watch(isPremiumProvider);
    final authUser = ref.watch(authStateProvider).value;
    final canComment = authUser != null && authUser.emailVerified;
    final isAdmin = ref.watch(adminAccessProvider).value?.isAdmin ?? false;
    final commentsAsync = ref.watch(commentsProvider(trap.id));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          color: _isSaved ? AppTheme.primary : Colors.white,
                          size: 22,
                        ),
                ),
                onPressed: _isSaving ? null : _toggleSave,
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard.withAlpha(200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: _reportTrap,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: trap.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: trap.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppTheme.bgCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppTheme.bgCard,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppTheme.textSecondary,
                          size: 48,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.bgCard,
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.primary,
                        size: 64,
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge('Pułapka', AppTheme.primary),
                      const SizedBox(width: 8),
                      _badge(trap.city, AppTheme.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trap.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DifficultyStars(difficulty: trap.difficulty),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM yyyy', 'pl').format(trap.createdAt),
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Opis błędu'),
                  const SizedBox(height: 8),
                  Text(
                    trap.description,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Zasada ruchu drogowego'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.routeBlue.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.routeBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            trap.ruleDescription.isNotEmpty
                                ? trap.ruleDescription
                                : 'Brak opisu zasady',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Wskazówka wideo'),
                  const SizedBox(height: 8),
                  if (!isPremium)
                    _videoPremiumLock(isPremium)
                  else if (trap.videoUrl?.trim().isNotEmpty == true)
                    _videoPremiumPlayer(trap.videoUrl!.trim())
                  else
                    _videoUnavailable(),
                  const SizedBox(height: 24),
                  commentsAsync.when(
                    data: (comments) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle('Komentarze (${comments.length})'),
                            TextButton.icon(
                              onPressed: canComment
                                  ? _showCommentDialog
                                  : _showCommentAccessMessage,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Dodaj'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (comments.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Bądź pierwszy i dodaj komentarz!',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...comments.map(
                            (c) => CommentTile(
                              comment: c,
                              onBlock:
                                  c.userId.isNotEmpty &&
                                      c.userId != authUser?.uid
                                  ? () => _blockUser(c.userId)
                                  : null,
                              onDelete: c.userId == authUser?.uid || isAdmin
                                  ? () => ref
                                        .read(firestoreServiceProvider)
                                        .deleteComment(c.id)
                                  : null,
                              onReport: !canComment || c.userId == authUser.uid
                                  ? null
                                  : (reason) async {
                                      if (ref.read(devLoginProvider)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'DEV: zgloszenie komentarza nie zapisuje Firestore',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final authState = ref.read(
                                        authStateProvider,
                                      );
                                      final user = authState.value;
                                      if (user == null) return;
                                      await ref
                                          .read(firestoreServiceProvider)
                                          .reportContent(
                                            ReportModel(
                                              id: '',
                                              itemId: c.id,
                                              itemType: 'comment',
                                              reason: reason,
                                              reporterId: user.uid,
                                              timestamp: DateTime.now(),
                                            ),
                                          );
                                    },
                            ),
                          ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Text(
                      'Błąd ładowania komentarzy',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        uri.hasScheme &&
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się otworzyć wideo.')),
      );
    }
  }

  Widget _videoPremiumPlayer(String url) {
    return Material(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openVideo(url),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_rounded,
                  color: AppTheme.primary,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Odtwórz wideo',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoUnavailable() {
    return Container(
      height: 96,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.videocam_off_outlined,
            color: AppTheme.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dla tego miejsca nie ma jeszcze wskazówki wideo.',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPremiumLock(bool isPremium) {
    return Stack(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.play_circle_rounded,
              color: AppTheme.textSecondary,
              size: 48,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withAlpha(200),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.premiumGold.withAlpha(80)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: AppTheme.premiumGold,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium',
                  style: GoogleFonts.poppins(
                    color: AppTheme.premiumGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/premium'),
                  child: Text(
                    'Odblokuj teraz →',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
