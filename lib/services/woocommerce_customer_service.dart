import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../core/app_config.dart';

class WooCommerceCustomerService {
  final String _baseUrl = AppConfig.baseUrl;
  final String _consumerKey = AppConfig.wcConsumerKey;
  final String _consumerSecret = AppConfig.wcConsumerSecret;

  String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';

  /// Register a new customer
  Future<Map<String, dynamic>> registerCustomer(Customer customer) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/customers");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(customer.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'customer': Customer.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Register Customer Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  /// "Login" - Search customer by username (phone)
  /// Note: REST API doesn't support password verification directly.
  /// This implementation checks if the customer exists by username.
  Future<Map<String, dynamic>> loginCustomer(String phone) async {
    // We use our custom endpoint because standard WC search doesn't look into billing_phone reliably
    final url = Uri.parse("$_baseUrl/wp-json/suja/v1/get-customer-by-phone");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"phone": phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['id'] != null && data['id'] != 0) {
        return {'success': true, 'customer': Customer.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'User not found or invalid phone number'
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Login Customer Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update customer details
  Future<bool> updateCustomer(int id, Customer customer) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/customers/$id");

    try {
      final Map<String, dynamic> updateData = {
        'first_name': customer.firstName,
        'last_name': customer.lastName,
        'billing': {
          ...customer.billing.toJson(),
          'first_name': customer.firstName,
          'last_name': customer.lastName,
          'phone': customer.billing.phone,
        },
        'shipping': {
          ...customer.shipping.toJson(),
          'first_name': customer.firstName,
          'last_name': customer.lastName,
        },
      };

      final response = await http
          .put(
            url,
            headers: {
              "Authorization": _basicAuth,
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
            body: jsonEncode(updateData),
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        debugPrint("Update Customer Status: ${response.statusCode}");
        debugPrint("Update Customer Body: ${response.body}");
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Update Customer Error: $e");
      }
      return false;
    }
  }

  /// Send OTP to user's phone
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final url = Uri.parse("$_baseUrl/wp-json/suja/v1/send-otp");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"phone": phone}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint("Send OTP Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final url = Uri.parse("$_baseUrl/wp-json/suja/v1/verify-otp");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"phone": phone, "otp": otp}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint("Verify OTP Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Sync saved addresses to customer's meta_data
  Future<bool> updateCustomerAddresses(int id, String addressesJson) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/customers/$id");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": _basicAuth,
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'meta_data': [
            {'key': 'suja_saved_addresses', 'value': addressesJson}
          ]
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint("Update Addresses Error: $e");
      return false;
    }
  }

  /// Validate referral code
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    final url = Uri.parse("$_baseUrl/wp-json/suja/v1/validate-referral");

    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"code": code}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint("Validate Referral Error: $e");
      return {'valid': false, 'message': e.toString()};
    }
  }

  /// Get referral dashboard info
  Future<Map<String, dynamic>> getReferralInfo(int customerId) async {
    final url = Uri.parse("$_baseUrl/wp-json/suja/v1/referral-info?customer_id=$customerId");

    try {
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load referral details'};
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Get Referral Info Error: $e");
      return {'success': false, 'message': e.toString()};
    }
  }
}
