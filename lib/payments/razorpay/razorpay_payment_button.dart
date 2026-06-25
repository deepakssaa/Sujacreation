import 'package:flutter/material.dart';
import 'razorpay_service.dart';
import 'razorpay_model.dart';

class RazorpayPaymentButton extends StatefulWidget {
  final RazorpayService service;
  final RazorpayPaymentRequest request;

  const RazorpayPaymentButton({
    Key? key,
    required this.service,
    required this.request,
  }) : super(key: key);

  @override
  _RazorpayPaymentButtonState createState() => _RazorpayPaymentButtonState();
}

class _RazorpayPaymentButtonState extends State<RazorpayPaymentButton> {
  bool _isLoading = false;

  void _handlePress() async {
    setState(() {
      _isLoading = true;
    });

    // We await the async openPayment call
    await widget.service.openPayment(widget.request);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePress,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text("Checkout & Pay"),
    );
  }
}
