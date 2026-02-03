/// API Configuration for TrustPoints Backend
class ApiConfig {
  // Change this to your actual backend URL
  // For Android emulator use: 10.0.2.2
  // For iOS simulator use: localhost or 127.0.0.1
  // For physical device use: your computer's IP address

  // static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000'; // iOS simulator
  static const String baseUrl = 'http://192.168.100.6:5000'; // Physical device

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
