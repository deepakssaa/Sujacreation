import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'razorpay_constants.dart';
import 'razorpay_model.dart';

class RazorpayApiClient {
  /// Lock inventory for the items in the cart
  Future<bool> lockInventory(RazorpayPaymentRequest request) async {
    if (request.cartItems.isEmpty) return true; // Nothing to lock

    try {
      final response = await http.post(
        Uri.parse(RazorpayConstants.lockInventoryEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': request.userId,
          'items': request.cartItems,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint("Error locking inventory: \$e");
      return false;
    }
  }

  /// Create an order on the backend to get a Razorpay order_id
  Future<String?> createOrder(RazorpayPaymentRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(RazorpayConstants.createOrderEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': request.amount,
          'user_id': request.userId,
          'receipt': 'rcptid_\${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // Razorpay order id
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint("Error creating order: \$e");
      return null;
    }
  }

  /// Verify the payment signature on the backend
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(RazorpayConstants.verifyPaymentEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payment_id': paymentId,
          'order_id': orderId,
          'signature': signature,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) debugPrint("Error verifying payment: \$e");
      return false;
    }
  }
}
