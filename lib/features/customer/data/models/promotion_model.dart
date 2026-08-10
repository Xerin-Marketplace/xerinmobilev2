class PromotionModel {
  final String id;
  final String? sellerId;
  final String code;
  final String promotionType;
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final String? startsAt;
  final String? endsAt;
  final String? createdAt;

  const PromotionModel({
    required this.id,
    this.sellerId,
    required this.code,
    required this.promotionType,
    this.discountValue = 0.0,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimit,
    this.usageCount = 0,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    this.createdAt,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString(),
      code: json['code'] as String? ?? '',
      promotionType: json['promotion_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
      maximumDiscountAmount: (json['maximum_discount_amount'] as num?)?.toDouble(),
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class PromotionApplyResult {
  final String promotionId;
  final String code;
  final double subtotal;
  final double discountAmount;
  final double totalAfterDiscount;
  final String promotionType;

  const PromotionApplyResult({
    required this.promotionId,
    required this.code,
    this.subtotal = 0.0,
    this.discountAmount = 0.0,
    this.totalAfterDiscount = 0.0,
    this.promotionType = 'percentage',
  });

  factory PromotionApplyResult.fromJson(Map<String, dynamic> json) {
    return PromotionApplyResult(
      promotionId: json['promotion_id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      totalAfterDiscount: (json['total_after_discount'] as num?)?.toDouble() ?? 0.0,
      promotionType: json['promotion_type'] as String? ?? 'percentage',
    );
  }
}

class CampaignModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;
  final String? startsAt;
  final String? endsAt;
  final String? createdAt;

  const CampaignModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.description,
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
