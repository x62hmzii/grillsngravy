import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/custom_button.dart';
import 'package:grillsngravy/data/models/product_model.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = true;
  int _quantity = 1;
  StreamSubscription<List<ProductModel>>? _productSubscription;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }

  void _loadProduct() async {
    try {
      _productSubscription = FirebaseService.getFeaturedProducts().listen(
            (products) {
          final product = products.firstWhere(
                (p) => p.id == widget.productId,
            orElse: () => products.isNotEmpty ? products.first : _createDummyProduct(),
          );

          if (mounted) {
            setState(() {
              _product = product;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _product = _createDummyProduct();
        });
      }
    }
  }

  ProductModel _createDummyProduct() {
    return ProductModel(
      id: widget.productId,
      name: 'Product Not Found',
      price: 0,
      description: 'This product is currently unavailable.',
      imageUrl: '',
      categoryId: '',
      keywords: [],
      featured: false,
      active: true,
      createdAt: DateTime.now(),
    );
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    if (FirebaseService.currentUser == null) {
      _showLoginPrompt();
      return;
    }

    if (_product == null) return;

    FirebaseService.addToCart(
      userId: FirebaseService.currentUser!.uid,
      productId: _product!.id,
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!.name} added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _product == null
          ? _buildErrorState()
          : _buildProductDetail(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            'Product not found',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetail() {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              _buildProductImage(),

              // Product Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Price
                    _buildProductHeader(),

                    const SizedBox(height: 16),

                    // Description
                    _buildProductDescription(),

                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
        ),

        // Add to Cart Button (Fixed at bottom)
        _buildAddToCartButton(),
      ],
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: _product!.imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: _product!.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.greyLight,
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.greyLight,
              child: const Icon(
                Icons.fastfood_outlined,
                color: AppColors.grey,
                size: 60,
              ),
            ),
          )
              : Container(
            color: AppColors.greyLight,
            child: const Icon(
              Icons.fastfood_outlined,
              color: AppColors.grey,
              size: 60,
            ),
          ),
        ),
        // Back Button
        Positioned(
          top: 40,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        // Discount Badge
        if (_product!.hasDiscount)
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_product!.discountPercentage.round()}% OFF',
                style: GoogleFonts.poppins(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'RS ${_product!.price.toInt()}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            if (_product!.hasDiscount) ...[
              const SizedBox(width: 8),
              Text(
                'RS ${_product!.originalPrice!.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _product!.description,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.greyLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _decreaseQuantity,
                    icon: const Icon(Icons.remove, size: 18),
                    padding: const EdgeInsets.all(4),
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      _quantity.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _increaseQuantity,
                    icon: const Icon(Icons.add, size: 18),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add to Cart Button
            Expanded(
              child: CustomButton(
                text: 'Add to Cart - RS ${(_product!.price * _quantity).toInt()}',
                onPressed: _addToCart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}