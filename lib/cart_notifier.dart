import 'package:flutter/material.dart';

class CartNotifier extends ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addItem(Map<String, dynamic> item) {
    // nullable 변수 처리
    final existingItem = _cartItems.cast<Map<String, dynamic>?>().firstWhere(
          (cartItem) => cartItem?['name'] == item['name'],
          orElse: () => null,
        );

    if (existingItem != null) {
      existingItem['quantity'] += item['quantity'];
    } else {
      _cartItems.add(item);
    }

    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
