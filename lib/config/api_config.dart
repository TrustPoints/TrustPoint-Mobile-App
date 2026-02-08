/// API Configuration for TrustPoints Backend
class ApiConfig {
  static const String baseUrl = 'https://trustpoints.irc-enter.tech';

  // API Endpoints
  static const String register = '/api/register';
  static const String login = '/api/login';
  static const String profile = '/api/profile';
  static const String profileEdit = '/api/profile/edit';
  static const String changePassword = '/api/profile/change-password';
  static const String health = '/health';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
