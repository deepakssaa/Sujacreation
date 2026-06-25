abstract class RazorpayCallbacks {
  void onPaymentSuccess(String paymentId);
  void onPaymentError(String message);
  void onExternalWallet(String walletName);
}
