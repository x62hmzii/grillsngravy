import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/core/widgets/product_card.dart';
import 'package:grillsngravy/data/models/product_model.dart';
import 'package:grillsngravy/services/firebase_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  // Debouncing variables
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _performSearch(String query) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
        _currentQuery = '';
      });
      return;
    }

    // Set loading state immediately
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _currentQuery = query;
    });

    // Start new debounce timer
    _debounceTimer = Timer(_debounceDuration, () {
      _executeSearch(query);
    });
  }

  void _executeSearch(String query) async {
    try {
      // Get all active products first
      final allProducts = await _getAllActiveProducts();

      // Filter products based on search query
      final filteredProducts = _filterProducts(allProducts, query);

      if (mounted) {
        setState(() {
          _searchResults = filteredProducts;
          _isSearching = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  Future<List<ProductModel>> _getAllActiveProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return ProductModel(
            id: doc.id,
            name: data['name'] ?? 'Unknown Product',
            price: _safeToDouble(data['price']),
            originalPrice: _safeToNullableDouble(data['originalPrice']),
            description: data['description'] ?? '',
            imageUrl: data['imageUrl'] ?? '',
            categoryId: data['categoryId'] ?? '',
            featured: data['featured'] ?? false,
            active: data['active'] ?? true,
            keywords: List<String>.from(data['keywords'] ?? []),
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        } catch (e) {
          return ProductModel(
            id: doc.id,
            name: 'Error Loading Product',
            price: 0.0,
            description: 'Could not load product details',
            imageUrl: '',
            categoryId: '',
            keywords: [],
            createdAt: DateTime.now(),
          );
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<ProductModel> _filterProducts(List<ProductModel> products, String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();

    return products.where((product) {
      // Check if product name contains the query
      final nameMatch = product.name.toLowerCase().contains(lowerQuery);

      // Check if any keyword matches
      final keywordMatch = product.keywords.any((keyword) =>
          keyword.toLowerCase().contains(lowerQuery));

      // Return true if either name or keyword matches
      return nameMatch || keywordMatch;
    }).toList();
  }

  // Advanced matching functions (_checkAdvancedMatch, _areWordsSimilar, _calculateSimilarity, _levenshteinDistance, min, max)
  // ko hata diya gaya hai kyunkay ab unki zaroorat nahi.

  double _safeToDouble(dynamic data) {
    if (data == null) return 0.0;
    if (data is int) return data.toDouble();
    if (data is double) return data;
    if (data is String) return double.tryParse(data) ?? 0.0;
    if (data is num) return data.toDouble();
    return 0.0;
  }

  double? _safeToNullableDouble(dynamic data) {
    if (data == null) return null;
    if (data is int) return data.toDouble();
    if (data is double) return data;
    if (data is String) return double.tryParse(data);
    if (data is num) return data.toDouble();
    return null;
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearched = false;
      _currentQuery = '';
    });
    _searchFocusNode.requestFocus();
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
      appBar: AppBar(
        title: _buildSearchField(),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: _hasSearched ? _buildSearchResults() : _buildInitialState(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search 5000+ products...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.onBackground,
        ),
        onChanged: _performSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildInitialState() {
    // "Popular Searches" aur "Tips" ko hata kar ek saada state add kar di gayi hai.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              color: AppColors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for products by name or keyword',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // _buildSearchChip aur _buildTipItem methods ko hata diya gaya hai.

  Widget _buildSearchResults() {
    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results Count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Found ${_searchResults.length} ${_searchResults.length == 1 ? 'result' : 'results'} for "$_currentQuery"',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
        ),

        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () {
                  _navigateToProductDetail(product);
                },
                onAddToCart: () => _handleAddToCart(product),
              );
            },
          ),
        ),
      ],
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
            'Searching...',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: AppColors.grey,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "$_currentQuery"',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check spelling',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Suggested searches
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Biryani'),
                _buildSuggestionChip('Chicken'),
                _buildSuggestionChip('Rice'),
                _buildSuggestionChip('Curry'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.primary,
          ),
        ),
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