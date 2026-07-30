import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/user_model.dart';
import 'package:drivio/config/app_config.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TRAPS ───────────────────────────────────────────────────────────────

  Stream<List<TrapModel>> getTraps(String city) {
    return _db
        .collection('traps')
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TrapModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<TrapModel?> getTrapById(String id) async {
    final doc = await _db.collection('traps').doc(id).get();
    if (!doc.exists) return null;
    return TrapModel.fromMap(doc.data()!, doc.id);
  }

  Future<String> addTrap(TrapModel trap) async {
    final data = trap.toMap()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['savesCount'] = 0;
    final ref = await _db.collection('traps').add(data);
    return ref.id;
  }

  Future<void> updateTrap(String id, Map<String, dynamic> data) async {
    await _db.collection('traps').doc(id).update(data);
  }

  // ─── SCHOOLS ─────────────────────────────────────────────────────────────

  Stream<List<SchoolModel>> getSchools(String city) {
    return _db
        .collection('schools')
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<SchoolModel?> getSchoolById(String id) async {
    final doc = await _db.collection('schools').doc(id).get();
    if (!doc.exists) return null;
    return SchoolModel.fromMap(doc.data()!, doc.id);
  }

  // ─── COMMENTS ────────────────────────────────────────────────────────────

  Stream<List<CommentModel>> getComments(String itemId, String itemType) {
    return _db
        .collection('comments')
        .where('itemId', isEqualTo: itemId)
        .where('itemType', isEqualTo: itemType)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addComment(CommentModel comment) async {
    final data = comment.toMap()..['timestamp'] = FieldValue.serverTimestamp();
    await _db.collection('comments').add(data);
  }

  // ─── REPORTS ─────────────────────────────────────────────────────────────

  Future<void> reportContent(ReportModel report) async {
    final data = report.toMap()..['timestamp'] = FieldValue.serverTimestamp();
    await _db.collection('reports').add(data);
  }

  Stream<List<ReportModel>> getModerationReports() {
    return _db
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> resolveReport(
    ReportModel report, {
    required bool deleteContent,
  }) async {
    final batch = _db.batch();
    if (deleteContent) {
      final collection = switch (report.itemType) {
        'trap' => 'traps',
        'school' => 'schools',
        'comment' => 'comments',
        _ => null,
      };
      if (collection != null) {
        batch.delete(_db.collection(collection).doc(report.itemId));
      }
    }
    batch.delete(_db.collection('reports').doc(report.id));
    await batch.commit();
  }

  // ─── USERS ───────────────────────────────────────────────────────────────

  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> saveTrap(String uid, String trapId) async {
    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final saved = List<String>.from(
        user.data()?['savedTraps'] as List? ?? const [],
      );
      if (saved.contains(trapId)) return;
      if (saved.length >= AppConfig.maxSavedTraps) {
        throw StateError('Osiągnięto limit zapisanych pułapek.');
      }
      transaction.update(userRef, {
        'savedTraps': FieldValue.arrayUnion([trapId]),
      });
    });
  }

  Future<void> unsaveTrap(String uid, String trapId) async {
    await _db.collection('users').doc(uid).update({
      'savedTraps': FieldValue.arrayRemove([trapId]),
    });
  }

  Future<void> saveSchool(String uid, String schoolId) async {
    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final saved = List<String>.from(
        user.data()?['savedSchools'] as List? ?? const [],
      );
      if (saved.contains(schoolId)) return;
      if (saved.length >= AppConfig.maxSavedSchools) {
        throw StateError('Osiągnięto limit zapisanych szkół.');
      }
      transaction.update(userRef, {
        'savedSchools': FieldValue.arrayUnion([schoolId]),
      });
    });
  }

  Future<void> unsaveSchool(String uid, String schoolId) async {
    await _db.collection('users').doc(uid).update({
      'savedSchools': FieldValue.arrayRemove([schoolId]),
    });
  }

  Future<void> blockUser(String uid, String blockedUid) async {
    if (uid == blockedUid || blockedUid.isEmpty) return;
    await _db.collection('users').doc(uid).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUid]),
    });
  }

  Future<void> unblockUser(String uid, String blockedUid) async {
    await _db.collection('users').doc(uid).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUid]),
    });
  }

  // ─── RANKINGS ────────────────────────────────────────────────────────────

  Future<List<TrapModel>> getRankingTraps(String city) async {
    final snap = await _db
        .collection('traps')
        .where('city', isEqualTo: city)
        .orderBy('difficulty', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((doc) => TrapModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<SchoolModel>> getRankingSchools(String city) async {
    final snap = await _db
        .collection('schools')
        .orderBy('rating', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─── DAILY TRAP VIEWS ────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _usageRef(String uid) =>
      _db.collection('users').doc(uid).collection('usage').doc('trapViews');

  Future<int> getTrapViewsToday(String uid) async {
    final snapshot = await _usageRef(uid).get();
    if (!snapshot.exists) return 0;
    final data = snapshot.data()!;
    final startedAt = (data['periodStartedAt'] as Timestamp?)?.toDate();
    if (startedAt == null ||
        DateTime.now().difference(startedAt) >= const Duration(hours: 24)) {
      return 0;
    }
    return (data['views'] as num?)?.toInt() ?? 0;
  }

  Future<bool> consumeTrapView(String uid, int dailyLimit) async {
    final usageRef = _usageRef(uid);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(usageRef);
      if (!snapshot.exists) {
        transaction.set(usageRef, {
          'views': 1,
          'periodStartedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final data = snapshot.data()!;
      final startedAt = (data['periodStartedAt'] as Timestamp?)?.toDate();
      final expired =
          startedAt == null ||
          DateTime.now().difference(startedAt) >= const Duration(hours: 24);
      if (expired) {
        transaction.set(usageRef, {
          'views': 1,
          'periodStartedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final used = (data['views'] as num?)?.toInt() ?? 0;
      if (used >= dailyLimit) return false;
      transaction.update(usageRef, {
        'views': used + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
  // ─── SAVED TRAPS DETAILS ────────────────────────────────────────────────

  Future<List<TrapModel>> getSavedTraps(List<String> trapIds) async {
    if (trapIds.isEmpty) return [];
    final results = <TrapModel>[];
    // Firestore whereIn supports up to 10 items per query
    for (var i = 0; i < trapIds.length; i += 10) {
      final chunk = trapIds.sublist(
        i,
        i + 10 > trapIds.length ? trapIds.length : i + 10,
      );
      final snap = await _db
          .collection('traps')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((doc) => TrapModel.fromMap(doc.data(), doc.id)),
      );
    }
    return results;
  }

  Future<List<SchoolModel>> getSavedSchools(List<String> schoolIds) async {
    if (schoolIds.isEmpty) return [];
    final results = <SchoolModel>[];
    for (var i = 0; i < schoolIds.length; i += 10) {
      final chunk = schoolIds.sublist(
        i,
        i + 10 > schoolIds.length ? schoolIds.length : i + 10,
      );
      final snap = await _db
          .collection('schools')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs.map((doc) => SchoolModel.fromMap(doc.data(), doc.id)),
      );
    }
    return results;
  }
}
