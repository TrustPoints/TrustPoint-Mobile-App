import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Authentication Service - handles login, register, and token management
class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  /// Register a new user
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.register,
      body: {'full_name': fullName, 'email': email, 'password': password},
    );

    if (response.success && response.data != null) {
      // Handle nested response: { data: { token, user }, message, success }
      final data = response.data!['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;
      final userId = user?['user_id'] as String?;

      if (token != null && userId != null) {
        await _saveCredentials(token, userId);
        return AuthResult(
          success: true,
          message: response.message ?? 'Registration successful',
          token: token,
          userId: userId,
        );
      }
    }

    return AuthResult(
      success: false,
      message: response.message ?? 'Registration failed',
    );
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
    );

    if (response.success && response.data != null) {
      // Handle nested response: { data: { token, user }, message, success }
      final data = response.data!['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;
      final userId = user?['user_id'] as String?;

      if (token != null && userId != null) {
        await _saveCredentials(token, userId);
        return AuthResult(
          success: true,
          message: response.message ?? 'Login successful',
          token: token,
          userId: userId,
        );
      }
    }

    return AuthResult(
      success: false,
      message: response.message ?? 'Login failed',
    );
  }

  /// Get current user profile
  Future<UserResult> getProfile() async {
    final token = await getToken();
    if (token == null) {
      return UserResult(success: false, message: 'Not authenticated');
    }

    final response = await _apiService.get(ApiConfig.profile, token: token);

    if (response.success && response.data != null) {
      // Handle nested response: { data: { user }, message, success }
      final data = response.data!['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData != null) {
        return UserResult(
          success: true,
          message: response.message,
          user: User.fromJson(userData),
        );
      }
    }

    return UserResult(
      success: false,
      message: response.message ?? 'Failed to get profile',
    );
  }

  /// Update user profile
  Future<UserResult> updateProfile({
    String? fullName,
    String? profilePicture,
    String? languagePreference,
  }) async {
    final token = await getToken();
    if (token == null) {
      return UserResult(success: false, message: 'Not authenticated');
    }

    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (profilePicture != null) body['profile_picture'] = profilePicture;
    if (languagePreference != null)
      body['language_preference'] = languagePreference;

    final response = await _apiService.put(
      ApiConfig.profileEdit,
      body: body,
      token: token,
    );

    if (response.success && response.data != null) {
      // Handle nested response: { data: { user }, message, success }
      final data = response.data!['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData != null) {
        return UserResult(
          success: true,
          message: response.message ?? 'Profile updated',
          user: User.fromJson(userData),
        );
      }
    }

    return UserResult(
      success: false,
      message: response.message ?? 'Failed to update profile',
    );
  }

  /// Change user password
  Future<ChangePasswordResult> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      return ChangePasswordResult(success: false, message: 'Not authenticated');
    }

    final response = await _apiService.post(
      ApiConfig.changePassword,
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      token: token,
    );

    return ChangePasswordResult(
      success: response.success,
      message:
          response.message ??
          (response.success
              ? 'Password berhasil diubah'
              : 'Gagal mengubah password'),
    );
  }

  /// Logout - clear stored credentials
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Save credentials to secure storage
  Future<void> _saveCredentials(String token, String userId) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    await _secureStorage.write(key: _userIdKey, value: userId);
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final String? userId;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.userId,
  });
}

/// Result class for user operations
class UserResult {
  final bool success;
  final String? message;
  final User? user;

  UserResult({required this.success, this.message, this.user});
}

/// Result class for change password operations
class ChangePasswordResult {
  final bool success;
  final String message;

  ChangePasswordResult({required this.success, required this.message});
}
