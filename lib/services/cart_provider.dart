import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'notification_service.dart';

class CartItem {
  final Product product;
  int quantity;
  final Map<String, String> selectedAttributes;
  final int? variationId;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedAttributes = const {},
    this.variationId,
  });

  String get key => variationId != null ? "v-$variationId" : "p-${product.id}";

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selectedAttributes': selectedAttributes,
      'variationId': variationId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      selectedAttributes: Map<String, String>.from(json['selectedAttributes'] ?? {}),
      variationId: json['variationId'] as int?,
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  int? _userId;

  int? get userId => _userId;

  String get _storageKey => _userId != null ? 'cart_$_userId' : 'cart_guest';

  // We don't call loadCart in constructor anymore if using ProxyProvider, 
  // or we call it with a default guest state.
  CartProvider() {
    // We don't call loadCart here because updateUser will be called 
    // immediately by ProxyProvider which will handle the initial load.
  }

  /// Called by MultiProvider/ProxyProvider when user state changes
  void updateUser(int? newUserId) {
    if (_userId == newUserId && _items.isNotEmpty) return;

    final int? oldUserId = _userId;
    _userId = newUserId;

    if (oldUserId == null && newUserId != null && _items.isNotEmpty) {
      // Transition: Guest -> Logged In (Merge guest items into user account)
      _mergeGuestCartIntoUser(newUserId);
    } else {
      // Regular load for User or Guest
      loadCart();
    }
  }

  Future<void> _mergeGuestCartIntoUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Current items in memory are the guest items
    Map<String, CartItem> guestItems = Map.from(_items);
    
    // 2. Clear memory and load the user's existing cart from storage
    final String userKey = 'cart_$userId';
    Map<String, CartItem> userItems = {};
    
    if (prefs.containsKey(userKey)) {
      final String? userData = prefs.getString(userKey);
      if (userData != null) {
        try {
          final Map<String, dynamic> decodedData = jsonDecode(userData);
          decodedData.forEach((key, value) {
            userItems[key] = CartItem.fromJson(value as Map<String, dynamic>);
          });
        } catch (e) {
          debugPrint("Error decoding user cart during merge: $e");
        }
      }
    }

    // 3. Merge guest items into user items
    guestItems.forEach((key, guestItem) {
      if (userItems.containsKey(key)) {
        userItems[key]!.quantity += guestItem.quantity;
      } else {
        userItems[key] = guestItem;
      }
    });

    // 4. Update memory with merged items and save to user-specific storage
    _items = userItems;
    await saveCart(); // Saves to 'cart_$userId'

    // 5. Clean up guest cart from storage
    await prefs.remove('cart_guest');
    
    notifyListeners();
  }

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      final price = double.tryParse(cartItem.product.price) ?? 0.0;
      total += price * cartItem.quantity;
    });
    return total;
  }

  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String cartData = jsonEncode(
      _items.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_storageKey, cartData);
    
    _updateCartAbandonmentNotification();
  }

  void _updateCartAbandonmentNotification() {
    debugPrint("CART DEBUG: _updateCartAbandonmentNotification called. Cart items count: ${_items.length}");
    final ns = NotificationService();
    if (_items.isEmpty) {
      debugPrint("CART DEBUG: Cart is empty, canceling abandonment notification.");
      ns.cancelCartAbandonmentNotification();
    } else {
      debugPrint("CART DEBUG: Cart has items, scheduling abandonment notification for 1 minute.");
      
      // Build cart details for the notification body
      List<String> itemNames = _items.values.map((item) => "${item.quantity}x ${item.product.name}").toList();
      String cartDetails = itemNames.join(", ");
      if (cartDetails.length > 50) {
        cartDetails = "${cartDetails.substring(0, 47)}...";
      }
      
      ns.scheduleCartAbandonmentNotification(
        cartDetails,
        300, // 300 minutes = 5 hours
      );
    }
  }

  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the dynamic storage key
    if (!prefs.containsKey(_storageKey)) {
      _items = {};
      notifyListeners();
      return;
    }

    final String? cartData = prefs.getString(_storageKey);
    if (cartData != null) {
      try {
        final Map<String, dynamic> decodedData = jsonDecode(cartData);
        final Map<String, CartItem> loadedItems = {};
        decodedData.forEach((key, value) {
          loadedItems[key] = CartItem.fromJson(value as Map<String, dynamic>);
        });
        _items = loadedItems;
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading cart: $e");
      }
    }
  }

  void addItem(Product product, {int? variationId, Map<String, String> attributes = const {}}) {
    final item = CartItem(
      product: product, 
      variationId: variationId, 
      selectedAttributes: attributes,
    );
    final key = item.key;

    if (_items.containsKey(key)) {
      _items.update(
        key,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + 1,
          selectedAttributes: existingItem.selectedAttributes,
          variationId: existingItem.variationId,
        ),
      );
    } else {
      _items[key] = item;
    }
    saveCart();
    notifyListeners();
  }

  void removeItem(String key) {
    _items.remove(key);
    saveCart();
    notifyListeners();
  }

  void removeSingleItem(String key) {
    if (!_items.containsKey(key)) return;
    if (_items[key]!.quantity > 1) {
      _items.update(
        key,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity - 1,
          selectedAttributes: existingItem.selectedAttributes,
          variationId: existingItem.variationId,
        ),
      );
    } else {
      _items.remove(key);
    }
    saveCart();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    saveCart();
    notifyListeners();
  }
}
