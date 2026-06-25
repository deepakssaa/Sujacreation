class RazorpayPaymentRequest {
  final int amount; // Amount in paise (e.g., 50000 = ₹500.00)
  final String email;
  final String contact;
  final String name;
  String? orderId; // Will be set after calling backend
  final List<Map<String, dynamic>> cartItems; // Items for inventory locking
  final String userId;

  RazorpayPaymentRequest({
    required this.amount,
    required this.email,
    required this.contact,
    required this.name,
    this.orderId,
    this.cartItems = const [],
    this.userId = "",
  });
}
