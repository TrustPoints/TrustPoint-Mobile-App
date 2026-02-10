import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

/// Wallet Balance Response Model
class WalletBalance {
  final int points;
  final int rupiahEquivalent;
  final String conversionRate;

  WalletBalance({
    required this.points,
    required this.rupiahEquivalent,
    this.conversionRate = '1 pts = Rp100',
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      points: (json['points'] as num?)?.toInt() ?? 0,
      rupiahEquivalent: (json['rupiah_equivalent'] as num?)?.toInt() ?? 0,
      conversionRate: json['conversion_rate'] as String? ?? '1 pts = Rp100',
    );
  }
}

/// Wallet Transaction Result Model
class WalletTransactionResult {
  final bool success;
  final String? message;
  final String? error;
  final int? newBalance;
  final int? amount;
  final int? rupiahEquivalent;

  WalletTransactionResult({
    required this.success,
    this.message,
    this.error,
    this.newBalance,
    this.amount,
    this.rupiahEquivalent,
  });

  factory WalletTransactionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return WalletTransactionResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      error: json['error'] as String?,
      newBalance: (data?['new_balance'] as num?)?.toInt(),
      amount:
          (data?['added'] ?? data?['redeemed'] ?? data?['transferred'] as num?)
              ?.toInt(),
      rupiahEquivalent: (data?['rupiah_equivalent'] as num?)?.toInt(),
    );
  }
}

/// Wallet Service for managing user points
class WalletService {
  final ApiService _apiService;
  final AuthService _authService;

  WalletService(this._apiService, this._authService);

  /// Get current wallet balance
  Future<WalletBalance?> getBalance() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${_apiService.baseUrl}/wallet/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return WalletBalance.fromJson(json['data']);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Earn points (after completing delivery, etc.)
  Future<WalletTransactionResult> earnPoints({
    required int points,
    String? reason,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return WalletTransactionResult(
          success: false,
          error: 'Not authenticated',
        );
      }

      final body = {'points': points, if (reason != null) 'reason': reason};

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/wallet/earn'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);
      return WalletTransactionResult.fromJson(json);
    } catch (e) {
      return WalletTransactionResult(success: false, error: e.toString());
    }
  }

  /// Redeem/spend points
  Future<WalletTransactionResult> redeemPoints({
    required int points,
    String? reason,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return WalletTransactionResult(
          success: false,
          error: 'Not authenticated',
        );
      }

      final body = {'points': points, if (reason != null) 'reason': reason};

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/wallet/redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);
      return WalletTransactionResult.fromJson(json);
    } catch (e) {
      return WalletTransactionResult(success: false, error: e.toString());
    }
  }

  /// Transfer points to another user
  Future<WalletTransactionResult> transferPoints({
    required String recipientEmail,
    required int points,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return WalletTransactionResult(
          success: false,
          error: 'Not authenticated',
        );
      }

      final body = {'recipient_email': recipientEmail, 'points': points};

      final response = await http.post(
        Uri.parse('${_apiService.baseUrl}/wallet/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);
      return WalletTransactionResult.fromJson(json);
    } catch (e) {
      return WalletTransactionResult(success: false, error: e.toString());
    }
  }

  /// Convert points to Rupiah value
  static int pointsToRupiah(int points) => points * 100;

  /// Convert Rupiah to points value
  static int rupiahToPoints(int rupiah) => rupiah ~/ 100;
}
