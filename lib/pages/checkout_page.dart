import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/cart_provider.dart';
import '../services/user_provider.dart';
import '../services/woocommerce_order_service.dart';
import '../services/address_provider.dart';
import '../models/order_request.dart';
import '../models/order_response.dart';
import '../models/address.dart';
import '../payments/razorpay/razorpay_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = WooCommerceOrderService();
  late Razorpay _razorpay;
  bool _isLoading = false;

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _postcodeController = TextEditingController();
  final _countryController = TextEditingController(text: "IN");
  final _cityController = TextEditingController();

  String _selectedState = "Tamil Nadu";

  final List<String> _indianStates = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Puducherry", "Delhi", "Chandigarh", "Dadra and Nagar Haveli", "Daman and Diu", "Lakshadweep", "Andaman and Nicobar Islands", "Ladakh", "Jammu and Kashmir"];

  OrderRequest? _pendingOrder;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final user = Provider.of<UserProvider>(context, listen: false).currentCustomer;
    // Managed by ProxyProvider

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      if (addressProvider.selectedAddress != null) {
        _applyAddress(addressProvider.selectedAddress!);
      } else if (user != null) {
        _applyCustomerData(user);
      }
    });
  }

  void _applyAddress(Address addr) {
    setState(() {
      _fNameController.text = addr.firstName;
      _lNameController.text = addr.lastName;
      _emailController.text = addr.email;
      _phoneController.text = addr.phone;
      _address1Controller.text = addr.address1;
      _address2Controller.text = addr.address2;
      _postcodeController.text = addr.postcode;
      if (_indianStates.contains(addr.state)) {
        _selectedState = addr.state;
      } else {
        const stateMap = {"AP": "Andhra Pradesh", "AR": "Arunachal Pradesh", "AS": "Assam", "BR": "Bihar", "CG": "Chhattisgarh", "GA": "Goa", "GJ": "Gujarat", "HR": "Haryana", "HP": "Himachal Pradesh", "JH": "Jharkhand", "KA": "Karnataka", "KL": "Kerala", "MP": "Madhya Pradesh", "MH": "Maharashtra", "MN": "Manipur", "ML": "Meghalaya", "MZ": "Mizoram", "NL": "Nagaland", "OD": "Odisha", "PB": "Punjab", "RJ": "Rajasthan", "SK": "Sikkim", "TN": "Tamil Nadu", "TS": "Telangana", "TG": "Telangana", "TR": "Tripura", "UP": "Uttar Pradesh", "UK": "Uttarakhand", "WB": "West Bengal", "AN": "Andaman and Nicobar Islands", "CH": "Chandigarh", "DN": "Dadra and Nagar Haveli", "DD": "Daman and Diu", "DL": "Delhi", "JK": "Jammu and Kashmir", "LA": "Ladakh", "LD": "Lakshadweep", "PY": "Puducherry"};
        if (stateMap.containsKey(addr.state)) _selectedState = stateMap[addr.state]!;
      }
      _cityController.text = addr.city;
    });
  }

  void _applyCustomerData(dynamic user) {
    setState(() {
      _fNameController.text = user.firstName;
      _lNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.billing.phone.isNotEmpty ? user.billing.phone : user.username;
      _address1Controller.text = user.billing.address1;
      _address2Controller.text = user.billing.address2;
      _postcodeController.text = user.billing.postcode;
      if (_indianStates.contains(user.billing.state)) {
        _selectedState = user.billing.state;
      } else {
        const stateMap = {"AP": "Andhra Pradesh", "AR": "Arunachal Pradesh", "AS": "Assam", "BR": "Bihar", "CG": "Chhattisgarh", "GA": "Goa", "GJ": "Gujarat", "HR": "Haryana", "HP": "Himachal Pradesh", "JH": "Jharkhand", "KA": "Karnataka", "KL": "Kerala", "MP": "Madhya Pradesh", "MH": "Maharashtra", "MN": "Manipur", "ML": "Meghalaya", "MZ": "Mizoram", "NL": "Nagaland", "OD": "Odisha", "PB": "Punjab", "RJ": "Rajasthan", "SK": "Sikkim", "TN": "Tamil Nadu", "TS": "Telangana", "TG": "Telangana", "TR": "Tripura", "UP": "Uttar Pradesh", "UK": "Uttarakhand", "WB": "West Bengal", "AN": "Andaman and Nicobar Islands", "CH": "Chandigarh", "DN": "Dadra and Nagar Haveli", "DD": "Daman and Diu", "DL": "Delhi", "JK": "Jammu and Kashmir", "LA": "Ladakh", "LD": "Lakshadweep", "PY": "Puducherry"};
        if (stateMap.containsKey(user.billing.state)) _selectedState = stateMap[user.billing.state]!;
      }
      _cityController.text = user.billing.city;
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    _fNameController.dispose(); _lNameController.dispose(); _phoneController.dispose();
    _emailController.dispose(); _address1Controller.dispose(); _address2Controller.dispose();
    _postcodeController.dispose(); _cityController.dispose(); _countryController.dispose();
    super.dispose();
  }

  double get _shippingCharge => (_selectedState == "Tamil Nadu" || _selectedState == "Puducherry") ? 0.0 : 100.0;

  void _handlePaymentSuccess(PaymentSuccessResponse response) { if (_pendingOrder != null) _completeWooCommerceOrder(response.paymentId ?? ""); }
  void _handlePaymentError(PaymentFailureResponse response) { setState(() => _isLoading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: AppColors.error)); }
  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    final billing = Billing(firstName: _fNameController.text.trim(), lastName: _lNameController.text.trim(), address1: _address1Controller.text.trim(), address2: _address2Controller.text.trim(), city: _cityController.text.trim(), state: _selectedState, postcode: _postcodeController.text.trim(), country: _countryController.text.trim(), email: _emailController.text.trim(), phone: _phoneController.text.trim());
    final shipping = Shipping(firstName: _fNameController.text.trim(), lastName: _lNameController.text.trim(), address1: _address1Controller.text.trim(), address2: _address2Controller.text.trim(), city: _cityController.text.trim(), state: _selectedState, postcode: _postcodeController.text.trim(), country: _countryController.text.trim());
    final lineItems = cart.items.values.map((item) => LineItem(productId: item.product.id, quantity: item.quantity, variationId: item.variationId)).toList();

    _pendingOrder = OrderRequest(
      paymentMethod: "razorpay", paymentMethodTitle: "Razorpay (Online)", setPaid: true,
      billing: billing, shipping: shipping, lineItems: lineItems,
      customerId: Provider.of<UserProvider>(context, listen: false).currentCustomer?.id,
      shippingLines: [ShippingLine(methodId: _shippingCharge > 0 ? "flat_rate" : "free_shipping", methodTitle: _shippingCharge > 0 ? "Standard Shipping" : "Free Shipping", total: _shippingCharge.toString())],
    );

    final double totalAmount = cart.totalAmount + _shippingCharge;
    var options = {'key': RazorpayConstants.keyId, 'amount': (totalAmount * 100).toInt(), 'name': RazorpayConstants.companyName, 'description': 'Order Payment', 'prefill': {'contact': _phoneController.text.trim(), 'email': _emailController.text.trim()}};
    try { _razorpay.open(options); } catch (e) { debugPrint("Razorpay Error: $e"); }
  }

  Future<void> _completeWooCommerceOrder(String paymentId) async {
    if (_pendingOrder == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _orderService.createOrder(_pendingOrder!);
      if (response.success) {
        Provider.of<CartProvider>(context, listen: false).clear();
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderSuccessPage(orderId: response.id!)));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message ?? "Order failed")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading ? _buildLoading() : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 25),
              decoration: const BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20))),
                    const SizedBox(width: 15),
                    Text("Checkout", style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _buildSavedAddressesSection(),
              const SizedBox(height: 25),
              _buildSectionTitle("Delivery Details"),
              const SizedBox(height: 15),
              _buildDeliveryInfoCard(),
              const SizedBox(height: 25),
              _buildSectionTitle("Contact Details"),
              const SizedBox(height: 15),
              Form(key: _formKey, child: CustomTextField(controller: _phoneController, label: "Phone Number", icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone)),
              const SizedBox(height: 25),
              _buildSectionTitle("Order Items"),
              const SizedBox(height: 15),
              _buildOrderItems(cart),
              const SizedBox(height: 25),
              _buildOrderSummary(cart),
              const SizedBox(height: 30),
              GradientButton(text: "Pay & Place Order", onPressed: _placeOrder),
              const SizedBox(height: 50),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: AppColors.primaryStart), const SizedBox(height: 30), Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text("Verifying your order, please don't close the app...", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)))]));

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary));

  Widget _buildDeliveryInfoCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
    child: Row(children: [
      Icon(Icons.location_on_rounded, color: AppColors.primaryStart, size: 24),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${_fNameController.text} ${_lNameController.text}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text("${_address1Controller.text}, ${_cityController.text}, ${_selectedState} - ${_postcodeController.text}", style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
      ])),
    ]),
  );

  Widget _buildOrderItems(CartProvider cart) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
    child: Column(children: cart.items.values.map((item) => Padding(padding: const EdgeInsets.only(bottom: 15), child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(item.product.images.isNotEmpty ? item.product.images[0] : '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: AppColors.background))),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), Text("${item.quantity} x ₹${item.product.price}", style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 11))])),
      Text("₹${(double.parse(item.product.price) * item.quantity).toStringAsFixed(0)}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
    ]))).toList()),
  );

  Widget _buildOrderSummary(CartProvider cart) {
    final total = cart.totalAmount + _shippingCharge;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryStart.withOpacity(0.1))),
      child: Column(children: [
        _summaryRow("Cart Total", "₹${cart.totalAmount.toStringAsFixed(0)}"),
        _summaryRow("Shipping", _shippingCharge > 0 ? "₹${_shippingCharge.toStringAsFixed(0)}" : "FREE", isFree: _shippingCharge == 0),
        const Divider(height: 30),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Net Amount", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)), Text("₹${total.toStringAsFixed(0)}", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryStart))]),
      ]),
    );
  }

  Widget _summaryRow(String label, String value, {bool isFree = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)), Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: isFree ? Colors.green : AppColors.textPrimary))]));

  Widget _buildSavedAddressesSection() => Consumer<AddressProvider>(builder: (context, provider, _) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (provider.addresses.isNotEmpty) ...[
        _buildSectionTitle("Select Address"),
        const SizedBox(height: 15),
        SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: provider.addresses.length, itemBuilder: (context, index) {
          final addr = provider.addresses[index];
          final isSelected = provider.selectedAddress?.id == addr.id;
          return GestureDetector(onTap: () { provider.selectAddress(addr); _applyAddress(addr); }, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 160, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? AppColors.primaryStart : Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)], border: isSelected ? null : Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(addr.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 13), maxLines: 1), Text(addr.city, style: GoogleFonts.poppins(color: isSelected ? Colors.white70 : AppColors.textLight, fontSize: 11))])));
        })),
      ]
    ]);
  });
}

class OrderSuccessPage extends StatelessWidget {
  final int orderId;
  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 100),
        const SizedBox(height: 30),
        Text("Order Placed!", style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text("Your Order ID #$orderId has been placed successfully.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 50),
        GradientButton(text: "Continue Shopping", onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
      ]))),
    );
  }
}
