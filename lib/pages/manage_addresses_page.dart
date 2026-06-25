import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/address_provider.dart';
import '../services/user_provider.dart';
import '../models/address.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';

class ManageAddressesPage extends StatefulWidget {
  const ManageAddressesPage({super.key});

  @override
  State<ManageAddressesPage> createState() => _ManageAddressesPageState();
}

class _ManageAddressesPageState extends State<ManageAddressesPage> {
  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentCustomer;
    Provider.of<AddressProvider>(context, listen: false).loadAddresses(user);
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
                      Text("My Addresses", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Consumer<AddressProvider>(
            builder: (context, addressProvider, child) {
              final addresses = addressProvider.addresses;
              if (addresses.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 80, color: AppColors.primaryStart.withOpacity(0.2)),
                        const SizedBox(height: 20),
                        Text("No addresses saved yet", style: GoogleFonts.poppins(color: AppColors.textLight)),
                        const SizedBox(height: 30),
                        GradientButton(
                          text: "Add New Address",
                          width: 200,
                          onPressed: () => _showAddressDialog(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final addr = addresses[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          border: addr.isDefault ? Border.all(color: AppColors.primaryStart.withOpacity(0.3), width: 1.5) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.home_outlined, color: AppColors.primaryStart, size: 20),
                                    const SizedBox(width: 10),
                                    Text(addr.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                if (addr.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Text("DEFAULT", style: GoogleFonts.poppins(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const Divider(height: 30),
                            Text("${addr.firstName} ${addr.lastName}", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${addr.address1}, ${addr.address2}", style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                            Text("${addr.city}, ${addr.state} - ${addr.postcode}", style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 10),
                            Text("Phone: ${addr.phone}", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 12)),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _addressAction(Icons.edit_outlined, "Edit", Colors.blue, () => _showAddressDialog(context, address: addr)),
                                if (addr.id != 'default') ...[
                                  const SizedBox(width: 20),
                                  _addressAction(Icons.delete_outline, "Delete", AppColors.error, () => addressProvider.deleteAddress(addr.id)),
                                ] else ...[
                                  const SizedBox(width: 15),
                                  Text("Cannot be deleted", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 11, fontStyle: FontStyle.italic)),
                                ],
                                if (!addr.isDefault) ...[
                                  const SizedBox(width: 20),
                                  _addressAction(Icons.check_circle_outline, "Set Default", AppColors.success, () => addressProvider.setDefaultAddress(addr.id)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: addresses.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddressDialog(context),
        backgroundColor: AppColors.primaryStart,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _addressAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context, {Address? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: AddressBottomSheet(address: address),
        ),
      ),
    );
  }
}

class AddressBottomSheet extends StatefulWidget {
  final Address? address;
  const AddressBottomSheet({super.key, this.address});

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedState = "Tamil Nadu";
  bool _isDefault = false;

  final List<String> _indianStates = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Puducherry", "Delhi", "Chandigarh", "Dadra and Nagar Haveli", "Daman and Diu", "Lakshadweep", "Andaman and Nicobar Islands", "Ladakh", "Jammu and Kashmir"];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final addr = widget.address!;
      _nameController.text = addr.name;
      _fNameController.text = addr.firstName;
      _lNameController.text = addr.lastName;
      _address1Controller.text = addr.address1;
      _address2Controller.text = addr.address2;
      _cityController.text = addr.city;
      _postcodeController.text = addr.postcode;
      _phoneController.text = addr.phone;
      _emailController.text = addr.email;

      if (_indianStates.contains(addr.state)) {
        _selectedState = addr.state;
      } else {
        const stateMap = {
          "AP": "Andhra Pradesh", "AR": "Arunachal Pradesh", "AS": "Assam", 
          "BR": "Bihar", "CG": "Chhattisgarh", "GA": "Goa", "GJ": "Gujarat", 
          "HR": "Haryana", "HP": "Himachal Pradesh", "JH": "Jharkhand", 
          "KA": "Karnataka", "KL": "Kerala", "MP": "Madhya Pradesh", 
          "MH": "Maharashtra", "MN": "Manipur", "ML": "Meghalaya", 
          "MZ": "Mizoram", "NL": "Nagaland", "OD": "Odisha", "PB": "Punjab", 
          "RJ": "Rajasthan", "SK": "Sikkim", "TN": "Tamil Nadu", "TS": "Telangana",
          "TG": "Telangana", "TR": "Tripura", "UP": "Uttar Pradesh", 
          "UK": "Uttarakhand", "WB": "West Bengal", "AN": "Andaman and Nicobar Islands",
          "CH": "Chandigarh", "DN": "Dadra and Nagar Haveli", "DD": "Daman and Diu",
          "DL": "Delhi", "JK": "Jammu and Kashmir", "LA": "Ladakh", 
          "LD": "Lakshadweep", "PY": "Puducherry"
        };
        _selectedState = stateMap[addr.state] ?? "Tamil Nadu";
      }

      _isDefault = addr.isDefault;
    } else {
      final user = Provider.of<UserProvider>(context, listen: false).currentCustomer;
      if (user != null) {
        _fNameController.text = user.firstName;
        _lNameController.text = user.lastName;
        _emailController.text = user.email;
        _phoneController.text = user.billing.phone;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 25),
            Text(widget.address == null ? "Add New Address" : "Edit Address", style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            CustomTextField(controller: _nameController, label: "Address Alias (e.g. Home)", icon: Icons.bookmark_outline),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _fNameController, label: "First Name", icon: Icons.person_outline)),
                const SizedBox(width: 15),
                Expanded(child: CustomTextField(controller: _lNameController, label: "Last Name", icon: Icons.person_outline)),
              ],
            ),
            CustomTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
            CustomTextField(controller: _address1Controller, label: "House No, Street", icon: Icons.location_on_outlined),
            CustomTextField(controller: _address2Controller, label: "Area, Landmark", icon: Icons.map_outlined, validator: (v) => null),
            Row(
              children: [
                Expanded(child: CustomTextField(controller: _cityController, label: "City", icon: Icons.location_city_outlined)),
                const SizedBox(width: 15),
                Expanded(child: CustomTextField(controller: _postcodeController, label: "Pincode", icon: Icons.pin_drop_outlined, keyboardType: TextInputType.number)),
              ],
            ),
            const Text("State", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              items: _indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _selectedState = val!),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text("Set as Default Address", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val),
              activeColor: AppColors.primaryStart,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 30),
            GradientButton(text: "Save Address", onPressed: _save),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final addr = Address(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        firstName: _fNameController.text.trim(),
        lastName: _lNameController.text.trim(),
        address1: _address1Controller.text.trim(),
        address2: _address2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState,
        postcode: _postcodeController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        isDefault: _isDefault,
      );
      final provider = Provider.of<AddressProvider>(context, listen: false);
      if (widget.address == null) { provider.addAddress(addr); } else { provider.updateAddress(addr); }
      Navigator.pop(context);
    }
  }
}
