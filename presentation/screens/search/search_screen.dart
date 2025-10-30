import 'dart:async';

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
  StreamSubscription<List<ProductModel>>? _searchSubscription;

  // Search history
  final List<String> _searchHistory = [
    'Chicken Biryani',
    'Grilled Chicken',
    'Naan Bread'
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _currentQuery = query;
    });

    // Cancel previous subscription
    _searchSubscription?.cancel();

    // Create new subscription
    _searchSubscription = FirebaseService.searchProducts(query).listen(
          (products) {
        if (mounted) {
          setState(() {
            _searchResults = products;
            _isSearching = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _searchSubscription?.cancel();
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _hasSearched = false;
      _currentQuery = '';
    });
    _searchFocusNode.requestFocus();
  }

  void _selectHistoryItem(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
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
            ),
        ],
      ),
      body: _hasSearched ? _buildSearchResults() : _buildSearchHistory(),
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
          hintText: 'Search products...',
          hintStyle: GoogleFonts.poppins(
            color: AppColors.grey,
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

  Widget _buildSearchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recent Searches Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
              if (_searchHistory.isNotEmpty)
                TextButton(
                  onPressed: _clearHistory,
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Search History List
        Expanded(
          child: _searchHistory.isEmpty
              ? _buildEmptyHistory()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.history, color: AppColors.grey),
                title: Text(
                  _searchHistory[index],
                  style: GoogleFonts.poppins(
                    color: AppColors.onBackground,
                  ),
                ),
                onTap: () => _selectHistoryItem(_searchHistory[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchHistory.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
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
            'No recent searches',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for products to see them here',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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
            '${_searchResults.length} results for "$_currentQuery"',
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
            'No results found',
            style: GoogleFonts.poppins(
              color: AppColors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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