import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/user_model.dart';
import 'package:drivio/config/app_config.dart';
import 'package:drivio/services/storage_service.dart';

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

  Stream<List<TrapModel>> getAllTraps() {
    return _db
        .collection('traps')
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => TrapModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteTrap(String id) => _deleteContent('trap', id);

  // ─── SCHOOLS ─────────────────────────────────────────────────────────────

  Stream<List<SchoolModel>> getSchools(String city) {
    return _db
        .collection('schools')
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
              .where((school) => school.city == city)
              .toList(),
        );
  }

  Stream<List<SchoolModel>> getAllSchools() {
    return _db.collection('schools').limit(200).snapshots().map((snap) {
      final schools = snap.docs
          .map((doc) => SchoolModel.fromMap(doc.data(), doc.id))
          .toList();
      schools.sort((a, b) => a.name.compareTo(b.name));
      return schools;
    });
  }

  Future<SchoolModel?> getSchoolById(String id) async {
    final doc = await _db.collection('schools').doc(id).get();
    if (!doc.exists) return null;
    return SchoolModel.fromMap(doc.data()!, doc.id);
  }

  Future<String> addSchool(SchoolModel school) async {
    final ref = await _db.collection('schools').add(school.toMap());
    return ref.id;
  }

  Future<void> updateSchool(String id, SchoolModel school) async {
    await _db.collection('schools').doc(id).update(school.toMap());
  }

  Future<void> deleteSchool(String id) => _deleteContent('school', id);

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

  Stream<List<CommentModel>> getRecentComments() {
    return _db
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteComment(String id) async {
    await _db.collection('comments').doc(id).delete();
  }

  // ─── REPORTS ─────────────────────────────────────────────────────────────

  Future<void> reportContent(ReportModel report) async {
    final data = report.toMap()..['timestamp'] = FieldValue.serverTimestamp();
    final id = '${report.reporterId}_${report.itemType}_${report.itemId}';
    final ref = _db.collection('reports').doc(id);
    await _db.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) {
        throw StateError('Ta treść została już zgłoszona.');
      }
      transaction.set(ref, data);
    });
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
    if (deleteContent) {
      await _deleteContent(report.itemType, report.itemId);
    }
    await _db.collection('reports').doc(report.id).delete();
  }

  Future<void> _deleteContent(String itemType, String itemId) async {
    final collection = switch (itemType) {
      'trap' => 'traps',
      'school' => 'schools',
      'comment' => 'comments',
      _ => throw ArgumentError.value(itemType, 'itemType'),
    };

    final batch = _db.batch();
    final trap = itemType == 'trap'
        ? await _db.collection('traps').doc(itemId).get()
        : null;
    batch.delete(_db.collection(collection).doc(itemId));

    if (itemType != 'comment') {
      final comments = await _db
          .collection('comments')
          .where('itemId', isEqualTo: itemId)
          .where('itemType', isEqualTo: itemType)
          .limit(400)
          .get();
      for (final comment in comments.docs) {
        batch.delete(comment.reference);
      }
    }

    final reports = await _db
        .collection('reports')
        .where('itemId', isEqualTo: itemId)
        .where('itemType', isEqualTo: itemType)
        .limit(80)
        .get();
    for (final report in reports.docs) {
      batch.delete(report.reference);
    }
    await batch.commit();
    if (trap != null && trap.exists) {
      final media = StorageService();
      for (final url in [trap.data()?['photoUrl'], trap.data()?['videoUrl']]) {
        if (url is String && url.isNotEmpty) {
          await media.deleteUploadedMedia(url);
        }
      }
    }
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
