/// App-wide string constants
class AppStrings {
  // App Info
  static const String appName = 'TrustPoints';
  static const String appTagline = 'P2P Delivery Platform';
  static const String appVersion = '1.0.0';

  // Auth Screens
  static const String welcomeBack = 'Welcome Back 👋';
  static const String signInSubtitle =
      'Sign in to continue your delivery journey';
  static const String createAccount = 'Create Account ✨';
  static const String signUpSubtitle =
      'Join TrustPoints and start delivering today';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String forgotPassword = 'Forgot Password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';

  // Form Hints
  static const String hintEmail = 'Email address';
  static const String hintPassword = 'Password';
  static const String hintConfirmPassword = 'Confirm Password';
  static const String hintFullName = 'Full Name';
  static const String hintPhone = 'Phone Number';

  // Button Texts
  static const String buttonLogin = 'Sign In';
  static const String buttonRegister = 'Create Account';
  static const String buttonContinue = 'Continue';
  static const String buttonCancel = 'Cancel';
  static const String buttonOk = 'OK';
  static const String buttonUnderstand = 'Mengerti';
  static const String buttonSave = 'Save';
  static const String buttonSubmit = 'Submit';

  // Terms
  static const String termsPrefix = 'I agree to the ';
  static const String termsOfService = 'Terms of Service';
  static const String and = ' and ';
  static const String privacyPolicy = 'Privacy Policy';

  // Navigation
  static const String navHome = 'Home';
  static const String navOrders = 'Orders';
  static const String navWallet = 'Wallet';
  static const String navProfile = 'Profile';

  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String or = 'or';
  static const String pts = 'pts';
  static const String points = 'Points';
}

/// App-wide numeric constants
class AppNumbers {
  // Points
  static const int pointsPerRupiah = 100;
  static const int minPasswordLength = 8;
  static const int minNameLength = 3;
  static const int maxNameLength = 100;

  // Animation Durations (in milliseconds)
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int animationPageTransition = 800;
  static const int animationSplash = 1200;

  // Layout
  static const double defaultPadding = 20.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 14.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 24.0;

  // Sizes
  static const double buttonHeight = 56.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeNormal = 22.0;
  static const double iconSizeLarge = 28.0;
}

/// App-wide duration constants
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 800);
  static const Duration splash = Duration(milliseconds: 1200);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration apiTimeout = Duration(seconds: 30);
}

/// Error messages
class ErrorMessages {
  // Network
  static const String networkError = 'Tidak dapat terhubung ke server';
  static const String timeoutError = 'Waktu koneksi habis';
  static const String serverError = 'Terjadi kesalahan pada server';
  static const String unknownError = 'Terjadi kesalahan tidak diketahui';

  // Auth
  static const String loginFailed = 'Login gagal';
  static const String registerFailed = 'Pendaftaran gagal';
  static const String invalidCredentials = 'Email atau password salah';
  static const String emailAlreadyExists = 'Email sudah terdaftar';
  static const String accountNotFound = 'Akun tidak ditemukan';
  static const String sessionExpired =
      'Sesi telah berakhir, silakan login kembali';

  // Validation
  static const String requiredField = 'Field ini wajib diisi';
  static const String invalidEmail = 'Format email tidak valid';
  static const String weakPassword = 'Password terlalu lemah';
  static const String passwordMismatch = 'Password tidak sama';
}

/// Success messages
class SuccessMessages {
  static const String loginSuccess = 'Login berhasil';
  static const String registerSuccess = 'Pendaftaran berhasil';
  static const String profileUpdated = 'Profil berhasil diperbarui';
  static const String passwordChanged = 'Password berhasil diubah';
  static const String orderCreated = 'Pesanan berhasil dibuat';
}
