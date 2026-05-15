class TransactionItemModel {
  final int? id;
  final int? transactionId;
  final String productCode;
  final String productName;
  final double unitPrice;
  final double quantity;
  final double subtotal;

  const TransactionItemModel({
    this.id,
    this.transactionId,
    required this.productCode,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  /// Converts this line item into a map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_code': productCode,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  /// Builds a transaction item from a database row.
  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productCode: (map['product_code'] ?? '') as String,
      productName: (map['product_name'] ?? '') as String,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}
