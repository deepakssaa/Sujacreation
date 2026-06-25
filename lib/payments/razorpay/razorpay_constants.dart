import '../../core/app_config.dart';

class RazorpayConstants {
  static String get keyId => AppConfig.razorpayKeyId;
  static String get companyName => AppConfig.razorpayCompanyName;
  static const String description = "Jewellery Purchase";

  // Backend API Endpoints (Update this with your actual Supabase URL)
  static const String backendBaseUrl =
      "https://yourproject.supabase.co/functions/v1";
  static const String createOrderEndpoint = "\$backendBaseUrl/create-order";
  static const String verifyPaymentEndpoint = "\$backendBaseUrl/verify-payment";
  static const String lockInventoryEndpoint = "\$backendBaseUrl/lock-inventory";
}
