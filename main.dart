import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/presentation/screens/auth/login_screen.dart';
import 'package:grillsngravy/presentation/screens/auth/register_screen.dart';
import 'package:grillsngravy/presentation/screens/categories/categories_screen.dart';
import 'package:grillsngravy/presentation/screens/home/home_screen.dart';
import 'package:grillsngravy/presentation/screens/offers/offers_screen.dart';
import 'package:grillsngravy/presentation/screens/search/search_screen.dart';
import 'package:grillsngravy/presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grills & Gravy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
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
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.onBackground),
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/search': (context) => const SearchScreen(),
        '/offers': (context) => const OffersScreen(),
      },
    );
  }
}