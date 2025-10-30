import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/constants/strings.dart';
import 'package:grillsngravy/core/widgets/product_card.dart';
import 'package:grillsngravy/data/models/category_model.dart';
import 'package:grillsngravy/data/models/product_model.dart';
import 'package:grillsngravy/presentation/screens/categories/categories_screen.dart';
import 'package:grillsngravy/presentation/screens/offers/offers_screen.dart';
import 'package:grillsngravy/presentation/screens/search/search_screen.dart';
import 'package:grillsngravy/presentation/widgets/bottom_nav_bar.dart';
import 'package:grillsngravy/presentation/widgets/side_drawer.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final BannerController _bannerController = BannerController();

  @override
  void initState() {
    super.initState();
    _bannerController.init();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  // Fixed navigation - don't change index when navigating to other screens
  void _onTabTapped(int index) {
    if (index == _currentIndex) return; // Already on this tab

    switch (index) {
      case 0:
      // Already on home, do nothing
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OffersScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: _handleCartPress,
          ),
        ],
      ),
      drawer: const SideDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              BannerCarousel(controller: _bannerController),
              const SizedBox(height: 16),
              _buildCategoriesSection(),
              const SizedBox(height: 16),
              _buildFeaturedProductsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  // ... (Keep all your existing _build methods exactly as they are)
  // They are working perfectly, no changes needed

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.grey),
              const SizedBox(width: 12),
              Text(
                'Search 5000+ products...',
                style: GoogleFonts.poppins(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/categories'),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<CategoryModel>>(
            stream: FirebaseService.getCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCategoriesShimmer();
              }

              if (snapshot.hasError) {
                print('Categories Error: ${snapshot.error}');
                return _buildDefaultCategories();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildDefaultCategories();
              }

              final categories = snapshot.data!;

              return SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryItem(category);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: index == 4 ? 0 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.greyLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 10,
                  color: AppColors.greyLight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultCategories() {
    final defaultCategories = [
      {'name': 'Barbecue', 'icon': Icons.outdoor_grill},
      {'name': 'Biryani', 'icon': Icons.rice_bowl},
      {'name': 'Curry', 'icon': Icons.soup_kitchen},
      {'name': 'Breads', 'icon': Icons.bakery_dining},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: defaultCategories.length,
        itemBuilder: (context, index) {
          final category = defaultCategories[index];
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: index == defaultCategories.length - 1 ? 0 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        // Navigate to category products
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.greyLight,
                    child: const Icon(
                      Icons.category,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.greyLight,
                    child: const Icon(
                      Icons.category,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onBackground,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Products',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<ProductModel>>(
            stream: FirebaseService.getFeaturedProductsFixed(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildProductsShimmer();
              }

              if (snapshot.hasError) {
                print('Products Error: ${snapshot.error}');
                return _buildErrorWidget('Failed to load products');
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildNoProductsWidget();
              }

              final products = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _navigateToProductDetail(product),
                    onAddToCart: () => _handleAddToCart(product),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                width: 100,
                color: AppColors.greyLight,
              ),
              const SizedBox(height: 4),
              Container(
                height: 8,
                width: 60,
                color: AppColors.greyLight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.grey,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
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

  Widget _buildNoProductsWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.fastfood_outlined,
            color: AppColors.grey,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No featured products available',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _handleCartPress() {
    if (FirebaseService.currentUser == null) {
      _showLoginPrompt();
    } else {
      Navigator.pushNamed(context, '/cart');
    }
  }

  void _handleAddToCart(ProductModel product) {
    if (FirebaseService.currentUser == null) {
      _showLoginPrompt();
    } else {
      FirebaseService.addToCart(
        userId: FirebaseService.currentUser!.uid,
        productId: product.id,
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Required',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Please login to add items to cart and access all features.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _navigateToProductDetail(ProductModel product) {
    // Navigate to product detail screen
  }
}

// Banner Controller and Carousel (keep as is)
class BannerController {
  final PageController pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;
  int _totalBanners = 0;
  ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);

  void init() {
    _startAutoScroll();
  }

  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    currentIndexNotifier.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageController.hasClients && _totalBanners > 0) {
        int nextPage = _currentIndex + 1;
        if (nextPage >= _totalBanners) {
          nextPage = 0;
        }
        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void onPageChanged(int index, int totalBanners) {
    _currentIndex = index;
    _totalBanners = totalBanners;
    currentIndexNotifier.value = index;
  }

  void onBannersLoaded(int totalBanners) {
    _totalBanners = totalBanners;
    _timer?.cancel();
    _startAutoScroll();
  }
}

class BannerCarousel extends StatelessWidget {
  final BannerController controller;

  const BannerCarousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerShimmer();
        }

        if (snapshot.hasError) {
          print('Banner Error: ${snapshot.error}');
          return _buildDefaultBanner();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDefaultBanner();
        }

        final banners = snapshot.data!;
        controller.onBannersLoaded(banners.length);

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: (index) => controller.onPageChanged(index, banners.length),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: banner['imageUrl'] as String,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.greyLight,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.greyLight,
                              child: const Icon(Icons.error),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          if (banner['title'] != null && banner['title'].toString().isNotEmpty)
                            Positioned(
                              left: 16,
                              bottom: 16,
                              right: 16,
                              child: Text(
                                banner['title'] as String,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            if (banners.length > 1)
              ValueListenableBuilder<int>(
                valueListenable: controller.currentIndexNotifier,
                builder: (context, currentIndex, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(banners.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentIndex == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.3),
                        ),
                      );
                    }),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildBannerShimmer() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant,
              color: AppColors.onPrimary,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Grills & Gravy',
              style: GoogleFonts.poppins(
                color: AppColors.onPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Quality Food Is The Most Important Thing\nIn Our Life',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.onPrimary.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}