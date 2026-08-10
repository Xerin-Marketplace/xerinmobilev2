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
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reservedQuantity: (json['reserved_quantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 0,
      warehouseLocation: json['warehouse_location'] as String?,
      restockDate: json['restock_date'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      inventoryValue: (json['inventory_value'] as num?)?.toDouble() ?? 0.0,
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
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      totalVariants: (json['total_variants'] as num?)?.toInt() ?? 0,
      totalStockUnits: (json['total_stock_units'] as num?)?.toInt() ?? 0,
      reservedUnits: (json['reserved_units'] as num?)?.toInt() ?? 0,
      availableUnits: (json['available_units'] as num?)?.toInt() ?? 0,
      lowStockVariants: (json['low_stock_variants'] as num?)?.toInt() ?? 0,
      outOfStockVariants: (json['out_of_stock_variants'] as num?)?.toInt() ?? 0,
      inventoryValue: (json['inventory_value'] as num?)?.toDouble() ?? 0.0,
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
      adjustment: (json['adjustment'] as num?)?.toInt() ?? 0,
      beforeQuantity: (json['before_quantity'] as num?)?.toInt() ?? 0,
      afterQuantity: (json['after_quantity'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
