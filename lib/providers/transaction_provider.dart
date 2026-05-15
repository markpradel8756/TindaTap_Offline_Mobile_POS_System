import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import 'cart_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  bool _isProcessing = false;

  /// Exposes whether a sale is actively being saved to the database.
  bool get isProcessing => _isProcessing;

  /// Validates the payment details, records the sale, and saves the sold items
  /// inside a single database transaction.
  Future<int> completeSale({
    required List<CartItem> cartItems,
    required String paymentMethod,
    double? cashReceived,
    String? qrLabel,
    required String storeName,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final total = cartItems.fold<double>(0, (sum, item) => sum + item.subtotal);
    if (paymentMethod == 'cash') {
      if (cashReceived == null) {
        throw Exception('Cash received is required.');
      }
      if (cashReceived < total) {
        throw Exception('Cash received must be at least the total amount.');
      }
    }

    _isProcessing = true;
    notifyListeners();
    try {
      final transaction = SaleTransaction(
        timestamp: DateTime.now().toIso8601String(),
        totalAmount: total,
        paymentMethod: paymentMethod,
        cashReceived: cashReceived,
        qrLabel: qrLabel,
        storeName: storeName,
      );

      final items = cartItems
          .map(
            (item) => TransactionItemModel(
              productCode: item.productCode,
              productName: item.productName,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              subtotal: item.subtotal,
            ),
          )
          .toList();

      return await _databaseHelper.saveTransaction(
        transaction: transaction,
        items: items,
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Retrieves all sales recorded for the selected calendar date.
  Future<List<SaleTransaction>> getTransactionsForDate(DateTime date) {
    return _databaseHelper.getTransactionsByDate(date);
  }

  /// Retrieves the most recent completed sales for dashboard displays.
  Future<List<SaleTransaction>> getRecentTransactions({int limit = 10}) {
    return _databaseHelper.getRecentTransactions(limit: limit);
  }

  /// Returns the total sales amount for one day.
  Future<double> getDailyTotal(DateTime date) {
    return _databaseHelper.getDailySalesTotal(date);
  }

  /// Returns sales totals grouped by day within the provided range.
  Future<Map<String, double>> getDailyTotalsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _databaseHelper.getDailySalesTotalsInRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Returns rows used to build stock movement reports.
  Future<List<Map<String, dynamic>>> getStockMovementRows() {
    return _databaseHelper.getStockMovementRows();
  }

  /// Returns products ordered by sales volume so fast movers are easy to spot.
  Future<List<Map<String, dynamic>>> getFastMovingProducts({
    int days = 30,
    int limit = 10,
  }) {
    return _databaseHelper.getFastMovingProducts(days: days, limit: limit);
  }
}
