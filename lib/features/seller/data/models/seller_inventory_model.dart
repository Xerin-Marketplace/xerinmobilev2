double _pd(dynamic v) { if (v == null) return 0.0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0.0; return 0.0; }
int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

class SellerInventoryItemModel {
  final String inventoryId;
  final String productId;
  final String productName;
  final String? productSku;
  final String? variantId;
  final String? variantName;
  final String? variantSku;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int lowStockThreshold;
  final String? warehouseLocation;
  final String? restockDate;
  final double unitPrice;
  final double inventoryValue;
  final bool isLowStock;
  final bool isOutOfStock;
  final String? updatedAt;

  const SellerInventoryItemModel({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.productSku,
    this.variantId,
    this.variantName,
    this.variantSku,
    this.quantity = 0,
    this.reservedQuantity = 0,
    this.availableQuantity = 0,
    this.lowStockThreshold = 0,
    this.warehouseLocation,
    this.restockDate,
    this.unitPrice = 0.0,
    this.inventoryValue = 0.0,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.updatedAt,
  });

  factory SellerInventoryItemModel.fromJson(Map<String, dynamic> json) {
    return SellerInventoryItemModel(
      inventoryId: json['inventory_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      productSku: json['product_sku'] as String?,
      variantId: json['variant_id']?.toString(),
      variantName: json['variant_name'] as String?,
      variantSku: json['variant_sku'] as String?,
      quantity: _pi(json['quantity']),
      reservedQuantity: _pi(json['reserved_quantity']),
      availableQuantity: _pi(json['available_quantity']),
      lowStockThreshold: _pi(json['low_stock_threshold']),
      warehouseLocation: json['warehouse_location'] as String?,
      restockDate: json['restock_date'] as String?,
      unitPrice: _pd(json['unit_price']),
      inventoryValue: _pd(json['inventory_value']),
      isLowStock: json['is_low_stock'] as bool? ?? false,
      isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SellerInventorySummary {
  final int totalProducts;
  final int totalVariants;
  final int totalStockUnits;
  final int reservedUnits;
  final int availableUnits;
  final int lowStockVariants;
  final int outOfStockVariants;
  final double inventoryValue;

  const SellerInventorySummary({
    this.totalProducts = 0,
    this.totalVariants = 0,
    this.totalStockUnits = 0,
    this.reservedUnits = 0,
    this.availableUnits = 0,
    this.lowStockVariants = 0,
    this.outOfStockVariants = 0,
    this.inventoryValue = 0.0,
  });

  factory SellerInventorySummary.fromJson(Map<String, dynamic> json) {
    return SellerInventorySummary(
      totalProducts: _pi(json['total_products']),
      totalVariants: _pi(json['total_variants']),
      totalStockUnits: _pi(json['total_stock_units']),
      reservedUnits: _pi(json['reserved_units']),
      availableUnits: _pi(json['available_units']),
      lowStockVariants: _pi(json['low_stock_variants']),
      outOfStockVariants: _pi(json['out_of_stock_variants']),
      inventoryValue: _pd(json['inventory_value']),
    );
  }
}

class SellerInventoryMovement {
  final String id;
  final String inventoryId;
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final String movementType;
  final int adjustment;
  final int beforeQuantity;
  final int afterQuantity;
  final String? reference;
  final String? note;
  final String? createdAt;

  const SellerInventoryMovement({
    required this.id,
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    this.movementType = '',
    this.adjustment = 0,
    this.beforeQuantity = 0,
    this.afterQuantity = 0,
    this.reference,
    this.note,
    this.createdAt,
  });

  factory SellerInventoryMovement.fromJson(Map<String, dynamic> json) {
    return SellerInventoryMovement(
      id: json['id']?.toString() ?? '',
      inventoryId: json['inventory_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      variantId: json['variant_id']?.toString(),
      variantName: json['variant_name'] as String?,
      movementType: json['movement_type'] as String? ?? '',
      adjustment: _pi(json['adjustment']),
      beforeQuantity: _pi(json['before_quantity']),
      afterQuantity: _pi(json['after_quantity']),
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
