import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String itemId;
  final String itemType; // "trap", "school", "comment"
  final String reason;
  final String reporterId;
  final DateTime timestamp;

  const ReportModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.reason,
    required this.reporterId,
    required this.timestamp,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemType: map['itemType'] as String? ?? 'trap',
      reason: map['reason'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'reason': reason,
      'reporterId': reporterId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
