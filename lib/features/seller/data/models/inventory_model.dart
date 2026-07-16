class InventoryModel {
  final String id;
  final String productId;
  final String? variantId;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final String? warehouseLocation;
  final int lowStockThreshold;
  final String? restockDate;
  final String? updatedAt;

  const InventoryModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    this.reservedQuantity = 0,
    this.availableQuantity = 0,
    this.warehouseLocation,
    this.lowStockThreshold = 10,
    this.restockDate,
    this.updatedAt,
  });

  bool get isLowStock => availableQuantity <= lowStockThreshold;
  bool get isOutOfStock => availableQuantity <= 0;

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reservedQuantity: (json['reserved_quantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toInt() ?? 0,
      warehouseLocation: json['warehouse_location'] as String?,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 10,
      restockDate: json['restock_date'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
        'reserved_quantity': reservedQuantity,
        'warehouse_location': warehouseLocation,
        'low_stock_threshold': lowStockThreshold,
      };
}
