import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/services/session_preference_service.dart';
import 'package:drivio/theme/app_theme.dart';
import 'package:drivio/utils/auth_error_message.dart';
import 'package:drivio/widgets/auth/social_auth_buttons.dart';
import 'package:drivio/widgets/common/drivio_brand.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;
  bool _acceptedRodo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateConsents() {
    if (_acceptedTerms && _acceptedRodo) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zaakceptuj regulamin i politykę prywatności.'),
      ),
    );
    return false;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || !_validateConsents()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .registerWithEmail(
            _emailController.text,
            _passwordController.text,
            _nameController.text.trim(),
          );
      await SessionPreferenceService.save(
        remember: true,
        email: _emailController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Konto utworzone. Otwórz link w e-mailu, a następnie się zaloguj.',
            ),
          ),
        );
        context.go('/login');
      }
    } catch (error) {
      _showAuthError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    await _registerWithProvider(
      () => ref.read(authServiceProvider).signInWithGoogle(),
    );
  }

  Future<void> _registerWithApple() async {
    await _registerWithProvider(
      () => ref.read(authServiceProvider).signInWithApple(),
    );
  }

  Future<void> _registerWithProvider(
    Future<User?> Function() authenticate,
  ) async {
    if (_isLoading || !_validateConsents()) return;
    setState(() => _isLoading = true);
    try {
      final user = await authenticate();
      if (user == null) return;
      await ref.read(authServiceProvider).recordLegalConsents(user.uid);
      await SessionPreferenceService.save(remember: true, email: user.email);
      if (mounted) context.go('/map');
    } catch (error) {
      if (!isAuthCancellation(error)) {
        _showAuthError(error, providerLogin: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthError(Object error, {bool providerLogin = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authErrorMessage(error, providerLogin: providerLogin)),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRegister = _acceptedTerms && _acceptedRodo;

    return Theme(
      data: AppTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppTheme.bgDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
              ),
              onPressed: _isLoading ? null : () => context.pop(),
            ),
          ),
          body: DrivioBackdrop(
            child: SafeArea(
              top: false,
              child: AutofillGroup(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const DrivioBrandMark(size: 46, compact: true),
                            const SizedBox(height: 28),
                            Text(
                              'Utwórz konto',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Zapisuj miejsca, komentuj i ucz się skuteczniej.',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withAlpha(14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.successColor.withAlpha(60),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppTheme.successColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      'Twoje dane chroni Firebase Authentication',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextFormField(
                              controller: _nameController,
                              cursorColor: AppTheme.primary,
                              autofillHints: const [AutofillHints.name],
                              style: const TextStyle(color: Colors.white),
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nazwa użytkownika',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Podaj nazwę użytkownika';
                                }
                                if (value.trim().length > 80) {
                                  return 'Nazwa może mieć maks. 80 znaków';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              cursorColor: AppTheme.primary,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.newUsername,
                                AutofillHints.email,
                              ],
                              autocorrect: false,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Podaj adres e-mail';
                                }
                                if (!value.contains('@')) {
                                  return 'Nieprawidłowy e-mail';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              cursorColor: AppTheme.primary,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Hasło',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Podaj hasło';
                                }
                                if (value.length < 6) {
                                  return 'Hasło musi mieć min. 6 znaków';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              cursorColor: AppTheme.primary,
                              obscureText: _obscureConfirm,
                              autofillHints: const [AutofillHints.newPassword],
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Potwierdź hasło',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Hasła nie są zgodne';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            _ConsentTile(
                              value: _acceptedTerms,
                              onChanged: (value) =>
                                  setState(() => _acceptedTerms = value),
                              prefix: 'Akceptuję ',
                              linkText: 'Regulamin aplikacji Drivio',
                              onOpen: () => context.push('/terms'),
                            ),
                            const SizedBox(height: 8),
                            _ConsentTile(
                              value: _acceptedRodo,
                              onChanged: (value) =>
                                  setState(() => _acceptedRodo = value),
                              prefix: 'Akceptuję ',
                              linkText: 'Politykę prywatności',
                              onOpen: () => context.push('/privacy'),
                            ),
                            const SizedBox(height: 26),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: canRegister && !_isLoading
                                    ? _register
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  disabledBackgroundColor: AppTheme.primary
                                      .withAlpha(80),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Zarejestruj się e-mailem'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SocialAuthButtons(
                              enabled: !_isLoading,
                              onGoogle: _registerWithGoogle,
                              onApple: _registerWithApple,
                              googleLabel: 'Zarejestruj przez Google',
                              appleLabel: 'Zarejestruj przez Apple',
                            ),
                            if (!canRegister) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Przed rejestracją zaakceptuj oba dokumenty.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String prefix;
  final String linkText;
  final VoidCallback onOpen;

  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.prefix,
    required this.linkText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (next) => onChanged(next ?? false),
        activeColor: AppTheme.primary,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        title: GestureDetector(
          onTap: onOpen,
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              children: [
                TextSpan(text: prefix),
                TextSpan(
                  text: linkText,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
