import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/data/models/product_model.dart';
import 'package:grillsngravy/presentation/widgets/bottom_nav_bar.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  int _currentIndex = 3; // Offers tab is active

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/categories');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 3:
      // Already on offers
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Special Offers',
          style: GoogleFonts.poppins(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<ProductModel>>(
          stream: FirebaseService.getFeaturedProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState('Failed to load offers');
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            // Filter products that have discounts
            final discountedProducts = snapshot.data!
                .where((product) => product.hasDiscount)
                .toList();

            if (discountedProducts.isEmpty) {
              return _buildNoOffersState();
            }

            return _buildOffersList(discountedProducts);
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildOffersList(List<ProductModel> products) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildOfferItem(product);
      },
    );
  }

  Widget _buildOfferItem(ProductModel product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _navigateToProductDetail(product);
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120, // Fixed height to prevent overflow
          child: Row(
            children: [
              // Product Image - Fixed width
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(product.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Product Details - Flexible to take remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Price and Discount Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Row
                          Row(
                            children: [
                              Text(
                                'RS ${product.price.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (product.hasDiscount)
                              // --- FIX IS HERE ---
                              // Wrapped the original price Text in Flexible
                                Flexible( // <-- WIDGET ADDED
                                  child: Text(
                                    'RS ${product.originalPrice!.toInt()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    maxLines: 1, // <-- ADDED
                                    overflow: TextOverflow.ellipsis, // <-- ADDED
                                  ),
                                ),
                              // --- END OF FIX ---
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Discount Badge
                          if (product.hasDiscount)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discountPercentage.round()}% OFF',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Add to Cart Button
              Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: () => _handleAddToCart(product),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.onPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 120,
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          color: AppColors.greyLight,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 80,
                              color: AppColors.greyLight,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 60,
                              color: AppColors.greyLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.add, size: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              color: AppColors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No offers available',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOffersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.percent_outlined,
              color: AppColors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No special offers at the moment',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for amazing deals!',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
        ),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to add items to cart.'),
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
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: product.id,
    );
  }
}