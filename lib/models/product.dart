class ProductModel {
  final int? id;
  final String productCode;
  final String name;
  final double price;
  final double quantity;
  final String? createdAt;
  final String? updatedAt;

  const ProductModel({
    this.id,
    required this.productCode,
    required this.name,
    required this.price,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy of this product with selected fields replaced.
  ProductModel copyWith({
    int? id,
    String? productCode,
    String? name,
    double? price,
    double? quantity,
    String? createdAt,
    String? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts this product into a map suitable for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_code': productCode,
      'name': name,
      'price': price,
      'quantity': quantity,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Builds a product model from a database row.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      productCode: (map['product_code'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
