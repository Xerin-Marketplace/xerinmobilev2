int _pi(dynamic v) { if (v == null) return 0; if (v is num) return v.toInt(); if (v is String) return int.tryParse(v) ?? 0; return 0; }

class StoreGalleryImageModel {
  final String id;
  final String storeId;
  final String imageUrl;
  final String? caption;
  final int displayOrder;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const StoreGalleryImageModel({
    required this.id,
    required this.storeId,
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreGalleryImageModel.fromJson(Map<String, dynamic> json) {
    return StoreGalleryImageModel(
      id: json['id']?.toString() ?? '',
      storeId: json['store_id']?.toString() ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      caption: json['caption'] as String?,
      displayOrder: _pi(json['display_order']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}
