import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/woocommerce_api.dart';
import '../services/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_product_card.dart';
import '../widgets/shimmer_widgets.dart';

class ShopPage extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;

  const ShopPage({super.key, this.categoryId, this.categoryName});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final api = WooCommerceApi();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  
  String _searchQuery = "";
  String _orderBy = "date";
  String _order = "desc";
  int? _selectedCategoryId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _fetchInitialProducts();
    _fetchCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = Provider.of<NavigationProvider>(context);
    if (nav.selectedCategoryId != null && nav.selectedCategoryId != _selectedCategoryId) {
      _selectedCategoryId = nav.selectedCategoryId;
      _fetchInitialProducts();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nav.clearCategory();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _fetchCategories() async {
    final cats = await api.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = <Map<String, dynamic>>[{'id': 0, 'name': 'All'}] + cats;
      });
    }
  }

  Future<void> _fetchInitialProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _page = 1;
      _products = [];
      _hasMore = true;
    });

    try {
      final products = await api.fetchProducts(
        page: _page,
        perPage: 20,
        search: _searchQuery,
        categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
        orderBy: _orderBy,
        order: _order,
      );

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          if (products.length < 20) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _page++;

    try {
      final products = await api.fetchProducts(
        page: _page,
        perPage: 20,
        search: _searchQuery,
        categoryId: _selectedCategoryId == 0 ? null : _selectedCategoryId,
        orderBy: _orderBy,
        order: _order,
      );

      if (mounted) {
        setState(() {
          _products.addAll(products);
          _isLoading = false;
          if (products.length < 20) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Sort Products', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _sortEntry('Newest First', 'date', 'desc'),
              _sortEntry('Price: Low to High', 'price', 'asc'),
              _sortEntry('Price: High to Low', 'price', 'desc'),
              _sortEntry('Popularity', 'popularity', 'desc'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _sortEntry(String title, String orderBy, String order) {
    final bool isSelected = _orderBy == orderBy && _order == order;
    return ListTile(
      onTap: () {
        setState(() { _orderBy = orderBy; _order = order; });
        _fetchInitialProducts();
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppColors.primaryStart : AppColors.textLight,
      ),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Our Collection",
                      style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _showSortOptions,
                      icon: const Icon(Icons.sort_rounded, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onTap: () {
                      if (_selectedCategoryId != 0 && _selectedCategoryId != null) {
                        setState(() => _selectedCategoryId = 0);
                        _fetchInitialProducts();
                      }
                    },
                    onChanged: (v) {
                      _searchQuery = v;
                      if (v.isEmpty) {
                        _fetchInitialProducts();
                      }
                    },
                    onSubmitted: (v) { 
                      _searchQuery = v;
                      if (_selectedCategoryId != 0 && _selectedCategoryId != null) {
                        setState(() => _selectedCategoryId = 0);
                      }
                      _fetchInitialProducts(); 
                    },
                    decoration: InputDecoration(
                      hintText: "Search jewellery...",
                      hintStyle: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categories
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 15),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final bool isSelected = (_selectedCategoryId == cat['id']) || (cat['id'] == 0 && _selectedCategoryId == null);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat['name']),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedCategoryId = cat['id']);
                        _fetchInitialProducts();
                      },
                      selectedColor: AppColors.primaryStart,
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

          // Product Grid
          Expanded(
            child: _isLoading && _products.isEmpty
              ? const ShimmerProductGrid(itemCount: 6)
              : RefreshIndicator(
                  color: AppColors.primaryStart,
                  onRefresh: _fetchInitialProducts,
                  child: _products.isEmpty
                    ? Center(child: Text("No products found", style: GoogleFonts.poppins()))
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: _products.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _products.length) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                          return PremiumProductCard(product: _products[index]);
                        },
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
