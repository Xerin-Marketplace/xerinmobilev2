import '../../../../core/utils/helpers.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String? shippingAddressId;
  final double subtotal;
  final double discountAmount;
  final double shippingAmount;
  final double taxAmount;
  final double total;
  final String currency;
  final String status;
  final String? statusLabel;
  final String? couponCode;
  final String? notes;
  final int itemCount;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderItemModel> items;
  final List<OrderStatusHistoryModel> statusHistory;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    this.shippingAddressId,
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.shippingAmount = 0.0,
    this.taxAmount = 0.0,
    required this.total,
    this.currency = 'TZS',
    required this.status,
    this.statusLabel,
    this.couponCode,
    this.notes,
    this.itemCount = 0,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.statusHistory = const [],
  });

  String get formattedTotal {
    final formatted = total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  String get formattedSubtotal {
    final formatted = subtotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  String get displayStatus => statusLabel ?? status;

  /// Returns a commercial order reference (e.g. XM-260811-00125)
  String get orderRef => formatOrderRef(id, createdAt);

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final historyList = json['status_history'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number'] as String? ?? json['id']?.toString() ?? '',
      shippingAddressId: json['shipping_address_id']?.toString(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      shippingAmount: (json['shipping_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'TZS',
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String?,
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      itemCount: (json['item_count'] as num?)?.toInt() ?? itemsList.length,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      items: itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistory: historyList
          .map((e) => OrderStatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderStatusHistoryModel {
  final String id;
  final String status;
  final String? notes;
  final String? createdById;
  final String? createdAt;

  const OrderStatusHistoryModel({
    required this.id,
    required this.status,
    this.notes,
    this.createdById,
    this.createdAt,
  });

  factory OrderStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String?,
      createdById: json['created_by_id']?.toString(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String? sellerId;
  final String productName;
  final String? variantName;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String currency;

  const OrderItemModel({
    required this.id,
    this.productId = '',
    this.variantId,
    this.sellerId,
    required this.productName,
    this.variantName,
    this.productImage,
    this.quantity = 1,
    required this.unitPrice,
    this.totalPrice = 0.0,
    this.currency = 'TZS',
  });

  String get formattedPrice {
    final formatted = unitPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  String get formattedTotal {
    final t = totalPrice > 0 ? totalPrice : unitPrice * quantity;
    final formatted = t.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        variantId: json['variant_id']?.toString(),
        sellerId: json['seller_id']?.toString(),
        productName: json['product_name'] as String? ?? json['name'] as String? ?? '',
        variantName: json['variant_name'] as String?,
        productImage: json['product_image'] as String? ?? json['image'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ??
            (json['price'] as num?)?.toDouble() ??
            0.0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
        currency: json['currency'] as String? ?? 'TZS',
      );
}
