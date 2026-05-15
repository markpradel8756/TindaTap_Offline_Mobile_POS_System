class SaleTransaction {
  final int? id;
  final String timestamp;
  final double totalAmount;
  final String paymentMethod;
  final double? cashReceived;
  final String? qrLabel;
  final String? storeName;

  const SaleTransaction({
    this.id,
    required this.timestamp,
    required this.totalAmount,
    required this.paymentMethod,
    this.cashReceived,
    this.qrLabel,
    this.storeName,
  });

  /// Creates a copy of this transaction with selected values replaced.
  SaleTransaction copyWith({
    int? id,
    String? timestamp,
    double? totalAmount,
    String? paymentMethod,
    double? cashReceived,
    String? qrLabel,
    String? storeName,
  }) {
    return SaleTransaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceived: cashReceived ?? this.cashReceived,
      qrLabel: qrLabel ?? this.qrLabel,
      storeName: storeName ?? this.storeName,
    );
  }

  /// Converts this transaction into a map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'cash_received': cashReceived,
      'qr_label': qrLabel,
      'store_name': storeName,
    };
  }

  /// Builds a transaction model from a database row.
  factory SaleTransaction.fromMap(Map<String, dynamic> map) {
    return SaleTransaction(
      id: map['id'] as int?,
      timestamp: (map['timestamp'] ?? '') as String,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (map['payment_method'] ?? '') as String,
      cashReceived: (map['cash_received'] as num?)?.toDouble(),
      qrLabel: map['qr_label'] as String?,
      storeName: map['store_name'] as String?,
    );
  }
}
