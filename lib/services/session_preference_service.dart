import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferenceService {
  static const _rememberAccountKey = 'auth.rememberAccount';
  static const _rememberedEmailKey = 'auth.rememberedEmail';

  const SessionPreferenceService._();

  static Future<bool> rememberAccount() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_rememberAccountKey) ?? true;
  }

  static Future<String?> rememberedEmail() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_rememberedEmailKey);
  }

  static Future<void> save({required bool remember, String? email}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberAccountKey, remember);

    final normalizedEmail = email?.trim();
    if (remember && normalizedEmail != null && normalizedEmail.isNotEmpty) {
      await preferences.setString(_rememberedEmailKey, normalizedEmail);
    } else {
      await preferences.remove(_rememberedEmailKey);
    }
  }

  static Future<void> enforceOnStartup() async {
    if (await rememberAccount()) return;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? await auth.authStateChanges().first;
    if (user != null) await auth.signOut();
  }
}
