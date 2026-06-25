import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tracking_data.dart';
import '../services/tracking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

class OrderTrackingPage extends StatefulWidget {
  final int orderId;
  final bool testMode;
  const OrderTrackingPage({super.key, required this.orderId, this.testMode = false});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final TrackingService _trackingService = TrackingService();
  late Future<TrackingData?> _trackingFuture;

  @override
  void initState() {
    super.initState();
    _trackingFuture = _trackingService.getTrackingInfo(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 25),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                  const SizedBox(width: 15),
                  Text("Track Order #${widget.orderId}", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ]),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: FutureBuilder<TrackingData?>(
              future: _trackingFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) return _buildNoTrackingState();

                final tracking = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTrackingHeader(tracking),
                      const SizedBox(height: 30),
                      Text("Shipment Journey", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTimeline(tracking.events),
                      const SizedBox(height: 30),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(tracking.trackingUrl);
                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text("View on courier website"),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: AppColors.primaryStart.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          foregroundColor: AppColors.primaryStart,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingHeader(TrackingData tracking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfo("Tracking ID", tracking.trackingId),
              _headerInfo("Partner", tracking.partner, crossAxisAlignment: CrossAxisAlignment.end),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primaryStart.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.local_shipping_outlined, color: AppColors.primaryStart)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tracking.status, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryStart)),
                Text("Est. Delivery: ${tracking.estimatedDelivery}", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13)),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(crossAxisAlignment: crossAxisAlignment, children: [
      Text(label, style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 11)),
      Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }

  Widget _buildTimeline(List<TrackingEvent> events) {
    if (events.isEmpty) return Center(child: Text("No tracking updates yet", style: GoogleFonts.poppins(color: AppColors.textLight)));
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isFirst = index == 0;
        final isLast = index == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: isFirst ? AppColors.primaryStart : Colors.grey.shade300, shape: BoxShape.circle, border: isFirst ? Border.all(color: AppColors.primaryStart.withOpacity(0.2), width: 4) : null)),
                if (!isLast) Container(width: 2, height: 60, color: Colors.grey.shade200),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.status, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: isFirst ? AppColors.textPrimary : AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(event.description, style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("${event.time} • ${event.location}", style: GoogleFonts.poppins(color: AppColors.textLight.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNoTrackingState() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.location_off_outlined, size: 80, color: AppColors.primaryStart.withOpacity(0.1)),
      const SizedBox(height: 25),
      Text("No Tracking Found", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text("Tracking details will be updated once your order is shipped.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14)),
      const SizedBox(height: 30),
      GradientButton(text: "Go Back", width: 150, onPressed: () => Navigator.pop(context)),
    ])));
  }
}
