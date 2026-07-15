import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivio/models/comment_model.dart';
import 'package:drivio/models/report_model.dart';
import 'package:drivio/models/school_model.dart';
import 'package:drivio/models/trap_model.dart';
import 'package:drivio/models/user_model.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── TRAPS ───────────────────────────────────────────────────────────────

  Stream<List<TrapModel>> getTraps(String city) {
    return _db
        .collection('traps')
        .where('city', isEqualTo: city)
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
    final ref = await _db.collection('traps').add(trap.toMap());
    return ref.id;
  }

  Future<void> updateTrap(String id, Map<String, dynamic> data) async {
    await _db.collection('traps').doc(id).update(data);
  }

  // ─── SCHOOLS ─────────────────────────────────────────────────────────────

  Stream<List<SchoolModel>> getSchools(String city) {
    return _db
        .collection('schools')
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
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addComment(CommentModel comment) async {
    await _db.collection('comments').add(comment.toMap());
  }

  // ─── REPORTS ─────────────────────────────────────────────────────────────

  Future<void> reportContent(ReportModel report) async {
    await _db.collection('reports').add(report.toMap());
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
    final trapRef = _db.collection('traps').doc(trapId);
    await _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final saved = List<String>.from(
        user.data()?['savedTraps'] as List? ?? const [],
      );
      if (saved.contains(trapId)) return;
      transaction.update(userRef, {
        'savedTraps': FieldValue.arrayUnion([trapId]),
      });
      transaction.update(trapRef, {'savesCount': FieldValue.increment(1)});
    });
  }

  Future<void> unsaveTrap(String uid, String trapId) async {
    final userRef = _db.collection('users').doc(uid);
    final trapRef = _db.collection('traps').doc(trapId);
    await _db.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final saved = List<String>.from(
        user.data()?['savedTraps'] as List? ?? const [],
      );
      if (!saved.contains(trapId)) return;
      final trap = await transaction.get(trapRef);
      final savesCount = (trap.data()?['savesCount'] as num?)?.toInt() ?? 0;
      transaction.update(userRef, {
        'savedTraps': FieldValue.arrayRemove([trapId]),
      });
      transaction.update(trapRef, {
        'savesCount': savesCount > 0 ? savesCount - 1 : 0,
      });
    });
  }

  Future<void> saveSchool(String uid, String schoolId) async {
    await _db.collection('users').doc(uid).update({
      'savedSchools': FieldValue.arrayUnion([schoolId]),
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

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<int> getTrapViewsToday(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 0;
    final data = doc.data()!;
    final views = Map<String, dynamic>.from(
      data['dailyTrapViews'] as Map? ?? {},
    );
    return (views[_todayKey] as num?)?.toInt() ?? 0;
  }

  Future<bool> consumeTrapView(String uid, int dailyLimit) async {
    final userRef = _db.collection('users').doc(uid);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final views = Map<String, dynamic>.from(
        snapshot.data()?['dailyTrapViews'] as Map? ?? const {},
      );
      final used = (views[_todayKey] as num?)?.toInt() ?? 0;
      if (used >= dailyLimit) return false;

      views[_todayKey] = used + 1;
      transaction.set(userRef, {
        'dailyTrapViews': views,
      }, SetOptions(merge: true));
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
