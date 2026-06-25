import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../services/user_provider.dart';
import '../services/woocommerce_customer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';
import 'main_navigation_page.dart';

class SignupPage extends StatefulWidget {
  final String? initialPhone;
  const SignupPage({super.key, this.initialPhone});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = WooCommerceCustomerService();
  bool _isLoading = false;

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _passwordController = TextEditingController(text: "123456");
  final _cityController = TextEditingController();
  final _referralController = TextEditingController();

  String _selectedState = "Tamil Nadu";
  bool? _isReferralValid;
  String _referrerName = '';
  bool _isValidatingReferral = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) _phoneController.text = widget.initialPhone!;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fNameController.dispose();
    _lNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onReferralChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    if (val.trim().isEmpty) {
      setState(() {
        _isReferralValid = null;
        _referrerName = '';
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _validateReferral(val.trim());
    });
  }

  Future<void> _validateReferral(String code) async {
    setState(() => _isValidatingReferral = true);
    final res = await _customerService.validateReferralCode(code);
    if (mounted) {
      setState(() {
        _isValidatingReferral = false;
        _isReferralValid = res['valid'] ?? false;
        _referrerName = res['referrer_name'] ?? '';
      });
    }
  }

  final List<String> _indianStates = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Puducherry", "Delhi", "Chandigarh", "Dadra and Nagar Haveli", "Daman and Diu", "Lakshadweep", "Andaman and Nicobar Islands", "Ladakh", "Jammu and Kashmir"];

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final billing = CustomerBilling(firstName: _fNameController.text.trim(), lastName: _lNameController.text.trim(), address1: _addressController.text.trim(), city: _cityController.text.trim(), state: _selectedState, postcode: _postcodeController.text.trim(), country: "IN", email: _emailController.text.trim(), phone: _phoneController.text.trim());
    final shipping = CustomerShipping(firstName: _fNameController.text.trim(), lastName: _lNameController.text.trim(), address1: _addressController.text.trim(), city: _cityController.text.trim(), state: _selectedState, postcode: _postcodeController.text.trim(), country: "IN");
    
    final metadata = <Map<String, dynamic>>[];
    if (_isReferralValid == true && _referralController.text.trim().isNotEmpty) {
      metadata.add({
        'key': 'suja_referred_by_code',
        'value': _referralController.text.trim().toUpperCase()
      });
    }

    final customer = Customer(
      email: _emailController.text.trim(),
      firstName: _fNameController.text.trim(),
      lastName: _lNameController.text.trim(),
      username: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      billing: billing,
      shipping: shipping,
      metaData: metadata.isNotEmpty ? metadata : null,
    );

    final result = await _customerService.registerCustomer(customer);
    setState(() => _isLoading = false);

    if (result['success']) {
      Provider.of<UserProvider>(context, listen: false).setCustomer(result['customer']);
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigationPage()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? "Signup failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 25),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                  const SizedBox(width: 15),
                  Text("Create Account", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(25),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Form(key: _formKey, child: Column(children: [
                CustomTextField(controller: _fNameController, label: "First Name", icon: Icons.person_rounded),
                CustomTextField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline_rounded),
                CustomTextField(controller: _emailController, label: "Email", icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
                CustomTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone, readOnly: widget.initialPhone != null),
                CustomTextField(controller: _addressController, label: "Full Address", icon: Icons.home_rounded),
                Row(children: [
                  Expanded(child: CustomTextField(controller: _cityController, label: "City", icon: Icons.location_city_rounded)),
                  const SizedBox(width: 15),
                  Expanded(child: CustomTextField(controller: _postcodeController, label: "Pincode", icon: Icons.pin_drop_rounded, keyboardType: TextInputType.number)),
                ]),
                const Text("State", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                  onChanged: (val) => setState(() => _selectedState = val!),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _referralController,
                  label: "Referral Code (Optional)",
                  icon: Icons.card_giftcard_rounded,
                  onChanged: _onReferralChanged,
                ),
                if (_isValidatingReferral)
                  const Padding(
                    padding: EdgeInsets.only(left: 10, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_isReferralValid == true)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          "Referred by $_referrerName",
                          style: GoogleFonts.poppins(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else if (_isReferralValid == false)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: AppColors.error, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          "Invalid referral code",
                          style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                GradientButton(text: "Complete Signup", onPressed: _isLoading ? null : _signup),
                if (_isLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator()),
                const SizedBox(height: 50),
              ])),
            ])),
          ),
        ],
      ),
    );
  }
}
