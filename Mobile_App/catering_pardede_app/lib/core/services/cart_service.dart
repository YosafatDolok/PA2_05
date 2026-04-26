import 'package:flutter/material.dart';
import '../../models/menu_model.dart';

class CartItem {
  final MenuModel menu;
  int quantity;

  CartItem({required this.menu, this.quantity = 1});
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<MenuModel> _items = [];

  List<MenuModel> get items => List.unmodifiable(_items);

  int get totalItems => _items.length;

  void addToCart(MenuModel menu) {
    if (!_items.any((item) => item.id == menu.id)) {
      _items.add(menu);
      notifyListeners();
    }
  }

  void removeFromCart(int menuId) {
    _items.removeWhere((item) => item.id == menuId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
