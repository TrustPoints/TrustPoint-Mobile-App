import 'dart:io';

/// Default Address Model
class DefaultAddress {
  final String address;
  final double latitude;
  final double longitude;

  DefaultAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory DefaultAddress.fromJson(Map<String, dynamic> json) {
    return DefaultAddress(
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'address': address, 'latitude': latitude, 'longitude': longitude};
  }

  DefaultAddress copyWith({
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return DefaultAddress(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

/// User Model for TrustPoints
class User {
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final double trustScore;
  final int points; // 1 pts = Rp100
  final String languagePreference;
  final DefaultAddress? defaultAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    required this.trustScore,
    this.points = 0,
    required this.languagePreference,
    this.defaultAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse date from various formats (RFC 1123, ISO 8601, etc.)
  static DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }

    try {
      // Try ISO 8601 format first
      return DateTime.parse(dateString);
    } catch (_) {
      try {
        // Try HTTP date format: "Tue, 03 Feb 2026 16:18:27 GMT"
        return HttpDate.parse(dateString);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as String? ?? json['_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      languagePreference: json['language_preference'] as String? ?? 'en',
      defaultAddress: json['default_address'] != null
          ? DefaultAddress.fromJson(
              json['default_address'] as Map<String, dynamic>,
            )
          : null,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'full_name': fullName,
      'email': email,
      'profile_picture': profilePicture,
      'trust_score': trustScore,
      'points': points,
      'language_preference': languagePreference,
      'default_address': defaultAddress?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get points value in Rupiah (1 pts = Rp100)
  int get pointsInRupiah => points * 100;

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profilePicture,
    double? trustScore,
    int? points,
    String? languagePreference,
    DefaultAddress? defaultAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      trustScore: trustScore ?? this.trustScore,
      points: points ?? this.points,
      languagePreference: languagePreference ?? this.languagePreference,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, trustScore: $trustScore, points: $points)';
  }
}
