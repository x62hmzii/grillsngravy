import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/constants/strings.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseService.currentUser != null;
    final userEmail = FirebaseService.currentUser?.email;
    final userName = userEmail?.split('@')[0] ?? 'User';

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.greyLight.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: AppColors.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoggedIn ? 'Welcome, $userName' : 'Welcome Guest',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.greyDark,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Call Us Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: AppColors.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Call Us',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Have questions? We\'re here to help!',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.onPrimary.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          _makePhoneCall();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Contact Now',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // User Section - Only show if logged in
                if (isLoggedIn) ...[
                  _buildSectionHeader('My Account'),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to profile screen
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to orders screen
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Addresses',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to addresses screen
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                // App Information Section
                _buildSectionHeader('About Us'),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About Grills & Gravy',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to about us screen
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & FAQs',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to help screen
                  },
                ),

                // Legal Section (Required for Play Store)
                _buildSectionHeader('Legal'),
                _buildDrawerItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to privacy policy screen
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to terms screen
                  },
                ),

                const SizedBox(height: 20),

                // App Version
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'App Version',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            'Ver. 1.0.0',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.greyDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Login/Register or Logout Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.greyLight.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: isLoggedIn
                ? Column(
              children: [
                Text(
                  'Logged in as $userEmail',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _logout(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/auth');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Login / Register',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 8,
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.greyDark,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        icon,
        size: 20,
        color: AppColors.greyDark,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.onBackground,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.grey,
      ),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseService.signOut();
      // Clear cart when logging out
      // You might want to add this to your CartProvider

      // Navigate to auth screen and clear all routes
      Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
              (route) => false
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _makePhoneCall() {
    // Implement phone call functionality
    // You can use url_launcher package for this
    // const phoneNumber = 'tel:+1234567890';
    // launchUrl(Uri.parse(phoneNumber));

    // For now, show a dialog
    showDialog(
      context: _getContext(),
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: const Text('Call us at: +1 234 567 890\nWe are available 24/7 for your queries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to get context for dialogs
  BuildContext _getContext() {
    // This is a workaround to get context for dialogs
    // In a real app, you might want to pass context differently
    return Navigator.of(_getKey().currentContext!).context;
  }

  GlobalKey<NavigatorState> _getKey() {
    return GlobalKey<NavigatorState>();
  }
}