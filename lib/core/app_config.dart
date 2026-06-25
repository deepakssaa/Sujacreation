import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AppConfig centralizes all API keys and configuration settings.
/// These are now fetched from the server on startup for better security.
class AppConfig {
  static const String baseUrl = "https://sujacreation.com";

  // Configuration values (now empty by default for security)
  static String wcConsumerKey = ""; 
  static String wcConsumerSecret = ""; 
  static String razorpayKeyId = ""; 
  static String razorpayCompanyName = "Suja Creations";

  // Twilio / Auth Endpoints
  static const String authBaseUrl = "$baseUrl/wp-json/suja/v1";

  /// Fetch configuration from the server-side endpoint.
  /// Throws an Exception if fetching fails to prevent the app from running without valid keys.
  static Future<void> initialize() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/wp-json/suja/v1/app-config"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Validate that we actually got keys
        if (data['wc_consumer_key'] == null || data['wc_consumer_secret'] == null) {
          throw Exception("Invalid configuration data received from server.");
        }

        wcConsumerKey = data['wc_consumer_key'];
        wcConsumerSecret = data['wc_consumer_secret'];
        razorpayKeyId = data['razorpay_key_id'] ?? razorpayKeyId;
        razorpayCompanyName = data['razorpay_company_name'] ?? razorpayCompanyName;
        
        debugPrint("[SujaCreations] Config fetched successfully from server.");
      } else {
        throw Exception("Failed to fetch config. Server returned status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("[SujaCreations] Critical Error fetching server config: $e");
      rethrow; // Re-throw to be handled in main.dart
    }
  }

  // Logging utility
  static void log(String message) {
    if (kDebugMode) {
      debugPrint("[SujaCreations] $message");
    }
  }
}
