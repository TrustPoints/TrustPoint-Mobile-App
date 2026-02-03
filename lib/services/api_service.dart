import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    required this.statusCode,
  });
}

/// Base API Service for HTTP requests
class ApiService {
  final String baseUrl = ApiConfig.baseUrl;

  /// GET request
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _buildHeaders(token))
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// POST request
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// PUT request
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse(
        success: false,
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Build headers
  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Handle HTTP response
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

      return ApiResponse(
        success: isSuccess,
        data: body,
        message: body['message'] as String?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }
}
