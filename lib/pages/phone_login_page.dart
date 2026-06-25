import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/woocommerce_customer_service.dart';
import '../services/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';
import 'main_navigation_page.dart';
import 'signup_page.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final WooCommerceCustomerService _customerService = WooCommerceCustomerService();

  bool _isLoading = false;
  bool _otpSent = false;
  String _phoneNumber = '';

  Timer? _resendTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _checkExistingLogin() async {
    final storedPhone = await _authService.getStoredPhone();
    if (storedPhone != null && mounted) {
      setState(() => _isLoading = true);
      _handleWooCommerceLogin(storedPhone);
    }
  }

  void _startResendTimer() {
    setState(() => _secondsRemaining = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
    }
  }

  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) { _showError("Please enter a valid phone number"); return; }
    if (!phone.startsWith('+')) phone = '+91$phone';

    setState(() { _isLoading = true; _phoneNumber = phone; });
    final result = await _authService.sendOtp(phone);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _otpSent = true);
        _startResendTimer();
      } else {
        _showError(result['message'] ?? "Failed to send OTP");
      }
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) { _showError("Please enter a valid OTP"); return; }
    setState(() => _isLoading = true);
    final result = await _authService.verifyOtp(_phoneNumber, otp);
    if (result['success']) {
      await _handleWooCommerceLogin(_phoneNumber);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(result['message'] ?? "Invalid OTP");
      }
    }
  }

  Future<void> _handleWooCommerceLogin(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('91') && cleanPhone.length > 10) cleanPhone = cleanPhone.substring(2);

    final loginResult = await _customerService.loginCustomer(cleanPhone);
    if (loginResult['success']) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setCustomer(loginResult['customer']);
        _navigateToHome();
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(context, MaterialPageRoute(builder: (context) => SignupPage(initialPhone: cleanPhone)));
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainNavigationPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.headerGradient.withOpacity(0.1))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Suja Creations", style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryStart)),
                const SizedBox(height: 10),
                Text(_otpSent ? "Verify your number" : "Login to your account", style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textSecondary)),
                const SizedBox(height: 50),
                if (!_otpSent) ...[
                  CustomTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  GradientButton(text: "Send OTP", onPressed: _isLoading ? null : _sendOtp),
                ] else ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      counterText: "",
                      hintText: "000000",
                      hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey.shade300),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => setState(() => _otpSent = false), child: Text("Change Phone", style: GoogleFonts.poppins(color: AppColors.textLight))),
                      TextButton(onPressed: (_isLoading || _secondsRemaining > 0) ? null : _sendOtp, child: Text(_secondsRemaining > 0 ? "Resend in ${_secondsRemaining}s" : "Resend OTP", style: GoogleFonts.poppins(color: _secondsRemaining > 0 ? AppColors.textLight : AppColors.primaryStart, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 30),
                  GradientButton(text: "Verify OTP", onPressed: _isLoading ? null : _verifyOtp),
                ],
                if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: CircularProgressIndicator())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
