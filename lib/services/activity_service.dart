import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Activity Model
class Activity {
  final String activityId;
  final String userId;
  final String type;
  final String title;
  final String? description;
  final int? points;
  final String? orderId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  Activity({
    required this.activityId,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    this.points,
    this.orderId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activity_id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      points: json['points'] as int?,
      orderId: json['order_id'],
      metadata: json['metadata'] ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = difference.inDays ~/ 30;
      return '$months bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  /// Get points display string (with + or -)
  String? get pointsDisplay {
    if (points == null) return null;
    return points! > 0 ? '+$points' : '$points';
  }
}

/// Activity Type Constants
class ActivityType {
  static const String orderCreated = 'ORDER_CREATED';
  static const String orderClaimed = 'ORDER_CLAIMED';
  static const String orderPickedUp = 'ORDER_PICKED_UP';
  static const String orderDelivered = 'ORDER_DELIVERED';
  static const String orderCancelled = 'ORDER_CANCELLED';
  static const String pointsEarned = 'POINTS_EARNED';
  static const String pointsSpent = 'POINTS_SPENT';
  static const String pointsTransferred = 'POINTS_TRANSFERRED';
  static const String pointsReceived = 'POINTS_RECEIVED';
  static const String accountCreated = 'ACCOUNT_CREATED';
  static const String profileUpdated = 'PROFILE_UPDATED';
}

/// Activity Result Model
class ActivityResult {
  final bool success;
  final List<Activity> activities;
  final String? error;
  final ActivityPagination? pagination;

  ActivityResult({
    required this.success,
    this.activities = const [],
    this.error,
    this.pagination,
  });

  factory ActivityResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<Activity> activityList = [];
    ActivityPagination? pagination;

    if (data != null && data['activities'] != null) {
      activityList = (data['activities'] as List)
          .map((a) => Activity.fromJson(a))
          .toList();
    }

    if (data != null && data['pagination'] != null) {
      pagination = ActivityPagination.fromJson(data['pagination']);
    }

    return ActivityResult(
      success: json['success'] ?? false,
      activities: activityList,
      pagination: pagination,
    );
  }
}

/// Pagination Model
class ActivityPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  ActivityPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ActivityPagination.fromJson(Map<String, dynamic> json) {
    return ActivityPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
    );
  }
}

/// Activity Service
class ActivityService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Get recent activities for dashboard
  Future<ActivityResult> getRecentActivities({
    required String token,
    int limit = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/activity/recent?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('GetRecentActivities Response: ${response.statusCode}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ActivityResult.fromJson(json);
      }

      return ActivityResult(
        success: false,
        error: json['message'] ?? 'Failed to get activities',
      );
    } catch (e) {
      debugPrint('GetRecentActivities Error: $e');
      return ActivityResult(success: false, error: e.toString());
    }
  }

  /// Get all activities with pagination
  Future<ActivityResult> getAllActivities({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/activity/?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('GetAllActivities Response: ${response.statusCode}');

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ActivityResult.fromJson(json);
      }

      return ActivityResult(
        success: false,
        error: json['message'] ?? 'Failed to get activities',
      );
    } catch (e) {
      debugPrint('GetAllActivities Error: $e');
      return ActivityResult(success: false, error: e.toString());
    }
  }
}
