import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_request.dart';
import '../models/order_response.dart';
import '../core/app_config.dart';

class WooCommerceOrderService {
  final String _baseUrl = AppConfig.baseUrl;
  final String _consumerKey = AppConfig.wcConsumerKey;
  final String _consumerSecret = AppConfig.wcConsumerSecret;

  Future<OrderResponse> createOrder(OrderRequest request) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/orders");
    final basicAuth =
        'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';

    final body = jsonEncode(request.toJson());

    if (kDebugMode) {
      debugPrint("POST: $url");
      debugPrint("Payload: $body");
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": basicAuth,
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: body,
      );

      final String rawBody = response.body;

      if (kDebugMode) {
        debugPrint("Response Status Code: ${response.statusCode}");
        debugPrint("Response Body: $rawBody");
      }

      final Map<String, dynamic> data = jsonDecode(rawBody);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return OrderResponse.fromJson(data, response.statusCode, rawBody);
      } else {
        // Handle 400, 401, 403, 500
        String errorMessage = "Failed to place order.";
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        }

        switch (response.statusCode) {
          case 400:
            errorMessage = "Validation error: $errorMessage";
            break;
          case 401:
            errorMessage = "Authentication error: $errorMessage";
            break;
          case 403:
            errorMessage = "Permission error: $errorMessage";
            break;
          case 500:
            errorMessage = "Server error: $errorMessage";
            break;
        }

        return OrderResponse.fromJson(data, response.statusCode, rawBody);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("WooCommerce Service Error: $e");
      }
      return OrderResponse.error("Error connecting to server: $e");
    }
  }
}
