import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tracking_data.dart';

class TrackingService {
  final String baseUrl = "https://sujacreation.com"; // Matches WooCommerceApi

  Future<TrackingData?> getTrackingInfo(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/wp-json/suja/v1/track-order/$orderId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if tracking exists
        if (data['status_code'] == 'no_tracking') {
          return null;
        }
        
        return TrackingData.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching tracking info: $e");
      return null;
    }
  }

}
