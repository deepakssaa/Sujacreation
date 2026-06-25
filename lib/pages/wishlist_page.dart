import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/wishlist_provider.dart';
import '../services/cart_provider.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'product_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context);
    final items = wishlist.items.values.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 25),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text("My Wishlist", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          items.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(context))
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = items[index];
                        return _WishlistItemCard(product: product);
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline_rounded, size: 80, color: AppColors.primaryStart.withOpacity(0.2)),
          const SizedBox(height: 25),
          Text("Your wishlist is empty", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Save designs you love for later!", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13)),
          const SizedBox(height: 30),
          GradientButton(text: "Start Exploring", width: 200, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final Product product;
  const _WishlistItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: AppColors.background),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text("₹${product.price}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryStart)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.error),
                onPressed: () => Provider.of<WishlistProvider>(context, listen: false).toggleWishlist(product),
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primaryStart),
                onPressed: () {
                  if (product.isVariable) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)));
                  } else {
                    Provider.of<CartProvider>(context, listen: false).addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to bag"), behavior: SnackBarBehavior.floating));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
