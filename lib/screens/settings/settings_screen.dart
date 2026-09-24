import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import 'package:drivio/utils/auth_error_message.dart';
import 'package:drivio/widgets/common/edit_name_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final mode = ref.watch(themeModeProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SettingsHero(
            displayName: user?.displayName ?? 'Kierowco',
            email: user?.email ?? 'Dostosuj aplikację do siebie',
            isPremium: isPremium,
          ),
          const SizedBox(height: 24),
          const _Label('WYGLĄD'),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _IconBox(
                        icon: Icons.palette_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motyw aplikacji',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Wybierz wygląd wygodny dla Twoich oczu',
                              style: GoogleFonts.poppins(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
            clipBehavior: Clip.antiAlias,
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
                      const Divider(height: 1, indent: 62),
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edytuj nazwę profilu'),
                        onTap: () => _editName(context, ref, user.displayName),
                      ),
                      if (user.email.isNotEmpty) ...[
                        const Divider(height: 1, indent: 62),
                        ListTile(
                          leading: const Icon(Icons.lock_reset),
                          title: const Text('Wyślij link do zmiany hasła'),
                          onTap: () => _resetPassword(context, ref, user.email),
                        ),
                      ],
                      const Divider(height: 1, indent: 62),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Wyloguj się'),
                        onTap: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const Divider(height: 1, indent: 62),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.primary,
                        ),
                        title: Text(
                          _deletingAccount ? 'Usuwanie konta…' : 'Usuń konto',
                          style: const TextStyle(color: AppTheme.primary),
                        ),
                        trailing: _deletingAccount
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        onTap: _deletingAccount
                            ? null
                            : () => _deleteAccount(context, ref),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          const _Label('PREMIUM'),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
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
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Regulamin'),
                  onTap: () => context.push('/terms'),
                ),
                const Divider(height: 1, indent: 62),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Polityka prywatności'),
                  onTap: () => context.push('/privacy'),
                ),
                const Divider(height: 1, indent: 62),
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
    final value = await showEditNameDialog(context, initialValue: current);
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
    if (_deletingAccount) return;
    final onIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final hasAppleLogin =
        onIos &&
        (ref
                .read(authServiceProvider)
                .currentUser
                ?.providerData
                .any((provider) => provider.providerId == 'apple.com') ??
            false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Usunąć konto?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konto, komentarze, zgłoszenia i zapisane miejsca zostaną '
              'trwale usunięte.',
            ),
            if (hasAppleLogin) ...[
              const SizedBox(height: 12),
              const Text(
                'Przed usunięciem potwierdzisz tożsamość przez Apple.',
              ),
            ],
            if (onIos) ...[
              const SizedBox(height: 12),
              const Text(
                'Jeśli masz aktywną subskrypcję, usunięcie konta jej nie anuluje. '
                'Anuluj ją osobno w ustawieniach Apple.',
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://apps.apple.com/account/subscriptions'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Zarządzaj subskrypcją'),
              ),
            ],
          ],
        ),
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
    setState(() => _deletingAccount = true);
    try {
      await ref
          .read(authServiceProvider)
          .deleteAccount(askPassword: () => _askPassword(context));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto zostało usunięte.')),
        );
        context.go('/login');
      }
    } catch (error) {
      if (isAuthCancellation(error)) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_accountDeletionErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Future<String?> _askPassword(BuildContext context) async {
    if (!context.mounted) return null;
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Potwierdź hasło'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(labelText: 'Hasło'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Usuń konto'),
          ),
        ],
      ),
    );
    // Not disposed here: the dialog's exit animation still reads it.
    return password;
  }

  String _accountDeletionErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Nieprawidłowe hasło.';
        case 'requires-recent-login':
          return 'Zaloguj się ponownie, a następnie usuń konto.';
        case 'apple-authorization-code-unavailable':
          return 'Apple nie potwierdziło usunięcia konta. Spróbuj ponownie.';
        case 'app-check-unavailable':
          return 'Nie udało się potwierdzić urządzenia. Spróbuj ponownie.';
        case 'network-request-failed':
          return 'Brak połączenia z internetem.';
      }
    }
    if (error is FirebaseFunctionsException &&
        (error.code == 'unauthenticated' ||
            error.code == 'failed-precondition')) {
      return 'Potwierdź ponownie logowanie i spróbuj usunąć konto.';
    }
    if (error is FirebaseException && error.plugin == 'firebase_app_check') {
      return 'Nie udało się potwierdzić urządzenia przez App Check.';
    }
    return 'Nie udało się usunąć konta. Spróbuj ponownie lub napisz na '
        '${AppConfig.contactEmail}.';
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

class _SettingsHero extends StatelessWidget {
  final String displayName;
  final String email;
  final bool isPremium;

  const _SettingsHero({
    required this.displayName,
    required this.email,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withAlpha(36),
            colors.surface,
            colors.secondary.withAlpha(18),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withAlpha(120)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(55),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Twoje Drivio',
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  displayName.isEmpty ? 'Kierowco' : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.premiumGold.withAlpha(100)),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.poppins(
                  color: AppTheme.premiumGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
