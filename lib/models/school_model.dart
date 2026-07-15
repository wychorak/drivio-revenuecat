class SchoolModel {
  final String id;
  final String name;
  final String? logoUrl;
  final double rating;
  final int reviewCount;
  final double priceFrom;
  final double priceTo;
  final String address;
  final String description;
  final double lat;
  final double lng;
  final String? phone;
  final String? website;

  const SchoolModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    required this.priceTo,
    required this.address,
    required this.description,
    required this.lat,
    required this.lng,
    this.phone,
    this.website,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolModel(
      id: id,
      name: map['name'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      priceFrom: (map['priceFrom'] as num?)?.toDouble() ?? 0.0,
      priceTo: (map['priceTo'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 53.4289,
      lng: (map['lng'] as num?)?.toDouble() ?? 14.5530,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceFrom': priceFrom,
      'priceTo': priceTo,
      'address': address,
      'description': description,
      'lat': lat,
      'lng': lng,
      'phone': phone,
      'website': website,
    };
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? logoUrl,
    double? rating,
    int? reviewCount,
    double? priceFrom,
    double? priceTo,
    String? address,
    String? description,
    double? lat,
    double? lng,
    String? phone,
    String? website,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceFrom: priceFrom ?? this.priceFrom,
      priceTo: priceTo ?? this.priceTo,
      address: address ?? this.address,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      phone: phone ?? this.phone,
      website: website ?? this.website,
    );
  }

  String get priceRangeText =>
      '${priceFrom.toStringAsFixed(0)} – ${priceTo.toStringAsFixed(0)} zł';
}
