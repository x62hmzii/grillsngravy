import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';

import '../../../services/firebase_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  //  app settings state
  Map<String, dynamic> _appSettings = {
    'preparationTime': 30,
  };

  @override
  void initState() {
    super.initState();
    //  Load app settings
    _loadAppSettings();
  }

  // ✅ NEW: Load app settings from Firebase
  Future<void> _loadAppSettings() async {
    try {
      final settings = await FirebaseService.getAppSettingsOnce();
      if (mounted) {
        setState(() {
          _appSettings = settings;
        });
      }
    } catch (e) {
      // Fallback to default values if there's an error
      if (mounted) {
        setState(() {
          _appSettings = {'preparationTime': 30};
        });
      }
    }
  }

  // Dynamic delivery time calculation
  String get _deliveryTimeText {
    final time = _appSettings['preparationTime'] ?? 30;
    return '$time-${time + 15} minutes';
  }

  // Helper method for safe order ID display
  String _getOrderDisplayId(String orderId) {
    if (orderId.isEmpty) return 'N/A';
    // Use the full ID if it's short, otherwise take first 8 characters
    return orderId.length <= 8 ? orderId : orderId.substring(0, 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth > 600 ? 32 : 24,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: constraints.maxWidth > 600 ? 120 : 100,
                      height: constraints.maxWidth > 600 ? 120 : 100,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: constraints.maxWidth > 600 ? 70 : 60,
                      ),
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 32 : 24),

                    // Success Message
                    Text(
                      'Order Placed Successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 600 ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 16 : 12),

                    // Order ID
                    Text(
                      'Order #${_getOrderDisplayId(widget.orderId)}',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 600 ? 18 : 16,
                        color: AppColors.greyDark,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 12 : 8),

                    // Thank You Message
                    Text(
                      'Thank you for your order!',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 600 ? 18 : 16,
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 8 : 4),

                    Text(
                      'Your food is being prepared and will be delivered soon.',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 600 ? 15 : 14,
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 40 : 32),

                    // Delivery Information
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(constraints.maxWidth > 600 ? 20 : 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyLight),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.access_time,
                            title: 'Estimated Delivery',
                            value: _deliveryTimeText,
                            constraints: constraints,
                          ),
                          SizedBox(height: constraints.maxWidth > 600 ? 16 : 12),
                          _buildInfoRow(
                            icon: Icons.payment_outlined,
                            title: 'Payment Method',
                            value: 'Cash on Delivery',
                            constraints: constraints,
                          ),
                          SizedBox(height: constraints.maxWidth > 600 ? 16 : 12),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            title: 'Contact Support',
                            value: 'Call if any issue',
                            constraints: constraints,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 40 : 32),

                    // Action Buttons - Only Continue Shopping
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Continue Shopping',
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (route) => false,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: constraints.maxWidth > 600 ? 20 : 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required BoxConstraints constraints,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: constraints.maxWidth > 600 ? 48 : 40,
          height: constraints.maxWidth > 600 ? 48 : 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: constraints.maxWidth > 600 ? 24 : 20,
          ),
        ),
        SizedBox(width: constraints.maxWidth > 600 ? 16 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: constraints.maxWidth > 600 ? 14 : 12,
                  color: AppColors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: constraints.maxWidth > 600 ? 4 : 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: constraints.maxWidth > 600 ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}