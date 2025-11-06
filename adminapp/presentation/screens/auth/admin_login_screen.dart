import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/core/constants/strings.dart';
import 'package:grillsngravy_admin/core/widgets/custom_button.dart';
import 'package:grillsngravy_admin/core/widgets/custom_textfield.dart';
import 'package:grillsngravy_admin/presentation/providers/auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Clear any previous errors when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Check if login was successful
      if (authProvider.hasError) {
        // Show error message (already handled in provider)
        return;
      }

      // Login successful - navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');

    } catch (e) {
      // This should not normally happen as errors are caught in provider
      if (!mounted) return;
      _showErrorSnackBar('An unexpected error occurred');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),

                // Back Button
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Header Section
                Center(
                  child: Column(
                    children: [
                      // Admin Badge
                      Container(
                        width: isSmallScreen ? 70 : 80,
                        height: isSmallScreen ? 70 : 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.9),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: AppColors.onPrimary,
                          size: isSmallScreen ? 35 : 40,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Text(
                        AppStrings.adminLogin,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Restaurant Management Panel',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: AppColors.greyDark,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Admin Access Only',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),

                // Error Message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: authProvider.clearError,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  labelText: AppStrings.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter admin email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: AppStrings.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
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
                SizedBox(height: isSmallScreen ? 24 : 30),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: AppStrings.login,
                      onPressed: authProvider.isLoading ? null : _login,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),

                // Security Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This area is restricted to authorized admin personnel only.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}