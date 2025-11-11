import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:grillsngravy/data/models/cart_model.dart';
import 'package:grillsngravy/presentation/screens/order/order_confirmation_screen.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';
import 'package:grillsngravy/core/widgets/custom_textfield.dart';
import 'package:grillsngravy/data/models/order_model.dart';
import 'package:grillsngravy/presentation/providers/cart_provider.dart';
import 'package:grillsngravy/services/firebase_service.dart';
import 'package:grillsngravy/services/location_service.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _isLoading = false;
  bool _useSavedAddress = false;
  ShippingAddress? _savedAddress;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSavedAddress();
    _getCurrentLocation();
    _listenToAppSettings();
  }

  void _listenToAppSettings() {
    FirebaseService.getAppSettings().listen((settings) {
      if (mounted) {
        setState(() {
          _appSettings = settings;
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseService.currentUser;
      if (user != null) {
        final userData = await FirebaseService.getUserData(user.uid);
        if (userData != null) {
          _fullNameController.text = userData.fullName;
          _phoneController.text = userData.phone ?? '';
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadSavedAddress() async {
    if (FirebaseService.currentUser == null) return;

    final address = await FirebaseService.getUserAddress(
      FirebaseService.currentUser!.uid,
    );

    if (address != null) {
      setState(() {
        _savedAddress = address;
        _useSavedAddress = true;
        _fillAddressForm(address);
      });
    }
  }

  Map<String, dynamic> _appSettings = {
    'deliveryFee': 100.0,
    'taxRate': 16.0,
    'preparationTime': 30,
  };

  void _fillAddressForm(ShippingAddress address) {
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phone;
    _addressController.text = address.address;
    _cityController.text = address.city;
    _landmarkController.text = address.landmark ?? '';
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final location = await LocationService.getSimplifiedAddress();
      setState(() {
        _cityController.text = location['city'] ?? 'Sahiwal';
        _areaController.text = location['area'] ?? 'Shahdab Town';

        // Auto-fill address with location data
        final fullAddress = location['fullAddress'];
        if (fullAddress != null && fullAddress.isNotEmpty) {
          _addressController.text = fullAddress;
        } else {
          _addressController.text = '${location['area']}, ${location['city']}';
        }
      });
    } catch (e) {
      // Fallback to default values
      setState(() {
        _cityController.text = 'Sahiwal';
        _areaController.text = 'Shahdab Town';
        _addressController.text = 'Shahdab Town, Sahiwal';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  double get _subtotal => widget.cartItems.fold(
      0.0,
          (sum, item) => sum + (item.product.price * item.quantity)
  );

  double get _deliveryFee => _appSettings['deliveryFee'] ?? 100.0;

  double get _total => _subtotal + _deliveryFee;

  int get _preparationTime => _appSettings['preparationTime'] ?? 30;

  String get _deliveryTimeText {
    final time = _preparationTime;
    return '$time-${time + 15} minutes';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (FirebaseService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place order'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create shipping address
      final shippingAddress = ShippingAddress(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        landmark: _landmarkController.text.trim().isNotEmpty
            ? _landmarkController.text.trim()
            : null,
      );

      // Save address if user wants to
      if (_useSavedAddress) {
        await FirebaseService.saveUserAddress(
          userId: FirebaseService.currentUser!.uid,
          address: shippingAddress,
        );
      }

      // Create order items
      final orderItems = widget.cartItems.map((cartItem) => OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
        imageUrl: cartItem.product.imageUrl,
      )).toList();

      // Create order
      final order = OrderModel(
        id: '', // Will be generated by Firestore
        userId: FirebaseService.currentUser!.uid,
        items: orderItems,
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        total: _total,
        status: 'pending',
        paymentMethod: 'cash_on_delivery',
        createdAt: DateTime.now(),
        shippingAddress: shippingAddress,
      );

      // Save order to Firebase
      final orderId = await FirebaseService.createOrder(order);

      // ✅ FIXED: Send notification with proper data
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('sendAdminOrderNotification');
        await callable.call(<String, dynamic>{
          'orderId': orderId,
          'customerName': shippingAddress.fullName,
          'totalAmount': _total,
          'itemsCount': widget.cartItems.fold(0, (sum, item) => sum + item.quantity),
        });
        print('✅ Notification sent for order: $orderId');
      } catch (notificationError) {
        print('⚠️ Notification failed: $notificationError');
        // Continue with order placement even if notification fails
      }

      // Clear cart
      await context.read<CartProvider>().clearCart();

      // Navigate to confirmation
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: orderId),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: ${e.toString()}'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildCheckoutForm(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Placing your order...',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth > 600 ? 24 : 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildOrderSummary(),
                  const SizedBox(height: 24),

                  // Delivery Information
                  _buildDeliverySection(),
                  const SizedBox(height: 24),

                  // Order Items
                  _buildOrderItems(),
                  const SizedBox(height: 24),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Place Order - ₫ ${_total.toInt()}',
                      onPressed: _placeOrder,
                      isLoading: _isLoading,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', '₫ ${_subtotal.toInt()}'),
          _buildSummaryRow('Delivery Fee', '₫ ${_deliveryFee.toInt()}'),
          const Divider(height: 20),
          _buildSummaryRow(
            'Total Amount',
            '₫ ${_total.toInt()}',
            isTotal: true,
          ),
          const SizedBox(height: 8),

          // Delivery time information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated delivery: $_deliveryTimeText',
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
          const SizedBox(height: 4),

          Text(
            'Payment: Cash on Delivery',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isTotal ? 15 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isTotal ? 16 : 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: isTotal ? AppColors.primary : AppColors.onBackground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Information',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),

          // Save Address Toggle
          if (_savedAddress != null)
            Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _useSavedAddress,
                      onChanged: (value) {
                        setState(() => _useSavedAddress = value ?? false);
                        if (value == true) {
                          _fillAddressForm(_savedAddress!);
                        } else {
                          _clearForm();
                          _getCurrentLocation();
                        }
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use saved address',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),

          // Address Form
          if (!_useSavedAddress) ...[
            // Name and Phone
            CustomTextField(
              controller: _fullNameController,
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
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
            const SizedBox(height: 16),

            // Location Auto-fill Section - Responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 500) {
                  // Horizontal layout for wider screens
                  return Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyTextField(
                          controller: _cityController,
                          labelText: 'City',
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReadOnlyTextField(
                          controller: _areaController,
                          labelText: 'Area/Town',
                          icon: Icons.place_outlined,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Vertical layout for narrower screens
                  return Column(
                    children: [
                      _buildReadOnlyTextField(
                        controller: _cityController,
                        labelText: 'City',
                        icon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyTextField(
                        controller: _areaController,
                        labelText: 'Area/Town',
                        icon: Icons.place_outlined,
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _isGettingLocation
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
                  : TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Refresh Location',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // House Number and Street
            _buildHouseNumberField(),
            const SizedBox(height: 16),

            // Complete Address
            _buildAddressField(),
            const SizedBox(height: 16),

            // Landmark
            CustomTextField(
              controller: _landmarkController,
              labelText: 'Landmark (Optional)',
              prefixIcon: Icons.flag_outlined,
            ),
          ] else if (_savedAddress != null) ...[
            // Show saved address
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _savedAddress!.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _savedAddress!.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _savedAddress!.formattedAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.greyLight.withOpacity(0.3),
        enabled: false,
      ),
      style: GoogleFonts.poppins(
        color: AppColors.onBackground,
      ),
    );
  }

  Widget _buildHouseNumberField() {
    return TextFormField(
      controller: _houseNoController,
      decoration: const InputDecoration(
        labelText: 'House No. & Street (Optional)',
        prefixIcon: Icon(Icons.home_outlined),
        border: OutlineInputBorder(),
      ),
      style: GoogleFonts.poppins(
        color: AppColors.onBackground,
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          _addressController.text =
          '$value, ${_areaController.text}, ${_cityController.text}';
        } else {
          _addressController.text =
          '${_areaController.text}, ${_cityController.text}';
        }
      },
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Complete Delivery Address',
        prefixIcon: Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(),
      ),
      style: GoogleFonts.poppins(
        color: AppColors.onBackground,
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your delivery address';
        }
        return null;
      },
    );
  }

  Widget _buildOrderItems() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${widget.cartItems.length})',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.cartItems.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.product.imageUrl,
                  width: constraints.maxWidth > 400 ? 60 : 50,
                  height: constraints.maxWidth > 400 ? 60 : 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: constraints.maxWidth > 400 ? 60 : 50,
                    height: constraints.maxWidth > 400 ? 60 : 50,
                    color: AppColors.greyLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: constraints.maxWidth > 400 ? 60 : 50,
                    height: constraints.maxWidth > 400 ? 60 : 50,
                    color: AppColors.greyLight,
                    child: const Icon(Icons.error_outline, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 400 ? 15 : 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${item.quantity} × ₫ ${item.product.price.toInt()}',
                      style: GoogleFonts.poppins(
                        fontSize: constraints.maxWidth > 400 ? 13 : 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Item Total
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '₫ ${(item.product.price * item.quantity).toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: constraints.maxWidth > 400 ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearForm() {
    _fullNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _areaController.clear();
    _houseNoController.clear();
    _landmarkController.clear();
    _loadUserData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _houseNoController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }
}