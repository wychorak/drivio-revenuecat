import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio/providers/auth_provider.dart';
import 'package:drivio/theme/app_theme.dart';

const _showPreviewAdminLogin = bool.fromEnvironment(
  'DRIVIO_PREVIEW_ADMIN_LOGIN',
  defaultValue: false,
);

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
      await ref
          .read(authServiceProvider)
          .signInWithEmail(_emailController.text, _passwordController.text);
      if (mounted) context.go('/map');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapFirebaseError(e.toString())),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithApple();
      if (user != null && mounted) {
        context.go('/map');
      }
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('cancelled') || message.contains('canceled')) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_mapFirebaseError(error.toString())),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _devLogin() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(devLoginProvider.notifier).state = true;
    final citySelected = prefs.getString('selectedCity');
    if (!mounted) return;
    context.go(citySelected == null ? '/city-select' : '/map');
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wpisz adres email, aby zresetować hasło'),
        ),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link do resetu hasła został wysłany')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_mapFirebaseError(e.toString()))),
        );
      }
    }
  }

  String _mapFirebaseError(String error) {
    if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Nieprawidłowy email lub hasło';
    } else if (error.contains('too-many-requests')) {
      return 'Za dużo prób. Spróbuj za chwilę.';
    } else if (error.contains('network-request-failed')) {
      return 'Brak połączenia z internetem';
    }
    return 'Wystąpił błąd. Spróbuj ponownie.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE30613), Color(0xFFB00010)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'drivio',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
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
                  'Zaloguj się, aby kontynuować',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Podaj adres email';
                    }
                    if (!value.contains('@')) return 'Nieprawidłowy email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Podaj hasło';
                    if (value.length < 6) {
                      return 'Hasło musi mieć min. 6 znaków';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _sendPasswordReset,
                    child: const Text('Zapomniałeś hasła?'),
                  ),
                ),
                const SizedBox(height: 16),
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
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'lub',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithApple,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.apple, size: 24),
                      label: Text(
                        'Zaloguj się przez Apple',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
                      onTap: () => context.push('/register'),
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
                const SizedBox(height: 32),
                if (kDebugMode || _showPreviewAdminLogin) ...[
                  const Divider(color: Colors.orange, thickness: 0.5),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _devLogin,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                      ),
                      child: const Text('Wejdz jako admin'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
