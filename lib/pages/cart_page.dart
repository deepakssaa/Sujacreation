import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Bag',
                              style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            TextButton.icon(
                              onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(0),
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 16),
                              label: Text(
                                "Continue Shopping",
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${cart.itemCount} items in your bag',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cart Items
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = cart.items.keys.toList()[index];
                        final item = cart.items[key]!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: item.product.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: item.product.imageUrl,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: AppColors.background),
                                      )
                                    : Container(width: 90, height: 90, color: AppColors.background, child: const Icon(Icons.image)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.selectedAttributes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          item.selectedAttributes.entries.map((e) => "${e.key}: ${e.value}").join(", "),
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "₹${item.product.price}",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryStart),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _qtyAction(Icons.remove, () => cart.removeSingleItem(key)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          child: Text("${item.quantity}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        _qtyAction(Icons.add, () => cart.addItem(item.product, attributes: item.selectedAttributes)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => cart.removeItem(key),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: cart.items.length,
                    ),
                  ),
                ),

                // Order Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order Summary", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 15),
                          _priceRow("Subtotal", "₹${cart.totalAmount.toStringAsFixed(2)}"),
                          const SizedBox(height: 10),
                          _priceRow("Delivery", "Free", isFree: true),
                          const Divider(height: 30),
                          _priceRow("Total", "₹${cart.totalAmount.toStringAsFixed(2)}", isTotal: true),
                        ],
                      ),
                    ),
                  ),
                ),
                // Checkout Action
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    child: Column(
                      children: [
                        GradientButton(
                          text: "Checkout Now",
                          icon: Icons.lock_outline_rounded,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage())),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(0),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text("Continue Shopping"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: AppColors.primaryStart.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.primaryStart.withOpacity(0.3)),
          ),
          const SizedBox(height: 25),
          Text("Your bag is empty", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Look like you haven't added anything to your bag yet.", style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 30),
          GradientButton(
            text: "Continue Shopping",
            width: 220,
            onPressed: () => Provider.of<NavigationProvider>(context, listen: false).setTab(0),
          ),
        ],
      ),
    );
  }

  Widget _qtyAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: isTotal ? 16 : 13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? AppColors.textPrimary : AppColors.textSecondary)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isFree ? Colors.green : (isTotal ? AppColors.primaryStart : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
