import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/woocommerce_api.dart';
import '../services/user_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_widgets.dart';
import 'order_tracking_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final WooCommerceApi _api = WooCommerceApi();
  late Future<List<dynamic>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final customerId = userProvider.currentCustomer?.id;

    if (!mounted) return;

    setState(() {
      _futureOrders = _api.fetchOrders(customerId: customerId);
    });

    await _futureOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryStart,
        onRefresh: _refreshOrders,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                    Text(
                      'My Orders',
                      style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Manage and track your orders',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),

            // Orders List
            FutureBuilder<List<dynamic>>(
              future: _futureOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const ShimmerOrderCard(),
                        childCount: 5,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Padding(padding: const EdgeInsets.only(top: 100), child: Text("Error: ${snapshot.error}"))),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 100),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.primaryStart.withValues(alpha: 0.2)),
                            const SizedBox(height: 20),
                            Text("No orders found", style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textLight)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, order);
                      },
                      childCount: orders.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order['id']}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildStatusBadge(order['status'].toString()),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textLight),
              const SizedBox(width: 6),
              Text(
                DateTime.parse(order['date_created']).toLocal().toString().split('.')[0],
                style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "₹${order['total']}",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryStart),
          ),
          const SizedBox(height: 15),
          Text("Items:", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          ...((order['line_items'] as List).map((item) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "• ${item['name']} x ${item['quantity']}",
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderTrackingPage(orderId: order['id'])),
                );
              },
              icon: const Icon(Icons.track_changes_outlined, size: 18),
              label: Text("Track Order", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed': color = AppColors.success; break;
      case 'processing': color = AppColors.info; break;
      case 'pending': color = AppColors.warning; break;
      case 'cancelled':
      case 'failed': color = AppColors.error; break;
      default: color = AppColors.textLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
