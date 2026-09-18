import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/providers/auth_provider.dart';

class AdminAccess {
  final bool emailListed;
  final bool emailVerified;
  final bool hasAdminClaim;

  const AdminAccess({
    required this.emailListed,
    required this.emailVerified,
    required this.hasAdminClaim,
  });

  bool get isAdmin => emailListed && emailVerified;
}

final adminAccessProvider = FutureProvider<AdminAccess>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const AdminAccess(
      emailListed: false,
      emailVerified: false,
      hasAdminClaim: false,
    );
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
      return AdminAccess(
        emailListed: emailListed,
        emailVerified: user.emailVerified,
        hasAdminClaim: false,
      );
    }

    var token = await user.getIdTokenResult(true);
    if (token.claims?['admin'] != true) {
      try {
        await FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        ).httpsCallable('refreshAdminClaim').call<void>();
        token = await user.getIdTokenResult(true);
      } on FirebaseFunctionsException {
        // The verified release email remains usable under Firestore rules.
      }
    }
    return AdminAccess(
      emailListed: true,
      emailVerified: true,
      hasAdminClaim: token.claims?['admin'] == true,
    );
  }
}
