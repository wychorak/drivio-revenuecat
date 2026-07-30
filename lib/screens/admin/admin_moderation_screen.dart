import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/services/admin_access_service.dart';
import 'package:drivio/theme/app_theme.dart';

final moderationReportsProvider = StreamProvider<List<ReportModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getModerationReports();
});

class AdminModerationScreen extends ConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Moderacja'),
        backgroundColor: AppTheme.bgDark,
      ),
      body: access.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _AccessDenied(),
        data: (status) {
          if (!status.isAdmin) return const _AccessDenied();
          return ref
              .watch(moderationReportsProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nie udało się pobrać zgłoszeń. Sprawdź reguły Firestore i claim administratora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                data: (reports) {
                  if (reports.isEmpty) {
                    return const Center(
                      child: Text(
                        'Brak oczekujących zgłoszeń',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ReportCard(report: reports[index]),
                  );
                },
              );
        },
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final ReportModel report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppTheme.bgCard,
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
                      color: Colors.white,
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
                color: AppTheme.textSecondary,
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Brak dostępu. Konto musi znajdować się w ADMIN_EMAILS, mieć zweryfikowany email i custom claim admin=true.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
