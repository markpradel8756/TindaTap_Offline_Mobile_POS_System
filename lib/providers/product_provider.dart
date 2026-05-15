import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<ProductModel> _products = [];
  bool _isLoading = false;

  /// Returns the cached products as an unmodifiable list for safe reading.
  List<ProductModel> get products => List.unmodifiable(_products);

  /// Indicates whether product data is currently being loaded from storage.
  bool get isLoading => _isLoading;

  /// Loads products from the database, optionally filtered by a search term.
  Future<void> loadProducts({String search = ''}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _databaseHelper.getProducts(search: search);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs a one-off search query without replacing the cached product list.
  Future<List<ProductModel>> searchProducts(String query) {
    return _databaseHelper.getProducts(search: query);
  }

  /// Inserts a new product after confirming its code is not already used.
  Future<void> addProduct(ProductModel product) async {
    final existing =
        await _databaseHelper.getProductByCode(product.productCode);
    if (existing != null) {
      throw Exception('Product code already exists.');
    }
    await _databaseHelper.insertProduct(product);
    await loadProducts();
  }

  /// Updates an existing product while preventing duplicate product codes.
  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) {
      throw Exception('Product ID is required for update.');
    }

    final existing =
        await _databaseHelper.getProductByCode(product.productCode);
    if (existing != null && existing.id != product.id) {
      throw Exception('Product code already exists.');
    }

    await _databaseHelper.updateProduct(product);
    await loadProducts();
  }

  /// Deletes a product from storage and refreshes the cached list.
  Future<void> deleteProduct(ProductModel product) async {
    if (product.id == null) return;
    await _databaseHelper.deleteProduct(product.id!);
    await loadProducts();
  }
}
