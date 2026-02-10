/// Email validation utilities
class EmailValidator {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Check if email format is valid
  static bool isValid(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  /// Get validation error message or null if valid
  static String? validate(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!isValid(email)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  /// Detailed validation with specific error
  static ValidationResult validateDetailed(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Email Kosong',
        errorMessage: 'Silakan masukkan alamat email Anda untuk melanjutkan.',
      );
    }
    if (!isValid(email)) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Email Tidak Valid',
        errorMessage:
            'Format email tidak valid. Pastikan email Anda benar, contoh: nama@email.com',
      );
    }
    return ValidationResult.valid();
  }
}

/// Password validation utilities
class PasswordValidator {
  static const int minLength = 8;

  /// Validate password and return list of errors
  static List<String> validate(String password) {
    List<String> errors = [];

    if (password.length < minLength) {
      errors.add('Minimal $minLength karakter');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Minimal 1 huruf besar (A-Z)');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Minimal 1 huruf kecil (a-z)');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Minimal 1 angka (0-9)');
    }

    return errors;
  }

  /// Check if password meets all requirements
  static bool isValid(String password) {
    return validate(password).isEmpty;
  }

  /// Get formatted error message or null if valid
  static String? getErrorMessage(String password) {
    final errors = validate(password);
    if (errors.isEmpty) return null;
    return 'Password harus memenuhi kriteria:\n• ${errors.join('\n• ')}';
  }

  /// Detailed validation with specific error
  static ValidationResult validateDetailed(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Password Kosong',
        errorMessage: 'Silakan masukkan password Anda.',
      );
    }

    final errorMessage = getErrorMessage(password);
    if (errorMessage != null) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Password Lemah',
        errorMessage: errorMessage,
      );
    }

    return ValidationResult.valid();
  }

  /// Validate password confirmation
  static ValidationResult validateConfirmation(
    String password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Konfirmasi Password',
        errorMessage: 'Silakan masukkan konfirmasi password Anda.',
      );
    }
    if (password != confirmPassword) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Password Tidak Sama',
        errorMessage:
            'Password dan konfirmasi password tidak cocok. Pastikan keduanya sama.',
      );
    }
    return ValidationResult.valid();
  }
}

/// Name validation utilities
class NameValidator {
  static const int minLength = 3;
  static const int maxLength = 100;

  /// Get validation error message or null if valid
  static String? validate(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (name.trim().length < minLength) {
      return 'Nama minimal $minLength karakter';
    }
    if (name.trim().length > maxLength) {
      return 'Nama maksimal $maxLength karakter';
    }
    return null;
  }

  /// Detailed validation with specific error
  static ValidationResult validateDetailed(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Nama Kosong',
        errorMessage: 'Silakan masukkan nama lengkap Anda.',
      );
    }
    if (name.trim().length < minLength) {
      return ValidationResult(
        isValid: false,
        errorTitle: 'Nama Terlalu Pendek',
        errorMessage: 'Nama harus minimal $minLength karakter.',
      );
    }
    return ValidationResult.valid();
  }
}

/// Phone number validation utilities
class PhoneValidator {
  static final RegExp _phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{7,11}$');

  /// Check if phone format is valid (Indonesian)
  static bool isValid(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phoneRegex.hasMatch(cleaned);
  }

  /// Get validation error message or null if valid
  static String? validate(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    if (!isValid(phone)) {
      return 'Format nomor telepon tidak valid';
    }
    return null;
  }

  /// Normalize phone number to +62 format
  static String normalize(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('62')) {
      cleaned = '+$cleaned';
    } else if (!cleaned.startsWith('+62')) {
      cleaned = '+62$cleaned';
    }
    return cleaned;
  }
}

/// Generic validation result
class ValidationResult {
  final bool isValid;
  final String? errorTitle;
  final String? errorMessage;

  ValidationResult({required this.isValid, this.errorTitle, this.errorMessage});

  factory ValidationResult.valid() => ValidationResult(isValid: true);

  factory ValidationResult.invalid({
    required String title,
    required String message,
  }) => ValidationResult(
    isValid: false,
    errorTitle: title,
    errorMessage: message,
  );
}
