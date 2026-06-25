import 'dart:convert';
import 'package:SujaCreations/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class UserProvider with ChangeNotifier {
  Customer? _currentCustomer;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  bool _isInitialized = false;
  late Future<void> initializationFuture;

  UserProvider() {
    initializationFuture = loadUser();
  }

  bool get isInitialized => _isInitialized;

  Customer? get currentCustomer => _currentCustomer;

  bool get isLoggedIn => _currentCustomer != null;

  Future<void> saveUser(Customer customer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(customer.toJson()));
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');
    if (userData != null) {
      _currentCustomer = Customer.fromJson(jsonDecode(userData));
      _notificationService.subscribeToUserTopic(_currentCustomer!.username);
    }
    _isInitialized = true;
    notifyListeners();
  }

  void setCustomer(Customer customer) {
    _currentCustomer = customer;
    saveUser(customer);
    _notificationService.subscribeToUserTopic(customer.username);
    notifyListeners();
  }

  Future<void> logout() async {
    if (_currentCustomer != null) {
      _notificationService.unsubscribeFromUserTopic(_currentCustomer!.username);
    }
    _currentCustomer = null;
    _isInitialized = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('verified_phone');
    await _authService.clearStoredPhone();
    
    notifyListeners();
  }
}
