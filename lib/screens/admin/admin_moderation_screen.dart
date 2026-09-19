import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/theme/app_theme.dart';

final moderationReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getModerationReports();
});

final adminCommentsProvider = StreamProvider<List<CommentModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getRecentComments();
});

final adminTrapsProvider = StreamProvider<List<TrapModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllTraps();
});

final adminSchoolsProvider = StreamProvider<List<SchoolModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllSchools();
});

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel administratora'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Zgłoszenia'),
              Tab(text: 'Komentarze'),
              Tab(text: 'Pułapki'),
              Tab(text: 'Szkoły'),
            ],
          ),
        ),
        body: access.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _AccessDenied(),
          data: (status) {
            if (!status.isAdmin) return const _AccessDenied();
            return const TabBarView(
              children: [
                _ReportsTab(),
                _CommentsTab(),
                _TrapsTab(),
                _SchoolsTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(moderationReportsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _LoadError(),
          data: (reports) => reports.isEmpty
              ? const _EmptyState('Brak oczekujących zgłoszeń')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) =>
                      _ReportCard(report: reports[index]),
                ),
        );
  }
}

class _CommentsTab extends ConsumerWidget {
  const _CommentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(adminCommentsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _LoadError(),
          data: (comments) => comments.isEmpty
              ? const _EmptyState('Brak komentarzy')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (_, index) {
                    final comment = comments[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          comment.userDisplayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${comment.text}\n${comment.itemType} • ${comment.itemId}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          tooltip: 'Usuń komentarz',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.primary,
                          ),
                          onPressed: () => _confirmDelete(
                            context,
                            'Usunąć komentarz?',
                            () => ref
                                .read(firestoreServiceProvider)
                                .deleteComment(comment.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
  }
}

class _TrapsTab extends ConsumerWidget {
  const _TrapsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AddButton(
          label: 'Dodaj pułapkę',
          onPressed: () => context.push('/trap/add'),
        ),
        Expanded(
          child: ref
              .watch(adminTrapsProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _LoadError(),
                data: (traps) => traps.isEmpty
                    ? const _EmptyState('Brak pułapek')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: traps.length,
                        itemBuilder: (_, index) {
                          final trap = traps[index];
                          return Card(
                            child: ListTile(
                              onTap: () => context.push('/trap/${trap.id}'),
                              title: Text(
                                trap.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                trap.city,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Usuń pułapkę',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.primary,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  'Usunąć pułapkę i jej komentarze?',
                                  () => ref
                                      .read(firestoreServiceProvider)
                                      .deleteTrap(trap.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
        ),
      ],
    );
  }
}

class _SchoolsTab extends ConsumerWidget {
  const _SchoolsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AddButton(
          label: 'Dodaj szkołę',
          onPressed: () => context.push('/admin/school/add'),
        ),
        Expanded(
          child: ref
              .watch(adminSchoolsProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _LoadError(),
                data: (schools) => schools.isEmpty
                    ? const _EmptyState('Brak szkół')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: schools.length,
                        itemBuilder: (_, index) {
                          final school = schools[index];
                          return Card(
                            child: ListTile(
                              onTap: () => context.push(
                                '/admin/school/${school.id}/edit',
                              ),
                              title: Text(
                                school.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${school.city} • ${school.address}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: IconButton(
                                tooltip: 'Usuń szkołę',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.primary,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  'Usunąć szkołę i jej opinie?',
                                  () => ref
                                      .read(firestoreServiceProvider)
                                      .deleteSchool(school.id),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Nie udało się pobrać danych. Sprawdź reguły Firestore i uprawnienia administratora.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  String message,
  Future<void> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(message),
      content: const Text('Tej operacji nie można cofnąć.'),
      actions: [
        TextButton(
          onPressed: () => dialogContext.pop(false),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () => dialogContext.pop(true),
          child: const Text('Usuń'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się usunąć elementu.')),
      );
    }
  }
}

class _ReportCard extends ConsumerWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${report.itemType} • ${report.itemId}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.reason,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _resolve(context, ref, false),
                  child: const Text('Odrzuć zgłoszenie'),
                ),
                ElevatedButton(
                  onPressed: () => _resolve(context, ref, true),
                  child: const Text('Usuń treść'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    bool deleteContent,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(deleteContent ? 'Usunąć treść?' : 'Odrzucić zgłoszenie?'),
        content: Text(
          deleteContent
              ? 'Treść i zgłoszenie zostaną trwale usunięte.'
              : 'Zgłoszenie zostanie zamknięte bez usuwania treści.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(firestoreServiceProvider)
          .resolveReport(report, deleteContent: deleteContent);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zamknąć zgłoszenia.')),
      );
    }
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Brak dostępu. Konto musi mieć aktywne uprawnienie administratora.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
