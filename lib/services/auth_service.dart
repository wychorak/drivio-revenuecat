import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        message: 'Potwierdź adres email przed logowaniem.',
      );
    }
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
    if (user != null) {
      await _ensureUserDocument(user);
    }
    return user;
  }

  Future<void> _ensureUserDocument(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      final fallbackName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Kierowca';
      await _createUserDocument(user, fallbackName);
      return;
    }
    await ref.set({
      'email': user.email ?? '',
      if (user.displayName?.trim().isNotEmpty == true)
        'displayName': user.displayName!.trim(),
    }, SetOptions(merge: true));
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
      await _createUserDocument(user, displayName);
      await user.sendEmailVerification();
      await _auth.signOut();
    }
    return user;
  }

  Future<void> _createUserDocument(User user, String displayName) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': displayName,
      'isPremium': false,
      'premiumUntil': null,
      'savedTraps': [],
      'savedSchools': [],
      'blockedUsers': [],
      'dailyTrapViews': {},
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
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

    await _deleteOwnedDocuments('comments', 'userId', user.uid);
    await _deleteOwnedDocuments('reports', 'reporterId', user.uid);
    await _deleteOwnedDocuments('traps', 'createdBy', user.uid);
    await _deleteUploadedTrapPhotos(user.uid);
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  Future<void> _deleteOwnedDocuments(
    String collection,
    String ownerField,
    String uid,
  ) async {
    while (true) {
      final snapshot = await _firestore
          .collection(collection)
          .where(ownerField, isEqualTo: uid)
          .limit(400)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 400) return;
    }
  }

  Future<void> _deleteUploadedTrapPhotos(String uid) async {
    final folder = FirebaseStorage.instance.ref().child('traps/$uid');
    try {
      final files = await folder.listAll();
      await Future.wait(files.items.map((item) => item.delete()));
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
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
