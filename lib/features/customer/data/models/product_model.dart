import '../../../../config/constants/api_constants.dart';

double _pd(dynamic v) { if (v == null) return 0.0; if (v is num) return v.toDouble(); if (v is String) return double.tryParse(v) ?? 0.0; return 0.0; }

class ProductModel {
  final String id;
  final String sellerId;
  final String categoryId;
  final String? brandId;
  final String sku;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final String currency;
  final String? weight;
  final String status;
  final String? rejectionReason;
  final bool isActive;
  final String? createdAt;
  final String? categoryName;
  final double rating;
  final List<String> images;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    this.brandId,
    required this.sku,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    this.currency = 'TZS',
    this.weight,
    this.status = 'active',
    this.rejectionReason,
    this.isActive = true,
    this.createdAt,
    this.categoryName,
    this.rating = 0.0,
    this.images = const [],
  });

  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$currency $formatted';
  }

  String get displayPrice => formattedPrice;

  String? get thumbnailUrl => images.isNotEmpty ? ApiConstants.resolveImageUrl(images.first) : null;

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
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

    return ProductModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      brandId: json['brand_id']?.toString(),
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      price: _parsePrice(json['price']),
      salePrice: json['sale_price'] != null ? _parsePrice(json['sale_price']) : null,
      currency: json['currency'] as String? ?? 'TZS',
      weight: json['weight'] as String?,
      status: json['status'] as String? ?? 'active',
      rejectionReason: json['rejection_reason'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      categoryName: json['category_name'] as String?,
      rating: _pd(json['rating']),
      images: imageUrls,
    );
  }
}
