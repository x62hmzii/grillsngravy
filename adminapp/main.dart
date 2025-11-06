import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grillsngravy_admin/presentation/providers/order_provider.dart';
import 'package:grillsngravy_admin/presentation/screens/orders/order_list_screen.dart';
import 'package:grillsngravy_admin/presentation/screens/users/user_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:grillsngravy_admin/core/constants/colors.dart';
import 'package:grillsngravy_admin/presentation/providers/auth_provider.dart';
import 'package:grillsngravy_admin/presentation/providers/dashboard_provider.dart';
import 'package:grillsngravy_admin/presentation/screens/auth/admin_login_screen.dart';
import 'package:grillsngravy_admin/presentation/screens/dashboard/admin_dashboard.dart';
import 'package:grillsngravy_admin/presentation/screens/splash/splash_screen.dart';
import 'package:grillsngravy_admin/presentation/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Grills & Gravy Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            background: AppColors.background,
            onBackground: AppColors.onBackground,
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
            error: AppColors.error,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            // backgroundColor: AppColors.background, // <-- FIX 2: Isay remove karein (yeh ColorScheme se ajayega)
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.onBackground),
            titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
          ),
          // scaffoldBackgroundColor: AppColors.background, // <-- FIX 3: Isay bhi remove karein
          cardTheme: CardThemeData( // <-- FIX 1: 'CardTheme' ko 'CardThemeData' karein
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const AdminLoginScreen(),
          '/dashboard': (context) => const AdminDashboard(),
          '/users': (context) => const UserManagementScreen(),
          '/orders': (context) => const OrderListScreen(),
        },
      ),
    );
  }
}