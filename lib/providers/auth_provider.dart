import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state enum
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Auth Provider - manages authentication state
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  String? _cachedToken;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Get cached token (synchronous) - use after ensuring token is loaded
  String? get token => _cachedToken;

  /// Get current token (async) - fetches from secure storage
  Future<String?> getToken() async {
    _cachedToken = await _authService.getToken();
    return _cachedToken;
  }

  /// Initialize - check if user is already logged in
  Future<void> initialize() async {
    _setLoading(true);

    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      // Cache the token
      _cachedToken = await _authService.getToken();

      // Try to fetch user profile
      final result = await _authService.getProfile();
      if (result.success && result.user != null) {
        _user = result.user;
        _state = AuthState.authenticated;
      } else {
        // Token might be expired, logout
        await _authService.logout();
        _cachedToken = null;
        _state = AuthState.unauthenticated;
      }
    } else {
      _state = AuthState.unauthenticated;
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    final result = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    if (result.success) {
      // Set authenticated state first
      _state = AuthState.authenticated;

      // Cache the token
      _cachedToken = await _authService.getToken();

      // Try to fetch user profile after registration
      final profileResult = await _authService.getProfile();
      if (profileResult.success && profileResult.user != null) {
        _user = profileResult.user;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setError(result.message);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    if (result.success) {
      // Set authenticated state first
      _state = AuthState.authenticated;

      // Cache the token
      _cachedToken = await _authService.getToken();

      // Try to fetch user profile after login
      final profileResult = await _authService.getProfile();
      if (profileResult.success && profileResult.user != null) {
        _user = profileResult.user;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setError(result.message);
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? profilePicture,
    String? languagePreference,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.updateProfile(
      fullName: fullName,
      profilePicture: profilePicture,
      languagePreference: languagePreference,
    );

    if (result.success && result.user != null) {
      _user = result.user;
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _setError(result.message ?? 'Failed to update profile');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    final result = await _authService.getProfile();
    if (result.success && result.user != null) {
      _user = result.user;
      notifyListeners();
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _user = null;
    _cachedToken = null;
    _state = AuthState.unauthenticated;
    _setLoading(false);
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _errorMessage = null;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _state = AuthState.error;
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }
}
