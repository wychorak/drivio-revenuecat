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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberAccount = true;

  @override
  void initState() {
    super.initState();
    _restoreRememberedAccount();
  }

  Future<void> _restoreRememberedAccount() async {
    final remember = await SessionPreferenceService.rememberAccount();
    final email = remember
        ? await SessionPreferenceService.rememberedEmail()
        : null;
    if (!mounted) return;
    setState(() {
      _rememberAccount = remember;
      if (email != null) _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await ref
          .read(authServiceProvider)
          .signInWithEmail(_emailController.text, _passwordController.text);
      await SessionPreferenceService.save(
        remember: _rememberAccount,
        email: user?.email ?? _emailController.text,
      );
      if (mounted) context.go('/map');
    } catch (error) {
      _showAuthError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    await _loginWithProvider(
      () => ref.read(authServiceProvider).signInWithGoogle(),
    );
  }

  Future<void> _loginWithApple() async {
    await _loginWithProvider(
      () => ref.read(authServiceProvider).signInWithApple(),
    );
  }

  Future<void> _loginWithProvider(Future<User?> Function() authenticate) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await authenticate();
      if (user == null) return;
      await SessionPreferenceService.save(
        remember: _rememberAccount,
        email: user.email,
      );
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

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wpisz adres e-mail, aby zresetować hasło.'),
        ),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link do resetu hasła został wysłany.')),
        );
      }
    } catch (error) {
      _showAuthError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          body: DrivioBackdrop(
            child: SafeArea(
              child: AutofillGroup(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 18),
                            const DrivioBrandMark(),
                            const SizedBox(height: 30),
                            Text(
                              'Witaj z powrotem',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Wróć na swoją drogę do prawa jazdy',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FeaturePill(
                                  icon: Icons.map_outlined,
                                  label: 'Pułapki',
                                ),
                                _FeaturePill(
                                  icon: Icons.school_outlined,
                                  label: 'Szkoły',
                                ),
                                _FeaturePill(
                                  icon: Icons.fact_check_outlined,
                                  label: 'Egzamin',
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              cursorColor: AppTheme.primary,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.username,
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
                              autofillHints: const [AutofillHints.password],
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberAccount,
                                  activeColor: AppTheme.primary,
                                  onChanged: _isLoading
                                      ? null
                                      : (value) => setState(
                                          () =>
                                              _rememberAccount = value ?? true,
                                        ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => setState(
                                            () => _rememberAccount =
                                                !_rememberAccount,
                                          ),
                                    child: Text(
                                      'Zapamiętaj konto na tym urządzeniu',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _sendPasswordReset,
                                  child: const Text(
                                    'Nie pamiętasz?',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Zaloguj się'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SocialAuthButtons(
                              enabled: !_isLoading,
                              onGoogle: _loginWithGoogle,
                              onApple: _loginWithApple,
                              googleLabel: 'Zaloguj się przez Google',
                              appleLabel: 'Zaloguj się przez Apple',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Logując się, akceptujesz',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/terms'),
                                  child: const Text(
                                    'Regulamin',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                                Text(
                                  'i',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/privacy'),
                                  child: const Text(
                                    'Politykę prywatności',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Nie masz konta? ',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => context.push('/register'),
                                  child: Text(
                                    'Zarejestruj się →',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
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

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated.withAlpha(210),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryBright, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
