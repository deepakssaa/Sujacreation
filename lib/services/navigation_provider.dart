import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 2; // Home as default
  int? _selectedCategoryId;

  int get currentIndex => _currentIndex;
  int? get selectedCategoryId => _selectedCategoryId;

  // Tab Indices: 0:Shop, 1:Cart, 2:Home, 3:Orders, 4:Profile
  void setTab(int index, {int? categoryId}) {
    _currentIndex = index;
    if (categoryId != null) {
      _selectedCategoryId = categoryId;
    }
    notifyListeners();
  }

  void clearCategory() {
    _selectedCategoryId = null;
    notifyListeners();
  }
}
