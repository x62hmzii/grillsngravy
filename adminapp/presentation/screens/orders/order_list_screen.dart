import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/core/widgets/search_field.dart';
import 'package:grillsngravy_admin/data/models/order_model.dart';
import 'package:grillsngravy_admin/presentation/providers/order_provider.dart';
import 'package:grillsngravy_admin/presentation/screens/orders/order_detail_screen.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with Search and Filters
          _buildHeaderSection(),

          // Statistics Cards
          _buildStatisticsSection(),

          // Orders List
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar - FIXED VERSION
          SearchField(
            controller: _searchController,
            hintText: 'Search by order ID, customer name or phone...',
            onChanged: (value) {
              context.read<OrderProvider>().setSearchQuery(value);
            },
            onClear: () { // ← YEH ADD KAREIN
              _searchController.clear();
              context.read<OrderProvider>().setSearchQuery('');
            },
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
          _buildStatusFilterChips(),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final orderProvider = context.watch<OrderProvider>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: orderProvider.statusOptions.map((status) {
          final isSelected = orderProvider.statusFilter == status;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                status == 'all' ? 'All Orders' : status.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.onPrimary : AppColors.onBackground,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                orderProvider.setStatusFilter(status);
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.greyLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final stats = orderProvider.getOrderStatistics();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatItem('Total', stats['total']?.toString() ?? '0', AppColors.primary),
                _buildStatItem('Pending', stats['pending']?.toString() ?? '0', AppColors.warning),
                _buildStatItem('Confirmed', stats['confirmed']?.toString() ?? '0', AppColors.info),
                _buildStatItem('Preparing', stats['preparing']?.toString() ?? '0', AppColors.primary),
                _buildStatItem('Delivered', stats['delivered']?.toString() ?? '0', AppColors.success),
                _buildStatItem('Cancelled', stats['cancelled']?.toString() ?? '0', AppColors.error),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return _buildLoadingState();
        }

        if (orderProvider.orders.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => orderProvider.refreshOrders(),
          backgroundColor: AppColors.background,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProvider.orders.length,
            itemBuilder: (context, index) {
              final order = orderProvider.orders[index];
              return _buildOrderItem(order);
            },
          ),
        );
      },
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
            'Loading orders...',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Orders will appear here when customers place orders'
                : 'No orders match your search criteria',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToOrderDetail(order);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${_getOrderDisplayId(order.id)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer Info
                Text(
                  'Customer: ${order.shippingAddress.fullName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),

                // Order Details
                Text(
                  '${order.items.length} item${order.items.length > 1 ? 's' : ''} • RS ${order.total.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),

                // Order Date & Time
                Text(
                  'Placed on ${_formatDateTime(order.createdAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Actions
                _buildQuickActions(order),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickActions(OrderModel order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showStatusUpdateDialog(order),
            icon: const Icon(Icons.edit, size: 16),
            label: Text(
              'Update Status',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToOrderDetail(order),
            icon: const Icon(Icons.visibility, size: 16),
            label: Text(
              'View Details',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: const BorderSide(color: AppColors.info),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'preparing':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _getOrderDisplayId(String orderId) {
    if (orderId.isEmpty) return 'N/A';
    return orderId.length <= 8 ? orderId : orderId.substring(0, 8).toUpperCase();
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  void _navigateToOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(order: order),
      ),
    );
  }

  void _showStatusUpdateDialog(OrderModel order) {
    final orderProvider = context.read<OrderProvider>();
    String? selectedStatus;

    // Store the current context before opening dialog
    final BuildContext currentContext = context;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Update Order Status',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order #${_getOrderDisplayId(order.id)}',
                  style: GoogleFonts.poppins(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus ?? order.status,
                  items: orderProvider.statusOptions
                      .where((status) => status != 'all')
                      .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(),
                    ),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedStatus = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedStatus != null && selectedStatus != order.status) {
                    // Close the dialog first
                    Navigator.pop(context);

                    // Use a small delay to ensure dialog is completely closed
                    await Future.delayed(const Duration(milliseconds: 100));

                    try {
                      await orderProvider.updateOrderStatus(order.id, selectedStatus!);

                      // Use the stored context to show snackbar
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Order status updated to ${selectedStatus!.toUpperCase()}'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: ${e.toString()}'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}