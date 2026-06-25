import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../core/app_config.dart';

class WooCommerceApi {
  final String _baseUrl = AppConfig.baseUrl;
  final String _consumerKey = AppConfig.wcConsumerKey;
  final String _consumerSecret = AppConfig.wcConsumerSecret;

  String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';

  /// Fetch products with advanced filters
  Future<List<Product>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    int? categoryId,
    String orderBy = 'date',
    String order = 'desc',
  }) async {
    // Only fetch parent products (no variations in the main list)
    String query = "?status=publish&stock_status=instock&parent=0&page=$page&per_page=$perPage&orderby=$orderBy&order=$order";
    
    if (search != null && search.isNotEmpty) {
      query += "&search=${Uri.encodeComponent(search)}";
    }
    
    if (categoryId != null && categoryId != 0) {
      query += "&category=$categoryId";
    }

    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/products$query");

    final response = await http.get(
      url,
      headers: {"Authorization": _basicAuth, "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Server error ${response.statusCode}. Please try again later.");
    }
  }

  /// Fetch a single product by ID
  Future<Product> fetchProductById(int productId) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/products/$productId");

    final response = await http.get(
      url,
      headers: {"Authorization": _basicAuth, "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Product not found");
    }
  }

  /// Fetch variations for a specific product
  Future<List<ProductVariation>> fetchVariations(int productId) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/products/$productId/variations?per_page=100");

    final response = await http.get(
      url,
      headers: {"Authorization": _basicAuth, "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => ProductVariation.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  /// Fetch all categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/products/categories?hide_empty=false&per_page=100");

    final response = await http.get(
      url,
      headers: {"Authorization": _basicAuth, "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => {
        'id': e['id'],
        'name': e['name'],
        'image': e['image'] != null ? e['image']['src'] : '',
        'count': e['count'],
      }).toList();
    } else {
      return [];
    }
  }

  /// Fetch products by category (for recommendations)
  Future<List<Product>> fetchRelatedProducts(
      {required List<int> categoryIds,
      required int excludeId,
      int limit = 5}) async {
    if (categoryIds.isEmpty) return [];

    final url = Uri.parse(
      "$_baseUrl/wp-json/wc/v3/products"
      "?status=publish"
      "&stock_status=instock"
      "&category=${categoryIds.join(',')}"
      "&exclude=$excludeId"
      "&per_page=$limit",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": _basicAuth, "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  /// Create a new order in WooCommerce
  Future<bool> createOrder({
    required List<Map<String, dynamic>> lineItems,
    required double total,
    required String paymentMethod,
    required String transactionId,
  }) async {
    final url = Uri.parse("$_baseUrl/wp-json/wc/v3/orders");

    final body = jsonEncode({
      "payment_method": paymentMethod,
      "payment_method_title": "Razorpay",
      "set_paid": true,
      "transaction_id": transactionId,
      "line_items": lineItems,
      // You can add billing/shipping info here if needed
      "billing": {
        "first_name": "Test",
        "last_name": "User",
        "address_1": "123 Test St",
        "city": "Chennai",
        "state": "TN",
        "postcode": "600001",
        "country": "IN",
        "email": "test@suja.com",
        "phone": "9876543210"
      },
      "shipping": {
        "first_name": "Test",
        "last_name": "User",
        "address_1": "123 Test St",
        "city": "Chennai",
        "state": "TN",
        "postcode": "600001",
        "country": "IN",
        "email": "test@suja.com",
        "phone": "9876543210"
      }
    });

    final response = await http.post(
      url,
      headers: {
        "Authorization": _basicAuth,
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      debugPrint("WooCommerce Create Order Error: ${response.body}");
      return false;
    }
  }

  /// Fetch orders for a specific customer
  Future<List<dynamic>> fetchOrders({int? customerId}) async {
    if (customerId == null || customerId <= 0) {
      return [];
    }

    final url = Uri.parse(
      "$_baseUrl/wp-json/wc/v3/orders"
      "?customer=$customerId"
      "&orderby=date"
      "&order=desc"
      "&per_page=50",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": _basicAuth,
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> orders = jsonDecode(response.body);

      orders.sort((a, b) {
        final aDate = DateTime.tryParse(a['date_created'] ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b['date_created'] ?? '') ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return orders;
    } else {
      throw Exception(
        "Failed to fetch orders: ${response.statusCode} ${response.body}",
      );
    }
  }
}
