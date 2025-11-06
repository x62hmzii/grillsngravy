import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/core/constants/strings.dart';
import 'package:grillsngravy_admin/presentation/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Add slight delay for smooth animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final isAdmin = await authProvider.checkAdminStatus();

    if (isAdmin) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo with Admin Badge
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: isSmallScreen ? 100 : 120,
                        height: isSmallScreen ? 100 : 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant,
                          color: AppColors.onPrimary,
                          size: isSmallScreen ? 50 : 60,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: isSmallScreen ? 28 : 32,
                          height: isSmallScreen ? 28 : 32,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            color: AppColors.onPrimary,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // App Name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    AppStrings.appName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 40,
                    ),
                    child: Text(
                      'Admin Management Panel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: AppColors.greyDark,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Loading Indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: isSmallScreen ? 24 : 28,
                    height: isSmallScreen ? 24 : 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Loading Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}