import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/constants/strings.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';
import 'package:grillsngravy/core/widgets/custom_textfield.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(); // Changed from _emailController
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Use the new method that accepts both email and phone
        await FirebaseService.loginWithEmailOrPhone(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _skipLogin() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordDialog(identifierController: _identifierController),
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
                const SizedBox(height: 40),
                // Header
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back! Please login to your account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.greyDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Email/Phone Field - UPDATED
                CustomTextField(
                  controller: _identifierController,
                  labelText: 'Email or Phone Number', // Updated label
                  hintText: 'Enter your email or phone number',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.text, // Changed to text to accept both
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or phone number';
                    }

                    // Check if it's email or phone
                    final isEmail = value.contains('@');
                    final isPhone = RegExp(r'^[0-9+\-\s()]{10,}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''));

                    if (!isEmail && !isPhone) {
                      return 'Please enter a valid email or phone number';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: AppStrings.password,
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
                const SizedBox(height: 8),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Login Button
                CustomButton(
                  text: AppStrings.login,
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                // Skip Button
                CustomButton(
                  text: AppStrings.skip,
                  onPressed: _skipLogin,
                  variant: ButtonVariant.outlined,
                ),
                const SizedBox(height: 30),
                // Register Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dontHaveAccount,
                        style: GoogleFonts.poppins(
                          color: AppColors.greyDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          AppStrings.register,
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Updated Forgot Password Dialog
class ForgotPasswordDialog extends StatefulWidget {
  final TextEditingController identifierController;

  const ForgotPasswordDialog({super.key, required this.identifierController});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _identifierController.text = widget.identifierController.text;
  }

  Future<void> _resetPassword() async {
    final identifier = _identifierController.text.trim();

    // Check if identifier is email or phone
    final isEmail = identifier.contains('@');

    if (!isEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset is only available for email accounts'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_identifierController.text.isEmpty || !_identifierController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address for password reset'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.resetPassword(_identifierController.text.trim());

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reset Password',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter your email address to reset your password. Phone number accounts need to contact support.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _identifierController,
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }
}