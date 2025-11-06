import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/services/firebase_admin_service.dart';

class AdminSideDrawer extends StatelessWidget {
  const AdminSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Admin ka email Firebase se fetch karein
    final adminUser = FirebaseAdminService.currentUser;
    final adminEmail = adminUser?.email ?? 'admin@grillsngravy.com';

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
              color: AppColors.primary.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.greyLight.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: AppColors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Panel',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        adminEmail,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                // Content Management Section
                _buildSectionHeader('Content Management'),
                _buildDrawerItem(
                  icon: Icons.image_outlined,
                  title: 'Manage Banners',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.pushNamed(context, '/manage-banners');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category_outlined,
                  title: 'Manage Categories',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.pushNamed(context, '/manage-categories');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Manage Offers',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.pushNamed(context, '/manage-offers');
                  },
                ),

                // Application Section
                _buildSectionHeader('Application'),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About App',
                  onTap: () {
                    Navigator.pop(context);
                    // About screen show karein
                  },
                ),
              ],
            ),
          ),

          // Logout Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.greyLight.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.grey,
      ),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAdminService.signOut();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}