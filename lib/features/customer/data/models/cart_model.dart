import '../../../../config/constants/api_constants.dart';

class CartModel {
  final String id;
  final String userId;
  final String? couponCode;
  final List<CartItemModel> items;
  final double subtotal;
  final double discountAmount;
  final double total;

  const CartModel({
    required this.id,
    required this.userId,
    this.couponCode,
    this.items = const [],
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedSubtotal => _formatPrice(subtotal);
  String get formattedDiscount => _formatPrice(discountAmount);
  String get formattedTotal => _formatPrice(total);

  static String _formatPrice(double value) {
    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      couponCode: json['coupon_code'] as String?,
      items: itemsList
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: _parsePrice(json['subtotal']),
      discountAmount: _parsePrice(json['discount_amount']),
      total: _parsePrice(json['total']),
    );
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}

class CartItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final int quantity;
  final double unitPrice;
  final ProductSummary? product;

  const CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.product,
  });

  String get formattedPrice {
    final formatted = unitPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  String get formattedTotal {
    final total = unitPrice * quantity;
    final formatted = total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'] as Map<String, dynamic>?;
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: _parsePrice(json['unit_price']),
      product: productJson != null ? ProductSummary.fromJson(productJson) : null,
    );
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}

class ProductSummary {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final String currency;
  final List<String> images;
  final bool isActive;

  const ProductSummary({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.price = 0.0,
    this.salePrice,
    this.currency = 'TZS',
    this.images = const [],
    this.isActive = true,
  });

  String? get thumbnailUrl => images.isNotEmpty ? ApiConstants.resolveImageUrl(images.first) : null;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    List<String> imageUrls = [];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is String) {
          imageUrls.add(img);
        } else if (img is Map) {
          final url = img['image_url'] ?? img['url'] ?? img['src'];
          if (url is String) imageUrls.add(url);
        }
      }
    }

    double _p(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
      return 0.0;
    }

    return ProductSummary(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: _p(json['price']),
      salePrice: json['sale_price'] != null ? _p(json['sale_price']) : null,
      currency: json['currency'] as String? ?? 'TZS',
      images: imageUrls,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
