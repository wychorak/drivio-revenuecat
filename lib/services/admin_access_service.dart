import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/providers/auth_provider.dart';

class AdminAccess {
  final bool emailListed;
  final bool hasAdminClaim;

  const AdminAccess({required this.emailListed, required this.hasAdminClaim});

  bool get isAdmin => emailListed && hasAdminClaim;
}

final adminAccessProvider = FutureProvider<AdminAccess>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const AdminAccess(emailListed: false, hasAdminClaim: false);
  }
  return AdminAccessService.check(user);
});

class AdminAccessService {
  const AdminAccessService._();

  static Future<AdminAccess> check(User user) async {
    final email = user.email?.trim().toLowerCase() ?? '';
    final emailListed =
        email.isNotEmpty && AppConfig.adminEmails.contains(email);
    if (!emailListed || !user.emailVerified) {
      return AdminAccess(emailListed: emailListed, hasAdminClaim: false);
    }

    final token = await user.getIdTokenResult(true);
    return AdminAccess(
      emailListed: true,
      hasAdminClaim: token.claims?['admin'] == true,
    );
  }
}
