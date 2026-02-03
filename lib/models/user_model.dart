import 'dart:io';

/// User Model for TrustPoints
class User {
  final String id;
  final String fullName;
  final String email;
  final String? profilePicture;
  final double trustScore;
  final String languagePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.profilePicture,
    required this.trustScore,
    required this.languagePreference,
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
      languagePreference: json['language_preference'] as String? ?? 'en',
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
      'language_preference': languagePreference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profilePicture,
    double? trustScore,
    String? languagePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      trustScore: trustScore ?? this.trustScore,
      languagePreference: languagePreference ?? this.languagePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, trustScore: $trustScore)';
  }
}
