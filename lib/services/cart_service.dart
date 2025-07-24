import 'package:flutter/foundation.dart';
import '../Models/cart_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, List<CartItem>> _pharmacyCarts = {};
  String? _currentPharmacy;

  // Get current pharmacy name
  String? get currentPharmacy => _currentPharmacy;

  // Set current pharmacy (when user enters a pharmacy's shopping page)
  void setCurrentPharmacy(String pharmacyName) {
    _currentPharmacy = pharmacyName;
    if (!_pharmacyCarts.containsKey(pharmacyName)) {
      _pharmacyCarts[pharmacyName] = [];
    }
    notifyListeners();
  }

  // Get cart items for current pharmacy
  List<CartItem> get currentCartItems {
    if (_currentPharmacy == null) return [];
    return _pharmacyCarts[_currentPharmacy] ?? [];
  }

  // Get cart items for specific pharmacy
  List<CartItem> getCartItemsForPharmacy(String pharmacyName) {
    return _pharmacyCarts[pharmacyName] ?? [];
  }

  // Add item to current pharmacy's cart
  void addToCart(CartItem item) {
    if (_currentPharmacy == null) return;

    final cartItems = _pharmacyCarts[_currentPharmacy]!;
    final existingIndex =
        cartItems.indexWhere((cartItem) => cartItem.id == item.id);

    if (existingIndex != -1) {
      // Item already exists, increase quantity
      cartItems[existingIndex] = cartItems[existingIndex].copyWith(
        quantity: cartItems[existingIndex].quantity + 1,
      );
    } else {
      // Add new item
      cartItems.add(item);
    }

    notifyListeners();
  }

  // Remove item from current pharmacy's cart
  void removeFromCart(String itemId) {
    if (_currentPharmacy == null) return;

    _pharmacyCarts[_currentPharmacy]!.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  // Update item quantity in current pharmacy's cart
  void updateQuantity(String itemId, int newQuantity) {
    if (_currentPharmacy == null) return;

    final cartItems = _pharmacyCarts[_currentPharmacy]!;
    final index = cartItems.indexWhere((item) => item.id == itemId);

    if (index != -1) {
      if (newQuantity <= 0) {
        cartItems.removeAt(index);
      } else {
        cartItems[index] = cartItems[index].copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  // Get total items count for current pharmacy
  int get totalItemsCount {
    return currentCartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total price for current pharmacy
  double get totalPrice {
    return currentCartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Clear current pharmacy's cart
  void clearCurrentCart() {
    if (_currentPharmacy != null) {
      _pharmacyCarts[_currentPharmacy]!.clear();
      notifyListeners();
    }
  }

  // Clear all carts
  void clearAllCarts() {
    _pharmacyCarts.clear();
    _currentPharmacy = null;
    notifyListeners();
  }

  // Check if item exists in current cart
  bool isInCart(String itemId) {
    return currentCartItems.any((item) => item.id == itemId);
  }

  // Get item quantity in current cart
  int getItemQuantity(String itemId) {
    final item = currentCartItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => CartItem(
        id: '',
        name: '',
        description: '',
        price: 0,
        pharmacyName: '',
        category: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Get all pharmacy names that have items in cart
  List<String> get pharmaciesWithItems {
    return _pharmacyCarts.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList();
  }
}
