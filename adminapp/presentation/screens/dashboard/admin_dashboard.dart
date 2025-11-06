import 'package:flutter/material.dart';
import 'package:grillsngravy_admin/presentation/screens/users/user_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/core/constants/strings.dart';
import 'package:grillsngravy_admin/presentation/providers/dashboard_provider.dart';
import 'package:grillsngravy_admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:grillsngravy_admin/presentation/widgets/admin_side_drawer.dart';
import 'package:grillsngravy_admin/presentation/screens/orders/order_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0: // Dashboard
        return _buildDashboardContent();
      case 1: // Products
        return _buildPlaceholderScreen('Products Management', Icons.fastfood_outlined);
      case 2: // Orders
        return const OrderListScreen();
      case 3: // Users
        return const UserManagementScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildPlaceholderScreen(String title, IconData icon) {
    // (Yeh function bilkul theek hai, koi change nahi)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // (Yeh function bilkul theek hai, koi change nahi)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_currentIndex),
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
        actions: _buildAppBarActions(_currentIndex),
      ),
      drawer: const AdminSideDrawer(),
      body: _buildCurrentScreen(),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    // (Yeh function bilkul theek hai, koi change nahi)
    switch (index) {
      case 0:
        return AppStrings.dashboard;
      case 1:
        return AppStrings.products;
      case 2:
        return AppStrings.orders;
      case 3:
        return AppStrings.users;
      default:
        return AppStrings.dashboard;
    }
  }

  List<Widget> _buildAppBarActions(int index) {
    // (Yeh function bilkul theek hai, koi change nahi)
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () {
          if (index == 0) {
            context.read<DashboardProvider>().loadDashboardData();
          }
        },
        tooltip: 'Refresh',
      ),
    ];
  }

  Widget _buildLoadingState() {
    // (Yeh function bilkul theek hai, koi change nahi)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading dashboard...',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // --- YAHAN SE CHANGES SHURU HAIN ---

  Widget _buildDashboardContent() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.isLoading) {
          return _buildLoadingState();
        }

        // Humne yahan se Column/SizedBox hata diya hai
        // Taaki Business Overview card screen ke center mein focus ho
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Business Overview Section (New Design)
              _buildBusinessOverviewSection(dashboardProvider),

              // Aap yahan dosre sections (like Recent Orders, etc.) baad mein add kar sakte hain
              // const SizedBox(height: 24),
              // _buildRecentOrdersSection(dashboardProvider),
            ],
          ),
        );
      },
    );
  }

  /// [FIXED] Naya responsive "Business Overview" card
  Widget _buildBusinessOverviewSection(DashboardProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, // Cards ke liye 'surface' behtar hai
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.greyLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header (Waisa hi hai)
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Business Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32), // Circles ke liye thori zyada jagah

          // [NEW] Responsive Row for Circles
          // Yeh Row ensure karega ke dono circles hamesha screen par fit ayen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 'Expanded' istemal kiya hai taaki dono items barabar jagah lein
              Expanded(
                child: _buildOverviewCircle(
                  title: 'Total Users',
                  value: provider.totalUsers.toString(),
                  color: AppColors.info,
                  onTap: () {
                    setState(() => _currentIndex = 3); // User screen par navigate
                  },
                ),
              ),
              const SizedBox(width: 16), // Dono circles ke darmiyan space
              Expanded(
                child: _buildOverviewCircle(
                  title: 'Total Orders',
                  value: provider.totalOrders.toString(),
                  color: AppColors.primary,
                  onTap: () {
                    setState(() => _currentIndex = 2); // Order screen par navigate
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Card ke neechay thori padding
        ],
      ),
    );
  }

  /// [NEW] Naya helper widget jo aapke design ke mutabiq circle banata hai
  Widget _buildOverviewCircle({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100), // Click effect ko gol rakhega
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle Container
          Container(
            width: 100, // Aap isay chota/bada kar sakte hain
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Text (Circle ke neechay)
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.greyDark,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}