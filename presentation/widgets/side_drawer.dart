import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/constants/strings.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                            'Welcome Guest',
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
                          // Implement call functionality
                          _showContactOptions(context);
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
                // User Section
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
                  icon: Icons.favorite_outline,
                  title: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to favorites screen
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
                _buildDrawerItem(
                  icon: Icons.contact_support_outlined,
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.pop(context);
                    _showContactOptions(context);
                  },
                ),

                // Legal Section
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
                _buildDrawerItem(
                  icon: Icons.assignment_return_outlined,
                  title: 'Returns & Refunds',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to returns policy screen
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to feedback screen
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
                            'Ver. 2.1.2 (79)',
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

          // Login/Register Section
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
            child: Row(
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

  void _showContactOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Wrap(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Contact Us',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactOption(
                    icon: Icons.phone,
                    title: 'Call Us',
                    subtitle: 'Speak directly with our team',
                    onTap: () {
                      Navigator.pop(context);
                      _makePhoneCall();
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.grey,
      ),
      onTap: onTap,
    );
  }

  void _makePhoneCall() {
    // Implement phone call functionality
    // const phoneNumber = 'tel:+1234567890';
    // launchUrl(Uri.parse(phoneNumber));
  }

  void _sendEmail() {
    // Implement email functionality
    // const email = 'mailto:support@grillsngravy.com';
    // launchUrl(Uri.parse(email));
  }

  void _startLiveChat() {
    // Implement live chat functionality
  }

  void _openLocation() {
    // Implement location functionality
    // const location = 'https://maps.google.com/?q=Grills+Gravy';
    // launchUrl(Uri.parse(location));
  }
}