import 'package:cloud_firestore/cloud_firestore.dart';

class TrapModel {
  final String id;
  final double lat;
  final double lng;
  final String title;
  final String description;
  final int difficulty;
  final String? photoUrl;
  final String? videoUrl;
  final String ruleDescription;
  final String createdBy;
  final String city;
  final DateTime createdAt;
  final int savesCount;

  const TrapModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    required this.description,
    required this.difficulty,
    this.photoUrl,
    this.videoUrl,
    required this.ruleDescription,
    required this.createdBy,
    required this.city,
    required this.createdAt,
    this.savesCount = 0,
  });

  factory TrapModel.fromMap(Map<String, dynamic> map, String id) {
    return TrapModel(
      id: id,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 1,
      photoUrl: map['photoUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      ruleDescription: map['ruleDescription'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      city: map['city'] as String? ?? 'Szczecin',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      savesCount: (map['savesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'ruleDescription': ruleDescription,
      'createdBy': createdBy,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'savesCount': savesCount,
    };
  }

  TrapModel copyWith({
    String? id,
    double? lat,
    double? lng,
    String? title,
    String? description,
    int? difficulty,
    String? photoUrl,
    String? videoUrl,
    String? ruleDescription,
    String? createdBy,
    String? city,
    DateTime? createdAt,
    int? savesCount,
  }) {
    return TrapModel(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      photoUrl: photoUrl ?? this.photoUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      createdBy: createdBy ?? this.createdBy,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      savesCount: savesCount ?? this.savesCount,
    );
  }
}
