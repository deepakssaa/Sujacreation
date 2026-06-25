import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';

class AuthService {
  static const String baseUrl = AppConfig.authBaseUrl;

  /// Send OTP to the provided phone number via Twilio Verify
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP sent successfully'};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to send OTP'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Verify the OTP code for the provided phone number
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp_code': otpCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'verified') {
        // Store verified phone number for persistence
        await _saveVerifiedPhone(phoneNumber);
        return {'success': true, 'message': 'Verification successful'};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Invalid OTP code'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Store verified phone locally
  Future<void> _saveVerifiedPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('verified_phone', phone);
  }

  /// Get stored verified phone
  Future<String?> getStoredPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('verified_phone');
  }

  /// Clear stored phone on logout
  Future<void> clearStoredPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('verified_phone');
  }
}
