import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';
import 'package:grillsngravy/core/widgets/custom_textfield.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isEmailProvided = false;
  bool _isEmailVerified = false;
  bool _isCheckingVerification = false;
  bool _isSendingVerification = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onEmailChanged() {
    setState(() {
      _isEmailProvided = _emailController.text.trim().isNotEmpty;
      // Reset verification status if email changes
      if (!_isEmailProvided) {
        _isEmailVerified = false;
      }
    });
  }

  void _onPhoneChanged() {
    setState(() {});
  }

  bool get _canCreateAccount {
    final hasFullName = _fullNameController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().length >= 10;
    final hasPassword = _passwordController.text.length >= 6;
    final hasConfirmPassword = _confirmPasswordController.text.isNotEmpty;
    final passwordsMatch = _passwordController.text == _confirmPasswordController.text;

    // Basic requirements for all cases
    if (!hasFullName || !hasPhone || !hasPassword || !hasConfirmPassword || !passwordsMatch) {
      return false;
    }

    // If email is provided, it must be verified after registration
    if (_isEmailProvided && _isRegistered) {
      return _isEmailVerified;
    }

    // For initial registration or phone-only, allow creation
    return true;
  }

  Future<void> _sendVerificationEmail() async {
    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isSendingVerification = true);

    try {
      await FirebaseService.resendVerificationEmail();
      _showSuccess('Verification email sent to ${_emailController.text}');
    } catch (e) {
      _showError('Failed to send verification email: ${e.toString()}');
    } finally {
      setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isCheckingVerification = true);

    try {
      final isVerified = await FirebaseService.checkEmailVerification();
      setState(() => _isEmailVerified = isVerified);

      if (isVerified) {
        _showSuccess('Email verified successfully!');
      } else {
        _showError('Email not verified yet. Please check your inbox.');
      }
    } catch (e) {
      _showError('Failed to check verification status: ${e.toString()}');
    } finally {
      setState(() => _isCheckingVerification = false);
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);

      try {
        await FirebaseService.registerWithEmailOrPhone(
          fullName: _fullNameController.text.trim(),
          email: _isEmailProvided ? _emailController.text.trim() : null,
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Mark as registered
        setState(() => _isRegistered = true);

        // If email was provided, show verification message
        if (_isEmailProvided) {
          _showSuccess('Registration successful! Please check your email for verification link.');
          // Don't navigate yet - wait for email verification
        } else {
          // No email provided, navigate directly to home
          Navigator.pushReplacementNamed(context, '/home');
          _showSuccess('Registration successful!');
        }
      } catch (e) {
        _showError('Registration failed: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _completeRegistration() {
    if (_isEmailVerified) {
      Navigator.pushReplacementNamed(context, '/home');
      _showSuccess('Registration completed successfully!');
    } else {
      _showError('Please verify your email first');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 20),

                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.onPrimary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join Grills & Gravy family',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.greyDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Full Name Field (Required)
                CustomTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name *',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field (Optional with Verification)
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email (Optional)',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // Email Verification Section (Only show if email provided AND registered but not verified)
                if (_isEmailProvided && _isRegistered && !_isEmailVerified) ...[
                  const SizedBox(height: 12),

                  // Verification Status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verification email sent to ${_emailController.text}',
                                style: GoogleFonts.poppins(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSendingVerification ? null : _sendVerificationEmail,
                                icon: _isSendingVerification
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.send, size: 18),
                                label: const Text('Resend Email'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isCheckingVerification ? null : _checkEmailVerification,
                                icon: _isCheckingVerification
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.refresh, size: 18),
                                label: const Text('Check Status'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                if (_isEmailVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Email verified successfully!',
                          style: GoogleFonts.poppins(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Phone Field (Required)
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number *',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password *',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password *',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixIconPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  obscureText: _obscureConfirmPassword,
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
                const SizedBox(height: 30),

                // Register/Complete Button
                CustomButton(
                  text: _isRegistered && _isEmailProvided && !_isEmailVerified
                      ? 'Complete Registration'
                      : 'Create Account',
                  onPressed: _canCreateAccount && !_isLoading ?
                  (_isRegistered && _isEmailProvided ? _completeRegistration : _register)
                      : null,
                  isLoading: _isLoading,
                ),

                if (!_canCreateAccount) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _isEmailProvided && _isRegistered && !_isEmailVerified
                          ? 'Please verify your email to continue'
                          : 'Please fill all required fields',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.poppins(
                          color: AppColors.greyDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}