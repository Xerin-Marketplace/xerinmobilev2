double _pd(dynamic v) { if (v == null) return 0.0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0.0; return 0.0; }
int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

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
      quantity: _pi(json['quantity']),
      reservedQuantity: _pi(json['reserved_quantity']),
      availableQuantity: _pi(json['available_quantity']),
      warehouseLocation: json['warehouse_location'] as String?,
      lowStockThreshold: _pi(json['low_stock_threshold']) == 0 ? 10 : _pi(json['low_stock_threshold']),
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
