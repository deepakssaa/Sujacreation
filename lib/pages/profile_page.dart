import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../services/user_provider.dart';
import '../services/navigation_provider.dart';
import 'edit_profile_page.dart';
import 'manage_addresses_page.dart';
import 'phone_login_page.dart';
import 'orders_page.dart';
import 'referral_dashboard_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentCustomer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 40),
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        user != null ? (user.firstName.isNotEmpty ? user.firstName[0] : 'U') : 'G',
                        style: GoogleFonts.playfairDisplay(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user != null ? "${user.firstName} ${user.lastName}" : "Guest User",
                    style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user?.email ?? "Welcome to Suja Creations",
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSection(
                    title: "My Account",
                    items: [
                      _profileItem(Icons.person_outline_rounded, "Edit Profile", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
                      _profileItem(Icons.history_rounded, "My Orders", () => Provider.of<NavigationProvider>(context, listen: false).setTab(3)),
                      _profileItem(Icons.location_on_outlined, "Manage Addresses", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAddressesPage()))),
                      _profileItem(Icons.card_giftcard_rounded, "Refer & Earn", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralDashboardPage()))),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildSection(
                    title: "Support",
                    items: [
                      _profileItem(FontAwesomeIcons.whatsapp, "WhatsApp Support", () async {
                        String msg = "Hello, I need help with Suja Creations.";
                        if (user != null) {
                          msg = "Hello Suja Creations, I need help with my account.\n\n"
                                "Details:\n"
                                "- Name: ${user.firstName} ${user.lastName}\n"
                                "- Phone: ${user.billing.phone}\n"
                                "- Email: ${user.email}\n"
                                "- City: ${user.billing.city}\n"
                                "- State: ${user.billing.state}";
                        }
                        final Uri uri = Uri.parse("https://wa.me/918248177897?text=${Uri.encodeComponent(msg)}");
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }),
                      _profileItem(Icons.info_outline_rounded, "About Us", () {}),
                      _profileItem(Icons.privacy_tip_outlined, "Privacy Policy", () async {
                        final Uri uri = Uri.parse("https://sujacreation.com/privacy-policy/");
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Logout Button
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text("Logout", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                          content: Text("Are you sure you want to logout from Suja Creations?", style: GoogleFonts.poppins()),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text("Cancel", style: GoogleFonts.poppins(color: AppColors.textLight)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await Provider.of<UserProvider>(context, listen: false).logout();
                                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PhoneLoginPage()), (route) => false);
                              },
                              child: Text("Logout", style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Text("Logout", style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 10),
          child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _profileItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryStart.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primaryStart, size: 20)),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}
