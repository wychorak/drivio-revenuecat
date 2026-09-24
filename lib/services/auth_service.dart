import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _iosGoogleClientId =
      '154834085926-sl7gdikb90m9p8gic56ru6btqpskdrk2.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateStream => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'too-many-requests') rethrow;
      }
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Potwierdź adres e-mail przed logowaniem.',
      );
    }
    return user;
  }

  Future<User?> signInWithGoogle() async {
    final UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      credential = await _auth.signInWithPopup(provider);
    } else {
      await _initializeGoogleSignIn();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-oauth-response',
          message: 'Google did not return an ID token.',
        );
      }
      final googleCredential = GoogleAuthProvider.credential(idToken: idToken);
      credential = await _auth.signInWithCredential(googleCredential);
    }

    final user = credential.user;
    if (user != null) await _ensureUserDocument(user);
    return user;
  }

  Future<User?> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);

    final user = credential.user;
    if (user != null) await _ensureUserDocument(user);
    return user;
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    final useIosClientId =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    await GoogleSignIn.instance.initialize(
      clientId: useIosClientId ? _iosGoogleClientId : null,
    );
    _googleInitialized = true;
  }

  Future<void> _ensureUserDocument(User user) async {
    final reference = _firestore.collection('users').doc(user.uid);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      final fallbackName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Kierowca';
      await _createUserDocument(user, fallbackName);
      return;
    }

    final updates = <String, Object>{};
    final email = user.email?.trim();
    final displayName = user.displayName?.trim();
    if (email != null && email.isNotEmpty) updates['email'] = email;
    if (displayName != null && displayName.isNotEmpty) {
      updates['displayName'] = displayName;
    }
    if (updates.isNotEmpty) {
      await reference.set(updates, SetOptions(merge: true));
    }
  }

  Future<User?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await _createUserDocument(user, displayName, legalConsentsAccepted: true);
      await user.sendEmailVerification();
      await _auth.signOut();
    }
    return user;
  }

  Future<void> _createUserDocument(
    User user,
    String displayName, {
    bool legalConsentsAccepted = false,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': displayName,
      'isGuest': false,
      'isPremium': false,
      'premiumUntil': null,
      'savedTraps': [],
      'savedSchools': [],
      'blockedUsers': [],
      'dailyTrapViews': {},
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      if (legalConsentsAccepted) ...{
        'acceptedTermsAt': FieldValue.serverTimestamp(),
        'acceptedPrivacyAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<void> recordLegalConsents(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'acceptedTermsAt': FieldValue.serverTimestamp(),
      'acceptedPrivacyAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized && !kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase logout must still succeed if the provider is unavailable.
      }
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Deletes the signed-in account after confirming the user's identity.
  ///
  /// [askPassword] is used for e-mail accounts whose session is too old for
  /// the backend's recent-login check; returning null cancels the deletion.
  Future<void> deleteAccount({
    required Future<String?> Function() askPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final providers = user.providerData.map((info) => info.providerId).toSet();
    if (providers.contains('apple.com') && !kIsWeb) {
      // Apple requires apps to revoke Sign in with Apple tokens when an
      // account is deleted, which needs a fresh authorization code.
      final credential = await user.reauthenticateWithProvider(
        AppleAuthProvider(),
      );
      final code = credential.additionalUserInfo?.authorizationCode;
      if (code != null && code.isNotEmpty) {
        await _auth.revokeTokenWithAuthorizationCode(code);
      }
    } else if (!_hasRecentLogin(user)) {
      if (providers.contains('google.com')) {
        await _reauthenticateWithGoogle(user);
      } else if (providers.contains('password') && user.email != null) {
        final password = await askPassword();
        if (password == null || password.isEmpty) {
          throw FirebaseAuthException(code: 'cancelled');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      } else {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'Zaloguj się ponownie przed usunięciem konta.',
        );
      }
    }

    // The callable checks auth_time, so send a token minted after re-auth.
    await user.getIdToken(true);
    await _functions.httpsCallable('deleteAccount').call<void>();
    await signOut();
  }

  bool _hasRecentLogin(User user) {
    final lastSignIn = user.metadata.lastSignInTime;
    return lastSignIn != null &&
        DateTime.now().difference(lastSignIn) < const Duration(minutes: 4);
  }

  Future<void> _reauthenticateWithGoogle(User user) async {
    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
      return;
    }
    await _initializeGoogleSignIn();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-oauth-response',
        message: 'Google did not return an ID token.',
      );
    }
    await user.reauthenticateWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });
    }
  }
}
