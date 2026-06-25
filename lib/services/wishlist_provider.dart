import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class WishlistProvider with ChangeNotifier {
  Map<String, Product> _items = {};
  int? _userId;

  int? get userId => _userId;

  String get _storageKey => _userId != null ? 'wishlist_$_userId' : 'wishlist_guest';

  WishlistProvider() {
    // We don't call loadWishlist here because updateUser will be called 
    // immediately by ProxyProvider which will handle the initial load.
  }

  /// Called by MultiProvider/ProxyProvider when user state changes
  void updateUser(int? newUserId) {
    if (_userId == newUserId && _items.isNotEmpty) return;

    final int? oldUserId = _userId;
    _userId = newUserId;

    if (oldUserId == null && newUserId != null && _items.isNotEmpty) {
      // Transition: Guest -> Logged In (Merge guest items into user account)
      _mergeGuestWishlistIntoUser(newUserId);
    } else {
      // Regular load for User or Guest
      loadWishlist();
    }
  }

  Future<void> _mergeGuestWishlistIntoUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Current items in memory are the guest items
    Map<String, Product> guestItems = Map.from(_items);
    
    // 2. Clear memory and load the user's existing wishlist from storage
    final String userKey = 'wishlist_$userId';
    Map<String, Product> userItems = {};
    
    if (prefs.containsKey(userKey)) {
      final String? userData = prefs.getString(userKey);
      if (userData != null) {
        try {
          final Map<String, dynamic> decodedData = jsonDecode(userData);
          decodedData.forEach((key, value) {
            userItems[key] = Product.fromJson(value as Map<String, dynamic>);
          });
        } catch (e) {
          debugPrint("Error decoding user wishlist during merge: $e");
        }
      }
    }

    // 3. Merge guest items into user items
    guestItems.forEach((key, guestItem) {
      if (!userItems.containsKey(key)) {
        userItems[key] = guestItem;
      }
    });

    // 4. Update memory with merged items and save to user-specific storage
    _items = userItems;
    await saveWishlist(); // Saves to 'wishlist_$userId'

    // 5. Clean up guest wishlist from storage
    await prefs.remove('wishlist_guest');
    
    notifyListeners();
  }

  Map<String, Product> get items => _items;

  int get itemCount => _items.length;

  bool isWishlisted(int productId) {
    return _items.containsKey(productId.toString());
  }

  Future<void> saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final String wishlistData = jsonEncode(
      _items.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_storageKey, wishlistData);
  }

  Future<void> loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_storageKey)) {
      _items = {};
      notifyListeners();
      return;
    }

    final String? wishlistData = prefs.getString(_storageKey);
    if (wishlistData != null) {
      try {
        final Map<String, dynamic> decodedData = jsonDecode(wishlistData);
        final Map<String, Product> loadedItems = {};
        decodedData.forEach((key, value) {
          loadedItems[key] = Product.fromJson(value as Map<String, dynamic>);
        });
        _items = loadedItems;
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading wishlist: $e");
      }
    }
  }

  void toggleWishlist(Product product) {
    final String key = product.id.toString();
    if (_items.containsKey(key)) {
      _items.remove(key);
    } else {
      _items[key] = product;
    }
    saveWishlist();
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId.toString());
    saveWishlist();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    saveWishlist();
    notifyListeners();
  }
}
