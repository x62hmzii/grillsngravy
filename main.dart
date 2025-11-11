import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:grillsngravy/data/models/cart_model.dart';
import 'package:grillsngravy/presentation/screens/categories/category_products_screen.dart';
import 'package:grillsngravy/presentation/screens/order/order_confirmation_screen.dart';
import 'package:grillsngravy/presentation/screens/order/orders_screen.dart';
import 'package:grillsngravy/presentation/screens/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/presentation/providers/cart_provider.dart';
import 'package:grillsngravy/presentation/screens/auth/login_screen.dart';
import 'package:grillsngravy/presentation/screens/auth/register_screen.dart';
import 'package:grillsngravy/presentation/screens/cart/cart_screen.dart';
import 'package:grillsngravy/presentation/screens/categories/categories_screen.dart';
import 'package:grillsngravy/presentation/screens/home/home_screen.dart';
import 'package:grillsngravy/presentation/screens/offers/offers_screen.dart';
import 'package:grillsngravy/presentation/screens/product_detail/product_detail_screen.dart';
import 'package:grillsngravy/presentation/screens/search/search_screen.dart';
import 'package:grillsngravy/presentation/screens/splash/splash_screen.dart';
import 'package:grillsngravy/presentation/screens/checkout/checkout_screen.dart';
import 'package:grillsngravy/data/models/category_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
  }

  runApp(const MyApp());
  // Set the orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Grills & Gravy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.background,
            onSurface: AppColors.onBackground,
            error: AppColors.error,
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.onBackground),
            titleTextStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onBackground,
            ),
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
          '/category-products': (context) => CategoryProductsScreen(
            category: ModalRoute.of(context)!.settings.arguments as CategoryModel,
          ),
          '/search': (context) => const SearchScreen(),
          '/offers': (context) => const OffersScreen(),
          '/cart': (context) => const CartScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/checkout': (context) => CheckoutScreen(
            cartItems: ModalRoute.of(context)!.settings.arguments as List<CartItem>,
          ),
          '/order-confirmation': (context) => OrderConfirmationScreen(
            orderId: ModalRoute.of(context)!.settings.arguments as String,
          ),
          '/product-detail': (context) => ProductDetailScreen(
            productId: ModalRoute.of(context)!.settings.arguments as String,
          ),
        },
      ),
    );
  }
}