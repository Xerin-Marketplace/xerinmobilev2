import 'product_model.dart';

class RecommendedProductModel {
  final ProductModel product;
  final double matchScore;
  final String reason;

  const RecommendedProductModel({
    required this.product,
    this.matchScore = 0.0,
    this.reason = '',
  });

  factory RecommendedProductModel.fromJson(Map<String, dynamic> json) {
    return RecommendedProductModel(
      product: ProductModel.fromJson(
          json['product'] as Map<String, dynamic>? ?? json),
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class FlashDealModel {
  final ProductModel product;
  final double originalPrice;
  final double dealPrice;
  final double discountPercentage;
  final String? endDate;

  const FlashDealModel({
    required this.product,
    required this.originalPrice,
    required this.dealPrice,
    this.discountPercentage = 0.0,
    this.endDate,
  });

  factory FlashDealModel.fromJson(Map<String, dynamic> json) {
    final product = ProductModel.fromJson(
        json['product'] as Map<String, dynamic>? ?? json);
    return FlashDealModel(
      product: product,
      originalPrice: (json['original_price'] as num?)?.toDouble() ??
          product.price,
      dealPrice: (json['deal_price'] as num?)?.toDouble() ??
          product.salePrice ??
          product.price,
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      endDate: json['end_date'] as String?,
    );
  }

  String get formattedOriginalPrice {
    final formatted = originalPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${product.currency} $formatted';
  }

  String get formattedDealPrice {
    final formatted = dealPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '${product.currency} $formatted';
  }

  bool get isActive {
    if (endDate == null) return true;
    final end = DateTime.tryParse(endDate!);
    if (end == null) return true;
    return end.isAfter(DateTime.now());
  }

  Duration? get remainingTime {
    if (endDate == null) return null;
    final end = DateTime.tryParse(endDate!);
    if (end == null) return null;
    return end.difference(DateTime.now());
  }
}

class StoreModel {
  final String id;
  final String sellerId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? contactPhone;
  final String? contactEmail;
  final String? address;
  final bool isVerified;
  final double rating;
  final int totalProducts;
  final int totalFollowers;
  final bool isOpen;

  const StoreModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.contactPhone,
    this.contactEmail,
    this.address,
    this.isVerified = false,
    this.rating = 0.0,
    this.totalProducts = 0,
    this.totalFollowers = 0,
    this.isOpen = true,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      name: (json['store_name'] ?? json['name']) as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      address: json['address'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalProducts: json['total_products'] as int? ?? 0,
      totalFollowers: json['total_followers'] as int? ?? 0,
      isOpen: json['is_open'] as bool? ?? true,
    );
  }
}

class CouponModel {
  final String id;
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double maxDiscountAmount;
  final String? endDate;
  final bool isActive;
  final int usageLimit;
  final int usageCount;
  final int userUsageCount;
  final int userUsageLimit;

  const CouponModel({
    required this.id,
    required this.code,
    this.description = '',
    this.discountType = 'percentage',
    this.discountValue = 0.0,
    this.minOrderAmount = 0.0,
    this.maxDiscountAmount = 0.0,
    this.endDate,
    this.isActive = true,
    this.usageLimit = 0,
    this.usageCount = 0,
    this.userUsageCount = 0,
    this.userUsageLimit = 0,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount:
          (json['max_discount_amount'] as num?)?.toDouble() ?? 0.0,
      endDate: json['end_date'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      usageLimit: json['usage_limit'] as int? ?? 0,
      usageCount: json['usage_count'] as int? ?? 0,
      userUsageCount: json['user_usage_count'] as int? ?? 0,
      userUsageLimit: json['user_usage_limit'] as int? ?? 0,
    );
  }

  String get discountDisplay {
    if (discountType == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    final formatted = discountValue.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted OFF';
  }

  bool get isExpired {
    if (endDate == null) return false;
    final end = DateTime.tryParse(endDate!);
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  bool get isAvailable => isActive && !isExpired && (usageLimit == 0 || usageCount < usageLimit);
}
