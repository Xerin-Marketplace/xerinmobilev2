import '../../../../core/utils/helpers.dart';

double _pd(dynamic v) { if (v == null) return 0.0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0.0; return 0.0; }
int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

class SellerOrderModel {
  final String id;
  final String userId;
  final String status;
  final String currency;
  final double subtotal;
  final double discountAmount;
  final double shippingAmount;
  final double taxAmount;
  final double total;
  final String? couponCode;
  final String? notes;
  final List<SellerOrderItemModel> items;
  final String? createdAt;
  final String? updatedAt;

  const SellerOrderModel({
    required this.id,
    required this.userId,
    required this.status,
    this.currency = 'TZS',
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.shippingAmount = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    this.couponCode,
    this.notes,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get formattedTotal {
    final formatted = total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  String get displayStatus => status;

  /// Returns a commercial order reference (e.g. XM-260811-00125)
  String get orderRef => formatOrderRef(id, createdAt);

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return SellerOrderModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status'] as String? ?? 'pending',
      currency: json['currency'] as String? ?? 'TZS',
      subtotal: _pd(json['subtotal']),
      discountAmount: _pd(json['discount_amount']),
      shippingAmount: _pd(json['shipping_amount']),
      taxAmount: _pd(json['tax_amount']),
      total: _pd(json['total']),
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      items: itemsList
          .map((e) => SellerOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SellerOrderItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String sellerId;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SellerOrderItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.sellerId,
    required this.productName,
    this.variantName,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
  });

  String get formattedUnitPrice {
    final formatted = unitPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return formatted;
  }

  factory SellerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      sellerId: json['seller_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      variantName: json['variant_name'] as String?,
      quantity: _pi(json['quantity']) == 0 ? 1 : _pi(json['quantity']),
      unitPrice: _pd(json['unit_price']),
      totalPrice: _pd(json['total_price']),
    );
  }
}
