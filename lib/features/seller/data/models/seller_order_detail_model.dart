import '../../../core/utils/helpers.dart';

class SellerOrderSummary {
  final int totalOrders;
  final int newOrders;
  final int acceptedOrders;
  final int processingOrders;
  final int readyToShipOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancellationRequests;
  final double grossSales;
  final int unitsSold;

  const SellerOrderSummary({
    this.totalOrders = 0,
    this.newOrders = 0,
    this.acceptedOrders = 0,
    this.processingOrders = 0,
    this.readyToShipOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.cancellationRequests = 0,
    this.grossSales = 0.0,
    this.unitsSold = 0,
  });

  factory SellerOrderSummary.fromJson(Map<String, dynamic> json) {
    return SellerOrderSummary(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      newOrders: (json['new_orders'] as num?)?.toInt() ?? 0,
      acceptedOrders: (json['accepted_orders'] as num?)?.toInt() ?? 0,
      processingOrders: (json['processing_orders'] as num?)?.toInt() ?? 0,
      readyToShipOrders: (json['ready_to_ship_orders'] as num?)?.toInt() ?? 0,
      shippedOrders: (json['shipped_orders'] as num?)?.toInt() ?? 0,
      deliveredOrders: (json['delivered_orders'] as num?)?.toInt() ?? 0,
      cancellationRequests: (json['cancellation_requests'] as num?)?.toInt() ?? 0,
      grossSales: (json['gross_sales'] as num?)?.toDouble() ?? 0.0,
      unitsSold: (json['units_sold'] as num?)?.toInt() ?? 0,
    );
  }
}

class SellerOrderDetail {
  final String id;
  final String orderId;
  final String sellerId;
  final String orderStatus;
  final String sellerStatus;
  final String currency;
  final double sellerSubtotal;
  final int itemCount;
  final String customerName;
  final String? customerPhone;
  final String? shippingMethodName;
  final String? shippingCarrier;
  final String? sellerNotes;
  final String? cancellationReason;
  final String? createdAt;
  final String? updatedAt;
  final List<SellerOrderDetailItem> items;
  final SellerOrderShipment? shipment;
  final SellerOrderAddress? shippingAddress;

  /// Returns a commercial order reference (e.g. XM-260811-00125)
  String get orderRef => formatOrderRef(orderId, createdAt);

  const SellerOrderDetail({
    required this.id,
    this.orderId = '',
    this.sellerId = '',
    this.orderStatus = '',
    this.sellerStatus = '',
    this.currency = 'TZS',
    this.sellerSubtotal = 0.0,
    this.itemCount = 0,
    this.customerName = '',
    this.customerPhone,
    this.shippingMethodName,
    this.shippingCarrier,
    this.sellerNotes,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.shipment,
    this.shippingAddress,
  });

