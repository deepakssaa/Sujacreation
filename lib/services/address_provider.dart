import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';
import '../models/customer.dart';
import '../services/woocommerce_customer_service.dart';

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  Address? _selectedAddress;
  int? _userId;

  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;

  String get _storageKey => _userId != null ? 'addresses_$_userId' : 'addresses_guest';

  void updateUser(int? newUserId, Customer? customer) {
    if (_userId == newUserId && _addresses.isNotEmpty) return;
    _userId = newUserId;
    loadAddresses(customer);
  }

  Future<void> loadAddresses(Customer? customer) async {
    String? metaAddressesJson;
    if (customer != null && customer.metaData != null) {
      final meta = customer.metaData!.firstWhere(
        (m) => m['key'] == 'suja_saved_addresses',
        orElse: () => null,
      );
      if (meta != null && meta['value'] != null && meta['value'].toString().trim().isNotEmpty) {
        metaAddressesJson = meta['value'].toString();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    String? jsonToLoad = metaAddressesJson ?? prefs.getString(_storageKey);

    if (jsonToLoad != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonToLoad);
        _addresses = decoded.map((item) => Address.fromJson(item)).toList();
        if (metaAddressesJson != null) {
          prefs.setString(_storageKey, metaAddressesJson);
        }
      } catch (e) {
        debugPrint("Error loading addresses: $e");
        _addresses = [];
      }
    }

    if (_addresses.isEmpty && customer != null) {
      final defaultAddress = Address.fromCustomerBilling(
        customer.billing,
        name: 'Default Address',
        id: 'default',
      );
      _addresses = [defaultAddress];
      await saveAddresses();
    } else if (customer == null && _addresses.isEmpty) {
      _addresses = [];
    }

    if (_addresses.isNotEmpty) {
      _selectedAddress = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
    } else {
      _selectedAddress = null;
    }
    notifyListeners();
  }

  Future<void> addAddress(Address address) async {
    if (address.isDefault) {
      _addresses = _addresses.map((a) => Address(
        id: a.id, name: a.name, firstName: a.firstName, lastName: a.lastName,
        address1: a.address1, address2: a.address2, city: a.city, state: a.state,
        postcode: a.postcode, country: a.country, email: a.email, phone: a.phone,
        isDefault: false,
      )).toList();
    }
    _addresses.add(address);
    if (address.isDefault || _addresses.length == 1) {
      _selectedAddress = address;
    }
    await saveAddresses();
    notifyListeners();
  }

  Future<void> updateAddress(Address updatedAddress) async {
    if (updatedAddress.isDefault) {
      _addresses = _addresses.map((a) => Address(
        id: a.id, name: a.name, firstName: a.firstName, lastName: a.lastName,
        address1: a.address1, address2: a.address2, city: a.city, state: a.state,
        postcode: a.postcode, country: a.country, email: a.email, phone: a.phone,
        isDefault: false,
      )).toList();
    }
    
    final index = _addresses.indexWhere((a) => a.id == updatedAddress.id);
    if (index != -1) {
      _addresses[index] = updatedAddress;
      if (updatedAddress.isDefault || _selectedAddress?.id == updatedAddress.id) {
        _selectedAddress = updatedAddress;
      }
      await saveAddresses();
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    _addresses.removeWhere((a) => a.id == id);
    if (_selectedAddress?.id == id) {
      _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
    }
    await saveAddresses();
    notifyListeners();
  }

  Future<void> selectAddress(Address address) async {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> setDefaultAddress(String id) async {
    _addresses = _addresses.map((a) {
      return Address(
        id: a.id, name: a.name, firstName: a.firstName, lastName: a.lastName,
        address1: a.address1, address2: a.address2, city: a.city, state: a.state,
        postcode: a.postcode, country: a.country, email: a.email, phone: a.phone,
        isDefault: a.id == id,
      );
    }).toList();
    _selectedAddress = _addresses.firstWhere((a) => a.id == id);
    await saveAddresses();
    notifyListeners();
  }

  Future<void> saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);

    if (_userId != null) {
      final wcService = WooCommerceCustomerService();
      // Fire and forget since we are already saving locally.
      wcService.updateCustomerAddresses(_userId!, encoded);
    }
  }

  void clearMemory() {
    _addresses = [];
    _selectedAddress = null;
    _userId = null;
    notifyListeners();
  }
}
