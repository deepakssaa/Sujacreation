import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/navigation_provider.dart';
import '../services/cart_provider.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'shop_page.dart';
import 'cart_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatelessWidget {
  const MainNavigationPage({super.key});

  final List<Widget> _pages = const [
    ShopPage(),
    CartPage(),
    HomePage(),
    OrdersPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return PopScope(
      canPop: nav.currentIndex == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (nav.currentIndex != 2) {
          nav.setTab(2);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: nav.currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(nav, 0, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, "Shop"),
              _buildNavItem(nav, 1, Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, "Cart", badge: cart.itemCount > 0 ? cart.itemCount.toString() : null),
              _buildNavItem(nav, 2, Icons.home_outlined, Icons.home_rounded, "Home"),
              _buildNavItem(nav, 3, Icons.history_outlined, Icons.history_rounded, "Orders"),
              _buildNavItem(nav, 4, Icons.person_outline_rounded, Icons.person_rounded, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationProvider nav, int index, IconData icon, IconData activeIcon, String label, {String? badge}) {
    final bool isActive = nav.currentIndex == index;
    return GestureDetector(
      onTap: () => nav.setTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryStart.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: isActive ? AppColors.primaryStart : AppColors.textLight, size: 22),
                if (badge != null)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.poppins(color: isActive ? AppColors.primaryStart : AppColors.textLight, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
