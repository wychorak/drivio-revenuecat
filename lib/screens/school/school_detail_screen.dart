import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/traps_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/content_moderation_service.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/services/dev_data_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/widgets/common/loading_widget.dart';
import 'package:drivio/widgets/trap/comment_tile.dart';

class SchoolDetailScreen extends ConsumerStatefulWidget {
  final String schoolId;
  const SchoolDetailScreen({super.key, required this.schoolId});

  @override
  ConsumerState<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen> {
  SchoolModel? _school;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isSaving = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchool();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSchool() async {
    final school = ref.read(devLoginProvider)
        ? DevDataService.schoolById(widget.schoolId)
        : await ref
              .read(firestoreServiceProvider)
              .getSchoolById(widget.schoolId);
    if (mounted) {
      setState(() {
        _school = school;
        _isLoading = false;
      });
      _checkSaved();
    }
  }

  void _checkSaved() {
    final user = ref.read(currentUserProvider).value;
    if (mounted && user != null && _school != null) {
      setState(() => _isSaved = user.isSchoolSavedById(_school!.id));
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaving || _school == null) return;
    if (ref.read(devLoginProvider)) {
      setState(() => _isSaved = !_isSaved);
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }
    final willSave = !_isSaved;
    setState(() => _isSaving = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      if (_isSaved) {
        await service.unsaveSchool(user.uid, _school!.id);
      } else {
        await service.saveSchool(user.uid, _school!.id);
      }
      if (mounted) {
        setState(() => _isSaved = willSave);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willSave
                  ? 'Szkoła dodana do zapisanych.'
                  : 'Szkoła usunięta z zapisanych.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się zapisać szkoły. Spróbuj ponownie.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _school == null) return;
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
          const SnackBar(content: Text('DEV: opinia nie zapisuje Firestore')),
        );
      }
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.value;
    if (user == null) return;

    final userAsync = ref.read(currentUserProvider);
    final userData = userAsync.value;

    try {
      await ref
          .read(firestoreServiceProvider)
          .addComment(
            CommentModel(
              id: '',
              itemId: _school!.id,
              itemType: 'school',
              userId: user.uid,
              userDisplayName:
                  userData?.displayName ?? user.displayName ?? 'Użytkownik',
              text: text,
              timestamp: DateTime.now(),
            ),
          );
      _commentController.clear();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się dodać opinii.')),
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
          'Dodaj opinię',
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
            hintText: 'Twoja opinia...',
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
        ? 'Opinie są dostępne po założeniu konta.'
        : 'Potwierdź adres e-mail, aby dodawać opinie.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: LoadingWidget(),
      );
    }

    if (_school == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(title: const Text('Nie znaleziono')),
        body: const Center(
          child: Text(
            'Szkoła nie istnieje',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final school = _school!;
    final authUser = ref.watch(authStateProvider).value;
    final canComment = authUser != null && authUser.emailVerified;
    final isAdmin = ref.watch(adminAccessProvider).value?.isAdmin ?? false;
    final commentsAsync = ref.watch(schoolCommentsProvider(school.id));

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.bgCard,
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
                tooltip: _isSaved ? 'Usuń z zapisanych' : 'Zapisz szkołę',
                onPressed: _isSaving ? null : _toggleSave,
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? AppTheme.primary : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.bgCard,
                child: Center(
                  child: school.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: school.logoUrl!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => const Icon(
                            Icons.school_rounded,
                            color: AppTheme.textSecondary,
                            size: 64,
                          ),
                        )
                      : const Icon(
                          Icons.school_rounded,
                          color: AppTheme.textSecondary,
                          size: 64,
                        ),
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
                  Text(
                    school.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < school.rating.floor()
                              ? Icons.star
                              : (i < school.rating
                                    ? Icons.star_half
                                    : Icons.star_outline),
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${school.rating.toStringAsFixed(1)} (${school.reviewCount} opinii)',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    icon: Icons.location_on_outlined,
                    text: school.address,
                  ),
                  if (school.phone != null)
                    _infoRow(
                      icon: Icons.phone_outlined,
                      text: school.phone!,
                      onTap: () => _callPhone(school.phone),
                      color: AppTheme.routeBlue,
                    ),
                  if (school.website != null)
                    _infoRow(
                      icon: Icons.language_outlined,
                      text: school.website!,
                      onTap: () => _launchUrl(school.website),
                      color: AppTheme.routeBlue,
                    ),
                  _infoRow(
                    icon: Icons.payments_outlined,
                    text: 'Cena: ${school.priceRangeText}',
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Opis szkoły',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    school.description.isNotEmpty
                        ? school.description
                        : 'Brak opisu.',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (school.website != null) {
                          _launchUrl(school.website);
                        } else if (school.phone != null) {
                          _callPhone(school.phone);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Zapisz się na kurs →'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  commentsAsync.when(
                    data: (comments) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Opinie kursantów (${comments.length})',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                                'Brak opinii. Bądź pierwszy!',
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
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
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

  Widget _infoRow({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    Color color = AppTheme.textSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: onTap != null ? color : AppTheme.textSecondary,
                  fontSize: 14,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
