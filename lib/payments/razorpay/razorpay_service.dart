import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_constants.dart';
import 'razorpay_model.dart';
import 'razorpay_callbacks.dart';
import 'razorpay_api_client.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final RazorpayCallbacks callbacks;
  final RazorpayApiClient apiClient = RazorpayApiClient();
  
  int _retryCount = 0;
  static const int maxRetries = 3;
  
  // Store request to use for retries
  RazorpayPaymentRequest? _currentRequest;

  RazorpayService(this.callbacks) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Initiates payment by first locking inventory, then creating an order, then opening Razorpay
  Future<void> openPayment(RazorpayPaymentRequest request) async {
    _currentRequest = request;
    
    // 1. Lock Inventory first
    final locked = await apiClient.lockInventory(request);
    if (!locked) {
      callbacks.onPaymentError("Failed to reserve items in cart.");
      return;
    }

    // 2. Create Order on backend
    final orderId = await apiClient.createOrder(request);
    if (orderId == null) {
      callbacks.onPaymentError("Failed to create order on server.");
      return;
    }
    
    request.orderId = orderId; // Save for later verification

    // 3. Open Razorpay Interface
    var options = {
      'key': RazorpayConstants.keyId,
      'amount': request.amount,
      'order_id': orderId,
      'name': RazorpayConstants.companyName,
      'description': RazorpayConstants.description,
      'prefill': {
        'contact': request.contact,
        'email': request.email
      }
    };
    
    _razorpay.open(options);
  }
  
  /// Retry payment without recreating order (using same order_id)
  void retryPayment() {
    if (_currentRequest == null || _currentRequest!.orderId == null) {
      callbacks.onPaymentError("No payment to retry.");
      return;
    }
    
    if (_retryCount >= maxRetries) {
      callbacks.onPaymentError("Maximum retry attempts reached. Order cancelled.");
      return;
    }
    
    _retryCount++;
    
    var options = {
      'key': RazorpayConstants.keyId,
      'amount': _currentRequest!.amount,
      'order_id': _currentRequest!.orderId,
      'name': RazorpayConstants.companyName,
      'description': RazorpayConstants.description,
      'prefill': {
        'contact': _currentRequest!.contact,
        'email': _currentRequest!.email
      }
    };
    
    _razorpay.open(options);
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    // 4. Verify payment via Backend
    if (response.paymentId == null || response.orderId == null || response.signature == null) {
      callbacks.onPaymentError("Missing verification data from Razorpay.");
      return;
    }
    
    final isValid = await apiClient.verifyPayment(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
    
    if (isValid) {
      callbacks.onPaymentSuccess(response.paymentId!);
      _retryCount = 0; // Reset on success
    } else {
      callbacks.onPaymentError("Payment signature verification failed. Possible fraud attempt.");
    }
  }

  void _handleError(PaymentFailureResponse response) {
    String errorMsg = response.message ?? "Payment Failed";
    // Allow UI to decide if they want to call `retryPayment()`
    callbacks.onPaymentError("\$errorMsg\\nRetry attempt: \$_retryCount/\$maxRetries");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    callbacks.onExternalWallet(response.walletName ?? "");
  }

  void dispose() {
    _razorpay.clear();
  }
}
