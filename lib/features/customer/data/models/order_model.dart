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
  final String? shippingMethodName;
  final String? shippingCarrier;
  final String? estimatedDeliveryFrom;
  final String? estimatedDeliveryTo;
  final List<OrderItemModel> items;
  final List<OrderStatusHistoryModel> statusHistory;
  final List<ShipmentModel> shipments;

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
    this.shippingMethodName,
    this.shippingCarrier,
    this.estimatedDeliveryFrom,
    this.estimatedDeliveryTo,
    this.items = const [],
    this.statusHistory = const [],
    this.shipments = const [],
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

  String get displayStatus => statusLabel ?? _humanizeStatus(status);

  String _humanizeStatus(String s) {
    return s.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  /// Returns a commercial order reference (e.g. XM-260811-00125)
  String get orderRef => formatOrderRef(id, createdAt);

  ShipmentModel? get primaryShipment =>
      shipments.isNotEmpty ? shipments.first : null;

  String? get deliveryStatus => primaryShipment?.status;

  String get displayDeliveryStatus {
    final s = primaryShipment?.status;
    if (s == null) return 'Processing';
    return _humanizeStatus(s);
  }

  bool get isDelivered => status.toLowerCase() == 'delivered';
  bool get isShipped =>
      status.toLowerCase() == 'shipped' ||
      status.toLowerCase() == 'received_at_hub' ||
      (primaryShipment != null &&
          ['dispatched', 'in_transit', 'out_for_delivery']
              .contains(primaryShipment!.status.toLowerCase()));
  bool get isPending =>
      ['pending', 'paid', 'processing'].contains(status.toLowerCase());
  bool get isCancelled =>
      ['cancelled', 'refunded'].contains(status.toLowerCase());

  String? get estimatedDeliveryRange {
    if (estimatedDeliveryFrom == null && estimatedDeliveryTo == null) return null;
    String fmt(String? iso) {
      if (iso == null) return '';
      try {
        final dt = DateTime.parse(iso);
        return '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {
        return iso;
      }
    }
    final from = fmt(estimatedDeliveryFrom);
    final to = fmt(estimatedDeliveryTo);
    if (from.isEmpty) return 'By $to';
    if (to.isEmpty) return 'From $from';
    return '$from - $to';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final historyList = json['status_history'] as List<dynamic>? ?? [];
    final shipmentsList = json['shipments'] as List<dynamic>? ?? [];
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
      shippingMethodName: json['shipping_method_name'] as String?,
      shippingCarrier: json['shipping_carrier'] as String?,
      estimatedDeliveryFrom: json['estimated_delivery_from']?.toString(),
      estimatedDeliveryTo: json['estimated_delivery_to']?.toString(),
      items: itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusHistory: historyList
          .map((e) => OrderStatusHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      shipments: shipmentsList
          .map((e) => ShipmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShipmentModel {
  final String id;
  final String orderId;
  final String status;
  final String? carrierName;
  final String? trackingNumber;
  final String? estimatedDeliveryFrom;
  final String? estimatedDeliveryTo;
  final String? dispatchedAt;
  final String? deliveredAt;
  final List<ShipmentTrackingEventModel> trackingEvents;

  const ShipmentModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.carrierName,
    this.trackingNumber,
    this.estimatedDeliveryFrom,
    this.estimatedDeliveryTo,
    this.dispatchedAt,
    this.deliveredAt,
    this.trackingEvents = const [],
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    final eventsList = json['tracking_events'] as List<dynamic>? ?? [];
    return ShipmentModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      status: json['status'] as String? ?? 'pending',
      carrierName: json['carrier_name'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      estimatedDeliveryFrom: json['estimated_delivery_from']?.toString(),
      estimatedDeliveryTo: json['estimated_delivery_to']?.toString(),
      dispatchedAt: json['dispatched_at']?.toString(),
      deliveredAt: json['delivered_at']?.toString(),
      trackingEvents: eventsList
          .map((e) => ShipmentTrackingEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShipmentTrackingEventModel {
  final String id;
  final String status;
  final String? location;
  final String? notes;
  final String? createdAt;

  const ShipmentTrackingEventModel({
    required this.id,
    required this.status,
    this.location,
    this.notes,
    this.createdAt,
  });

  factory ShipmentTrackingEventModel.fromJson(Map<String, dynamic> json) {
    return ShipmentTrackingEventModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? '',
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at']?.toString(),
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
