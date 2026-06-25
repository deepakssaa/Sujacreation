import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../services/user_provider.dart';
import '../services/woocommerce_customer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'main_navigation_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final Customer customer;
  final String phone;

  const OtpVerificationPage({super.key, required this.customer, required this.phone});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _otpController = TextEditingController();
  final _customerService = WooCommerceCustomerService();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter 4-digit OTP")));
      return;
    }
    setState(() => _isLoading = true);
    final result = await _customerService.verifyOtp(widget.phone, otp);
    setState(() => _isLoading = false);

    if (result['success']) {
      Provider.of<UserProvider>(context, listen: false).setCustomer(widget.customer);
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigationPage()), (route) => false);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Verification failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verification", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
            const SizedBox(height: 10),
            Text("Enter the code sent to +91 ${widget.phone}", style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 50),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 28, letterSpacing: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                counterText: "",
                hintText: "0000",
                hintStyle: TextStyle(letterSpacing: 20, color: Colors.grey.shade300),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            GradientButton(text: "Verify & Continue", onPressed: _isLoading ? null : _verifyOtp),
            if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