  factory SellerOrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return SellerOrderDetail(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      orderStatus: json['order_status'] as String? ?? '',
      sellerStatus: json['seller_status'] as String? ?? '',
      currency: json['currency'] as String? ?? 'TZS',
      sellerSubtotal: (json['seller_subtotal'] as num?)?.toDouble() ?? 0.0,
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String?,
      shippingMethodName: json['shipping_method_name'] as String?,
      shippingCarrier: json['shipping_carrier'] as String?,
      sellerNotes: json['seller_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      items: itemsList.map((e) => SellerOrderDetailItem.fromJson(e as Map<String, dynamic>)).toList(),
      shipment: json['shipment'] != null
          ? SellerOrderShipment.fromJson(json['shipment'] as Map<String, dynamic>)
          : null,
      shippingAddress: json['shipping_address'] != null
          ? SellerOrderAddress.fromJson(json['shipping_address'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SellerOrderDetailItem {
  final String id;
  final String productId;
  final String? variantId;
  final String sellerId;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SellerOrderDetailItem({
    required this.id,
    this.productId = '',
    this.variantId,
    this.sellerId = '',
    this.productName = '',
    this.variantName,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
  });

  factory SellerOrderDetailItem.fromJson(Map<String, dynamic> json) {
    return SellerOrderDetailItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      sellerId: json['seller_id']?.toString() ?? '',
      productName: json['product_name'] as String? ?? '',
      variantName: json['variant_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SellerOrderShipment {
  final String id;
  final String? carrierName;
  final String? trackingNumber;
  final String status;
  final String? dispatchedAt;
  final String? deliveredAt;

  const SellerOrderShipment({
    required this.id,
    this.carrierName,
    this.trackingNumber,
    this.status = 'pending',
    this.dispatchedAt,
    this.deliveredAt,
  });

  factory SellerOrderShipment.fromJson(Map<String, dynamic> json) {
    return SellerOrderShipment(
      id: json['id']?.toString() ?? '',
      carrierName: json['carrier_name'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      dispatchedAt: json['dispatched_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
    );
  }
}

class SellerOrderAddress {
  final String id;
  final String? label;
  final String? recipientName;
  final String? recipientPhone;
  final String? street;
  final String? ward;
  final String? district;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? country;

  const SellerOrderAddress({
    required this.id,
    this.label,
    this.recipientName,
    this.recipientPhone,
    this.street,
    this.ward,
    this.district,
    this.city,
    this.region,
    this.postalCode,
    this.country,
  });

  factory SellerOrderAddress.fromJson(Map<String, dynamic> json) {
    return SellerOrderAddress(
      id: json['id']?.toString() ?? '',
      label: json['label'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      street: json['street'] as String?,
      ward: json['ward'] as String?,
      district: json['district'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
    );
  }
}

class DeliveryQuoteModel {
  final String provider;
  final String? quoteId;
  final double fee;
  final String currency;
  final String? estimatedPickupAt;
  final String? estimatedDeliveryAt;

  const DeliveryQuoteModel({
    this.provider = '',
    this.quoteId,
    this.fee = 0.0,
    this.currency = 'TZS',
    this.estimatedPickupAt,
    this.estimatedDeliveryAt,
  });

  factory DeliveryQuoteModel.fromJson(Map<String, dynamic> json) {
    return DeliveryQuoteModel(
      provider: json['provider'] as String? ?? '',
      quoteId: json['quote_id']?.toString(),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'TZS',
      estimatedPickupAt: json['estimated_pickup_at'] as String?,
      estimatedDeliveryAt: json['estimated_delivery_at'] as String?,
    );
  }
}

class DeliveryJobModel {
  final String id;
  final String? externalDeliveryId;
  final String status;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? courierName;
  final String? courierPhone;
  final double? deliveryFee;
  final String? currency;
  final String? estimatedPickupAt;
  final String? estimatedDeliveryAt;
  final String? failureReason;

  const DeliveryJobModel({
    required this.id,
    this.externalDeliveryId,
    this.status = 'created',
    this.trackingNumber,
    this.trackingUrl,
    this.courierName,
    this.courierPhone,
    this.deliveryFee,
    this.currency,
    this.estimatedPickupAt,
    this.estimatedDeliveryAt,
    this.failureReason,
  });

  factory DeliveryJobModel.fromJson(Map<String, dynamic> json) {
    return DeliveryJobModel(
      id: json['id']?.toString() ?? '',
      externalDeliveryId: json['external_delivery_id']?.toString(),
      status: json['status'] as String? ?? 'created',
      trackingNumber: json['tracking_number'] as String?,
      trackingUrl: json['tracking_url'] as String?,
      courierName: json['courier_name'] as String?,
      courierPhone: json['courier_phone'] as String?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      estimatedPickupAt: json['estimated_pickup_at'] as String?,
      estimatedDeliveryAt: json['estimated_delivery_at'] as String?,
      failureReason: json['failure_reason'] as String?,
    );
  }
}
