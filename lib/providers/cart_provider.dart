import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartItem {
  final String productCode;
  final String productName;
  final double unitPrice;
  final double quantity;

  const CartItem({
    required this.productCode,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  /// Calculates the line-item subtotal from the price and quantity.
  double get subtotal => unitPrice * quantity;

  /// Creates a new cart item by replacing selected values while keeping the
  /// rest of the line item unchanged.
  CartItem copyWith({
    String? productCode,
    String? productName,
    double? unitPrice,
    double? quantity,
  }) {
    return CartItem(
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  /// Exposes the cart items as an unmodifiable list so callers cannot mutate
  /// provider state directly.
  List<CartItem> get items => List.unmodifiable(_items);

  /// Computes the current cart total by summing every line-item subtotal.
  double get total =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  /// Returns true when the cart has no items in it.
  bool get isEmpty => _items.isEmpty;

  /// Adds a product to the cart or increases the quantity if it already exists.
  void addProduct(ProductModel product) {
    final index =
        _items.indexWhere((item) => item.productCode == product.productCode);
    if (index >= 0) {
      _items[index] =
          _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(
        CartItem(
          productCode: product.productCode,
          productName: product.name,
          unitPrice: product.price,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  /// Changes the quantity of a specific product and removes it when the new
  /// quantity is zero or below.
  void updateQuantity(String productCode, double quantity) {
    final index = _items.indexWhere((item) => item.productCode == productCode);
    if (index < 0) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  /// Increases the quantity of a cart item by one unit.
  void increment(String productCode) {
    final index = _items.indexWhere((item) => item.productCode == productCode);
    if (index < 0) return;
    updateQuantity(productCode, _items[index].quantity + 1);
  }

  /// Decreases the quantity of a cart item by one unit.
  void decrement(String productCode) {
    final index = _items.indexWhere((item) => item.productCode == productCode);
    if (index < 0) return;
    updateQuantity(productCode, _items[index].quantity - 1);
  }

  /// Removes a product from the cart entirely.
  void remove(String productCode) {
    _items.removeWhere((item) => item.productCode == productCode);
    notifyListeners();
  }

  /// Clears every cart item and notifies listeners that the cart changed.
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
