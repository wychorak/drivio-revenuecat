import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String itemId;
  final String itemType; // "trap" or "school"
  final String userId;
  final String userDisplayName;
  final String text;
  final DateTime timestamp;
  final bool reported;

  const CommentModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.userId,
    required this.userDisplayName,
    required this.text,
    required this.timestamp,
    this.reported = false,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemType: map['itemType'] as String? ?? 'trap',
      userId: map['userId'] as String? ?? '',
      userDisplayName: map['userDisplayName'] as String? ?? 'Użytkownik',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      reported: map['reported'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'reported': reported,
    };
  }
}
