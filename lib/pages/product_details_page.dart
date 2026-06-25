import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/woocommerce_api.dart';
import '../services/cart_provider.dart';
import '../services/wishlist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/premium_product_card.dart';
import 'checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final api = WooCommerceApi();
  late Future<List<Product>> _futureRelated;
  
  List<ProductVariation> _variations = [];
  bool _loadingVariations = false;
  
  final Map<String, String> _selectedAttributes = {};
  
  String _displayPrice = "";
  String _displayRegularPrice = "";
  String _displaySku = "";
  String? _displayImage;
  int? _currentVariationId;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _displayPrice = widget.product.price;
    _displayRegularPrice = widget.product.regularPrice;
    _displaySku = widget.product.sku;
    
    final catIds = widget.product.categories.map((c) => c['id'] as int).toList();
    _futureRelated = api.fetchRelatedProducts(categoryIds: catIds, excludeId: widget.product.id);
    
    for (var attr in widget.product.attributes) {
      if (attr['options'] != null && (attr['options'] as List).isNotEmpty) {
        _selectedAttributes[attr['name']] = (attr['options'] as List)[0].toString();
      }
    }

    if (widget.product.isVariable) _fetchVariations();
  }

  Future<void> _fetchVariations() async {
    setState(() => _loadingVariations = true);
    try {
      final vars = await api.fetchVariations(widget.product.id);
      if (mounted) {
        setState(() {
          _variations = vars;
          _loadingVariations = false;
          _updateDisplayState();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingVariations = false);
    }
  }

  void _updateDisplayState() {
    if (!widget.product.isVariable || _variations.isEmpty) return;
    ProductVariation? match;
    for (var v in _variations) {
      bool attributesMatch = true;
      _selectedAttributes.forEach((key, value) {
        if (v.attributes.containsKey(key) && v.attributes[key] != value) attributesMatch = false;
      });
      if (attributesMatch) { match = v; break; }
    }
    if (match != null) {
      setState(() {
        _displayPrice = match!.price;
        _displayRegularPrice = match!.regularPrice;
        _displaySku = match!.sku.isNotEmpty ? match!.sku : widget.product.sku;
        _displayImage = match!.image;
        _currentVariationId = match!.id;
      });
    } else {
      setState(() => _currentVariationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final wishlist = Provider.of<WishlistProvider>(context);
    final isWishlisted = wishlist.isWishlisted(p.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? AppColors.error : AppColors.textPrimary),
                    onPressed: () => wishlist.toggleWishlist(p),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: p.images.length,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: p.images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(color: AppColors.background),
                    ),
                  ),
                  if (p.images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(p.images.length, (i) => Container(
                          width: _currentImageIndex == i ? 20 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(color: _currentImageIndex == i ? AppColors.primaryStart : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(4)),
                        )),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  if (_displaySku.isNotEmpty) Text("SKU: $_displaySku", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Text("₹$_displayPrice", style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
                      const SizedBox(width: 12),
                      if (_displayRegularPrice.isNotEmpty && _displayRegularPrice != _displayPrice)
                        Text("₹$_displayRegularPrice", style: GoogleFonts.poppins(fontSize: 16, decoration: TextDecoration.lineThrough, color: AppColors.textLight)),
                    ],
                  ),
                  if (_loadingVariations) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator())),
                  
                  if (p.attributes.isNotEmpty) ...[
                    const SizedBox(height: 25),
                    Text("Select Options", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    ...p.attributes.map((attr) {
                      final name = attr['name'];
                      final options = attr['options'] as List;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: options.map((opt) {
                              final bool isSelected = _selectedAttributes[name] == opt.toString();
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedAttributes[name] = opt.toString());
                                  _updateDisplayState();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryStart : AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? AppColors.primaryStart : Colors.grey.shade200),
                                  ),
                                  child: Text(opt.toString(), style: GoogleFonts.poppins(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                  ],

                  const SizedBox(height: 10),
                  Text("Description", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  HtmlWidget(p.description, textStyle: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: AppColors.textSecondary)),
                  const SizedBox(height: 30),
                  
                  Text("You May Also Like", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 240,
                    child: FutureBuilder<List<Product>>(
                      future: _futureRelated,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        final related = snapshot.data ?? [];
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: related.length,
                          itemBuilder: (context, index) => PremiumProductCardHorizontal(product: related[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (_currentVariationId == null && p.isVariable) ? null : () {
                  _addToCart(p);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to bag"), behavior: SnackBarBehavior.floating));
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: AppColors.primaryStart),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("Add to Bag", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GradientButton(
                text: "Buy Now",
                onPressed: (_currentVariationId == null && p.isVariable) ? null : () {
                  _addToCart(p);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product p) {
    Provider.of<CartProvider>(context, listen: false).addItem(
      Product(
        id: p.id, name: p.name, price: _displayPrice, regularPrice: _displayRegularPrice,
        description: p.description, images: p.images, categories: p.categories,
        attributes: p.attributes, sku: _displaySku, type: p.type, stockStatus: p.stockStatus,
      ),
      variationId: _currentVariationId,
      attributes: _selectedAttributes,
    );
  }
}
