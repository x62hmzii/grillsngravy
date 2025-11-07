import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// NOTE: Make sure AppColors and OrderModel/OrderItem are correctly imported
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  // --- UI Helper Methods ---

  String _getOrderDisplayId() {
    if (order.id.isEmpty || order.id == 'error') return 'N/A';
    final shortId = order.id.length <= 8 ? order.id : order.id.substring(0, 8);
    return shortId.toUpperCase();
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toTitleCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'delivered':
        return AppColors.success;
      case 'preparing':
      case 'ready':
      case 'out_for_delivery':
        return AppColors.warning; // Keeping warning/blue for in-progress states
      case 'cancelled':
      default:
        return AppColors.error;
    }
  }

  // Simplified Status Index for Timeline (only needs to check if it's confirmed/in-progress)
  int _getStatusIndex(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'preparing':
      case 'ready':
      case 'out_for_delivery':
      case 'delivered':
        return 1; // Any status beyond "Placed" is index 1
      case 'cancelled':
      default:
        return 0; // Placed or Cancelled is index 0
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'digital_wallet':
        return 'Digital Wallet';
      default:
        return method.replaceAll('_', ' ').toTitleCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenPadding = MediaQuery.of(context).padding;
    final statusColor = _getStatusColor(order.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Order #${_getOrderDisplayId()}',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Status: ${_formatStatus(order.status)}',
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: screenPadding.top > 0 ? 0 : 8),

              // 1. Order Items Card
              _buildOrderItemsCard(),
              const SizedBox(height: 16),

              // 2. Simple Order Summary Card (Total and Payment)
              _buildSimpleSummaryCard(),
              const SizedBox(height: 16),

              // 3. Shipping Address Card (Simplified)
              _buildShippingInfoCard(),
              const SizedBox(height: 16),

              // 4. Order Timeline (Simplified)
              _buildSimpleOrderTimeline(),
              SizedBox(height: 20 + screenPadding.bottom),
            ]),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Order Items (${order.items.length})',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => _buildOrderItemRow(item)),
          if (order.items.isEmpty) _buildEmptyItemsState(),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.greyLight,
              image: item.imageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: item.imageUrl.isEmpty ? const Icon(Icons.fastfood, color: AppColors.grey, size: 24) : null,
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Qty: ${item.quantity} x RS ${item.price.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Total Price
          Text(
            'RS ${item.total.toInt()}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Column(
      children: [
        const Icon(Icons.shopping_bag_outlined, color: AppColors.grey, size: 48),
        const SizedBox(height: 8),
        Text('No items in this order', style: GoogleFonts.poppins(color: AppColors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSimpleSummaryCard() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Payment & Total'),
          const SizedBox(height: 12),

          _buildSimpleSummaryRow(
            'Total Amount',
            'RS ${order.total.toInt()}',
            isTotal: true,
          ),
          const Divider(height: 20),

          _buildSimpleSummaryRow(
            'Payment Method',
            _formatPaymentMethod(order.paymentMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSummaryRow(String title, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.onBackground : AppColors.grey,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? AppColors.primary : AppColors.onBackground,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfoCard() {
    final address = order.shippingAddress;

    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Shipping Address'),
          const SizedBox(height: 12),

          _buildAddressDetail('Name', address.fullName),
          _buildAddressDetail('Phone', address.phone),
          _buildAddressDetail('Address', '${address.address}, ${address.city}'),

          if (address.landmark != null && address.landmark!.isNotEmpty)
            _buildAddressDetail('Landmark', address.landmark!),
        ],
      ),
    );
  }

  Widget _buildAddressDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.onBackground, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleOrderTimeline() {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTitle('Order Status'),
          const SizedBox(height: 12),

          // Order Placed (Always completed)
          _buildTimelineDot(
            'Order Placed',
            order.createdAt,
            isCompleted: true,
          ),

          _buildTimelineLine(),

          // Current Status
          _buildTimelineDot(
            _formatStatus(order.status),
            order.createdAt,
            isCompleted: _getStatusIndex(order.status) >= 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(String title, DateTime date, {required bool isCompleted}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot Icon
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.success : AppColors.greyLight,
            border: Border.all(
              color: isCompleted ? AppColors.success : AppColors.grey,
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
              : null,
        ),
        const SizedBox(width: 12),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.onBackground : AppColors.grey,
                ),
              ),
              Text(
                _formatDate(date),
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: AppColors.greyLight,
    );
  }
}

// Extension for string title case (REQUIRED)
extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}' : '').join(' ');
  }
}