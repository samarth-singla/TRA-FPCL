import 'package:flutter/foundation.dart';

/// Cart Item Model
class CartItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String unit;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? unit,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

/// Cart Service - Manages shopping cart state
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get gst => subtotal * 0.18; // 18% GST

  double get total => subtotal + gst;

  bool get isEmpty => _items.isEmpty;

  /// Add product to cart or update quantity if exists
  void addToCart({
    required String productId,
    required String productName,
    required double price,
    required String unit,
    int quantity = 1,
  }) {
    final existingIndex = _items.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      // Update quantity if product already in cart
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + quantity,
      );
    } else {
      // Add new item to cart
      _items.add(CartItem(
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        unit: unit,
      ));
    }

    notifyListeners();
  }

  /// Update quantity of specific item
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  /// Clear entire cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Get quantity of specific product in cart
  int getProductQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        price: 0,
        quantity: 0,
        unit: '',
      ),
    );
    return item.quantity;
  }
}
