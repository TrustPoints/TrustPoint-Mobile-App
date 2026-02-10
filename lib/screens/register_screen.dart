import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart' hide GradientButton;
import '../providers/auth_provider.dart';
import '../widgets/notification_modal.dart';
import '../widgets/common_widgets.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate name
    if (name.isEmpty) {
      _showErrorModal(
        title: 'Nama Kosong',
        message: 'Silakan masukkan nama lengkap Anda.',
      );
      return;
    }

    if (name.length < 3) {
      _showErrorModal(
        title: 'Nama Terlalu Pendek',
        message: 'Nama harus minimal 3 karakter.',
      );
      return;
    }

    // Validate email
    if (email.isEmpty) {
      _showErrorModal(
        title: 'Email Kosong',
        message: 'Silakan masukkan alamat email Anda.',
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorModal(
        title: 'Email Tidak Valid',
        message:
            'Format email tidak valid. Pastikan email Anda benar, contoh: nama@email.com',
      );
      return;
    }

    // Validate password
    if (password.isEmpty) {
      _showErrorModal(
        title: 'Password Kosong',
        message: 'Silakan masukkan password Anda.',
      );
      return;
    }

    // Check password strength
    final passwordError = PasswordValidator.getErrorMessage(password);
    if (passwordError != null) {
      _showErrorModal(title: 'Password Lemah', message: passwordError);
      return;
    }

    // Validate confirm password
    if (confirmPassword.isEmpty) {
      _showErrorModal(
        title: 'Konfirmasi Password',
        message: 'Silakan masukkan konfirmasi password Anda.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showErrorModal(
        title: 'Password Tidak Sama',
        message:
            'Password dan konfirmasi password tidak cocok. Pastikan keduanya sama.',
      );
      return;
    }

    // Check terms
    if (!_acceptTerms) {
      _showWarningModal(
        title: 'Syarat & Ketentuan',
        message:
            'Anda harus menyetujui Syarat & Ketentuan untuk melanjutkan pendaftaran.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      fullName: name,
      email: email,
      password: password,
    );

    if (mounted) {
      if (success) {
        _showSuccessModal(
          title: 'Pendaftaran Berhasil! 🎉',
          message:
              'Akun Anda telah berhasil dibuat. Silakan login untuk melanjutkan.',
          onClose: () => Navigator.pop(context),
        );
      } else {
        final errorMsg = authProvider.errorMessage ?? 'Pendaftaran gagal';

        if (errorMsg.toLowerCase().contains('already') ||
            errorMsg.toLowerCase().contains('exist') ||
            errorMsg.toLowerCase().contains('terdaftar')) {
          _showErrorModal(
            title: 'Email Sudah Terdaftar',
            message:
                'Email ini sudah digunakan. Silakan gunakan email lain atau login dengan akun yang sudah ada.',
          );
        } else {
          _showErrorModal(title: 'Pendaftaran Gagal', message: errorMsg);
        }
      }
    }
  }

  void _showErrorModal({required String title, required String message}) {
    NotificationModal.showError(
      context: context,
      title: title,
      message: message,
      buttonText: 'Mengerti',
    );
  }

  void _showSuccessModal({
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    NotificationModal.showSuccess(
      context: context,
      title: title,
      message: message,
      buttonText: 'Lanjutkan',
      onButtonPressed: onClose,
    );
  }

  void _showWarningModal({required String title, required String message}) {
    NotificationModal.showWarning(
      context: context,
      title: title,
      message: message,
      buttonText: 'Mengerti',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0xFFEDEDED)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Header
                        const Text(
                          'Create Account ✨',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join TrustPoints and start delivering today',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Name Field
                        AppTextField(
                          controller: _nameController,
                          hint: 'Full Name',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Email Field
                        AppTextField(
                          controller: _emailController,
                          hint: 'Email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Password Field
                        AppPasswordField(
                          controller: _passwordController,
                          hint: 'Password',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Confirm Password Field
                        AppPasswordField(
                          controller: _confirmPasswordController,
                          hint: 'Confirm Password',
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // Terms Checkbox
                        GestureDetector(
                          onTap: () =>
                              setState(() => _acceptTerms = !_acceptTerms),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: _acceptTerms
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: _acceptTerms ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: _acceptTerms
                                      ? null
                                      : Border.all(
                                          color: AppColors.textTertiary
                                              .withOpacity(0.5),
                                          width: 2,
                                        ),
                                ),
                                child: _acceptTerms
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.primaryStart,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.primaryStart,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Register Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return GradientButton(
                              text: 'Create Account',
                              isLoading: authProvider.isLoading,
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _handleRegister,
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppColors.primaryStart,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
