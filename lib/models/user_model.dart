import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final bool isPremium;
  final DateTime? premiumUntil;
  final List<String> savedTraps;
  final List<String> savedSchools;
  final List<String> blockedUsers;
  final Map<String, int> dailyTrapViews;
  final String? photoUrl;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.isPremium = false,
    this.premiumUntil,
    this.savedTraps = const [],
    this.savedSchools = const [],
    this.blockedUsers = const [],
    this.dailyTrapViews = const {},
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      isPremium: map['isPremium'] as bool? ?? false,
      premiumUntil: map['premiumUntil'] != null
          ? (map['premiumUntil'] as Timestamp).toDate()
          : null,
      savedTraps: List<String>.from(map['savedTraps'] as List? ?? []),
      savedSchools: List<String>.from(map['savedSchools'] as List? ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] as List? ?? []),
      dailyTrapViews: Map<String, int>.from(
        (map['dailyTrapViews'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toInt()),
        ),
      ),
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isPremium': isPremium,
      'premiumUntil': premiumUntil != null
          ? Timestamp.fromDate(premiumUntil!)
          : null,
      'savedTraps': savedTraps,
      'savedSchools': savedSchools,
      'blockedUsers': blockedUsers,
      'dailyTrapViews': dailyTrapViews,
      'photoUrl': photoUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isPremium,
    DateTime? premiumUntil,
    List<String>? savedTraps,
    List<String>? savedSchools,
    List<String>? blockedUsers,
    Map<String, int>? dailyTrapViews,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      savedTraps: savedTraps ?? this.savedTraps,
      savedSchools: savedSchools ?? this.savedSchools,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      dailyTrapViews: dailyTrapViews ?? this.dailyTrapViews,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  bool isTrapSavedById(String trapId) => savedTraps.contains(trapId);
  bool isSchoolSavedById(String schoolId) => savedSchools.contains(schoolId);
  bool isUserBlocked(String uid) => blockedUsers.contains(uid);
}
