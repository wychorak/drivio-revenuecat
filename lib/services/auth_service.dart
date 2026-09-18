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
    bool isGuest = false,
    bool legalConsentsAccepted = false,
  }) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': displayName,
      'isGuest': isGuest,
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

  Future<User?> continueAsGuest() async {
    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user != null) {
      await _createUserDocument(user, 'Gość', isGuest: true);
    }
    return user;
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

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        DateTime.now().difference(lastSignIn) > const Duration(minutes: 4)) {
      throw FirebaseAuthException(
        code: 'requires-recent-login',
        message: 'Zaloguj się ponownie przed usunięciem konta.',
      );
    }

    await _functions.httpsCallable('deleteAccount').call<void>();
    await _auth.signOut();
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
