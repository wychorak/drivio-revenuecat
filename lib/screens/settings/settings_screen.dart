import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/providers/settings_provider.dart';
import 'package:drivio/providers/user_provider.dart';
import 'package:drivio/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final mode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Label('WYGLĄD'),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motyw aplikacji',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(
                        GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.onPrimary
                            : colors.onSurface,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.primary
                            : colors.surface,
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_android),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Jasny'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Ciemny'),
                      ),
                    ],
                    selected: {mode},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) => ref
                        .read(themeModeProvider.notifier)
                        .setTheme(values.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _Label('KONTO'),
          Card(
            margin: EdgeInsets.zero,
            child: user == null
                ? ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Zaloguj się lub utwórz konto'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/login'),
                  )
                : Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            user.displayName.isEmpty
                                ? 'U'
                                : user.displayName[0].toUpperCase(),
                          ),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email),
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edytuj nazwę profilu'),
                        onTap: () => _editName(context, ref, user.displayName),
                      ),
                      if (user.email.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.lock_reset),
                          title: const Text('Wyślij link do zmiany hasła'),
                          onTap: () => _resetPassword(context, ref, user.email),
                        ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Wyloguj się'),
                        onTap: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.primary,
                        ),
                        title: const Text(
                          'Usuń konto',
                          style: TextStyle(color: AppTheme.primary),
                        ),
                        onTap: () => _deleteAccount(context, ref),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          const _Label('PREMIUM'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.star_rounded,
                    color: AppTheme.premiumGold,
                  ),
                  title: Text(isPremium ? 'Premium aktywne' : 'Drivio Premium'),
                  subtitle: const Text('Subskrypcja i przywracanie zakupów'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/premium'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _Label('POMOC I PRAWO'),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Regulamin'),
                  onTap: () => context.push('/terms'),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Polityka prywatności'),
                  onTap: () => context.push('/privacy'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Kontakt'),
                  subtitle: Text(AppConfig.contactEmail),
                  onTap: () =>
                      launchUrl(Uri.parse('mailto:${AppConfig.contactEmail}')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Drivio v1.0.0',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edytuj profil'),
        content: TextField(
          controller: controller,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Nazwa użytkownika'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.length < 2 || !context.mounted) return;
    await ref.read(authServiceProvider).updateDisplayName(value);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil zaktualizowany.')));
    }
  }

  Future<void> _resetPassword(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) async {
    await ref.read(authServiceProvider).sendPasswordReset(email);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Link wysłany na $email')));
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Usunąć konto?'),
        content: const Text('Konto i jego dane zostaną trwale usunięte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaloguj się ponownie i spróbuj jeszcze raz.'),
          ),
        );
      }
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 7),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        color: AppTheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.1,
      ),
    ),
  );
}
