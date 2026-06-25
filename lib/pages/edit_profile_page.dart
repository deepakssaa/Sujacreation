import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../services/user_provider.dart';
import '../services/woocommerce_customer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _customerService = WooCommerceCustomerService();
  bool _isLoading = false;

  late TextEditingController _fNameController;
  late TextEditingController _lNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentCustomer;
    _fNameController = TextEditingController(text: user?.firstName);
    _lNameController = TextEditingController(text: user?.lastName);
    _phoneController = TextEditingController(text: user?.billing.phone);
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentCustomer = userProvider.currentCustomer;

    if (currentCustomer == null || currentCustomer.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User data not found.")));
      return;
    }

    setState(() => _isLoading = true);

    final updatedBilling = CustomerBilling(
      firstName: _fNameController.text.trim(),
      lastName: _lNameController.text.trim(),
      address1: currentCustomer.billing.address1,
      address2: currentCustomer.billing.address2,
      city: currentCustomer.billing.city,
      state: currentCustomer.billing.state,
      postcode: currentCustomer.billing.postcode,
      country: currentCustomer.billing.country,
      email: currentCustomer.billing.email,
      phone: _phoneController.text.trim(),
    );

    final updatedShipping = CustomerShipping(
      firstName: _fNameController.text.trim(),
      lastName: _lNameController.text.trim(),
      address1: currentCustomer.shipping.address1,
      address2: currentCustomer.shipping.address2,
      city: currentCustomer.shipping.city,
      state: currentCustomer.shipping.state,
      postcode: currentCustomer.shipping.postcode,
      country: currentCustomer.shipping.country,
    );

    final updatedCustomer = Customer(
      id: currentCustomer.id,
      email: currentCustomer.email,
      firstName: _fNameController.text.trim(),
      lastName: _lNameController.text.trim(),
      username: currentCustomer.username, 
      billing: updatedBilling,
      shipping: updatedShipping,
    );

    final success = await _customerService.updateCustomer(currentCustomer.id!, updatedCustomer);

    setState(() => _isLoading = false);

    if (success) {
      userProvider.setCustomer(updatedCustomer);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile.")));
    }
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
                      Text("Edit Profile", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(controller: _fNameController, label: "First Name", icon: Icons.person_rounded),
                    CustomTextField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline_rounded),
                    CustomTextField(controller: _phoneController, label: "Mobile Number", icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                    const SizedBox(height: 30),
                    GradientButton(
                      text: "Save Changes",
                      onPressed: _isLoading ? null : _updateProfile,
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text("Updating profile, please wait...", style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
