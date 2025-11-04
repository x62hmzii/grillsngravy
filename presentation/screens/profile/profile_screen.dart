import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';
import 'package:grillsngravy/core/widgets/custom_textfield.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        // Load user data from Firestore
        final userData = await FirebaseService.getUserData(user.uid);

        if (userData != null) {
          setState(() {
            _fullNameController.text = userData.fullName;
            _phoneController.text = userData.phone ?? '';
            _emailController.text = userData.email;
          });
        } else {
          // Fallback to auth user data
          _emailController.text = user.email ?? '';
        }
      } catch (e) {
        print('Error loading user data: $e');
        // Fallback to auth user data
        _emailController.text = user.email ?? '';
      }
    }

    setState(() {
      _isInitialLoading = false;
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseService.currentUser;
        if (user != null) {
          // Update profile in Firebase
          await FirebaseService.updateUserProfile(
            userId: user.uid,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
        }

        setState(() => _isEditing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelEdit() {
    // Reload original data
    _loadUserData();
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final userEmail = user?.email ?? 'Not logged in';
    final displayName = _fullNameController.text.isEmpty
        ? userEmail.split('@')[0]
        : _fullNameController.text;

    if (_isInitialLoading) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isEditing && user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: user == null
          ? _buildNotLoggedInState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.onPrimary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Member since ${_getMemberSince()}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Full Name Field - Conditionally enabled
                  _isEditing
                      ? CustomTextField(
                    controller: _fullNameController,
                    labelText: 'Full Name',
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
                  )
                      : _buildReadOnlyField(
                    label: 'Full Name',
                    value: _fullNameController.text.isEmpty
                        ? 'Not set'
                        : _fullNameController.text,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Email Field - Always read-only
                  _buildReadOnlyField(
                    label: 'Email Address',
                    value: userEmail,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field - Conditionally enabled
                  _isEditing
                      ? CustomTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  )
                      : _buildReadOnlyField(
                    label: 'Phone Number',
                    value: _phoneController.text.isEmpty
                        ? 'Not set'
                        : _phoneController.text,
                    icon: Icons.phone_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: _cancelEdit,
                      variant: ButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ] else ...[
              CustomButton(
                text: 'Edit Profile',
                onPressed: _toggleEdit,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            color: AppColors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Please login to view your profile',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Login Now',
            onPressed: () {
              Navigator.pushNamed(context, '/auth');
            },
          ),
        ],
      ),
    );
  }

  // Helper method to create read-only fields
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMemberSince() {
    final user = FirebaseService.currentUser;
    if (user?.metadata.creationTime != null) {
      final date = user!.metadata.creationTime!;
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Recently';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}