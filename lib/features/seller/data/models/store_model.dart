import 'store_gallery_image_model.dart';
import 'store_opening_hour_model.dart';

double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class StoreModel {
  final String id;
  final String sellerId;
  final String storeName;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String? websiteUrl;
  final String? country;
  final String? region;
  final String? district;
  final String? ward;
  final String? street;
  final double? latitude;
  final double? longitude;
  final String? openingTime;
  final String? closingTime;
  final String? shippingPolicy;
  final String? returnPolicy;
  final String? privacyPolicy;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? tiktokUrl;
  final String? youtubeUrl;
  final String status;
  final bool isVerified;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final int followersCount;
  final List<StoreGalleryImageModel> galleryImages;
  final List<StoreOpeningHourModel> openingHours;
  final String? createdAt;
  final String? updatedAt;

  const StoreModel({
    required this.id,
    required this.sellerId,
    required this.storeName,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.contactEmail,
    this.contactPhone,
    this.websiteUrl,
    this.country,
    this.region,
    this.district,
    this.ward,
    this.street,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
    this.shippingPolicy,
    this.returnPolicy,
    this.privacyPolicy,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.tiktokUrl,
    this.youtubeUrl,
    this.status = 'draft',
    this.isVerified = false,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.followersCount = 0,
    this.galleryImages = const [],
    this.openingHours = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      storeName: json['store_name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      websiteUrl: json['website_url'] as String?,
      country: json['country'] as String?,
      region: json['region'] as String?,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      street: json['street'] as String?,
      latitude: json['latitude'] == null ? null : _parseDouble(json['latitude']),
      longitude: json['longitude'] == null ? null : _parseDouble(json['longitude']),
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      shippingPolicy: json['shipping_policy'] as String?,
      returnPolicy: json['return_policy'] as String?,
      privacyPolicy: json['privacy_policy'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      instagramUrl: json['instagram_url'] as String?,
      twitterUrl: json['twitter_url'] as String?,
      tiktokUrl: json['tiktok_url'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      status: json['status'] as String? ?? 'draft',
      isVerified: json['is_verified'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['review_count']),
      followersCount: _parseInt(json['followers_count']),
      galleryImages: (json['gallery_images'] as List<dynamic>?)
              ?.map((e) => StoreGalleryImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      openingHours: (json['opening_hours'] as List<dynamic>?)
              ?.map((e) => StoreOpeningHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'store_name': storeName,
        'description': description,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'website_url': websiteUrl,
        'country': country,
        'region': region,
        'district': district,
        'ward': ward,
        'street': street,
        'latitude': latitude,
        'longitude': longitude,
        'opening_time': openingTime,
        'closing_time': closingTime,
        'shipping_policy': shippingPolicy,
        'return_policy': returnPolicy,
        'privacy_policy': privacyPolicy,
        'facebook_url': facebookUrl,
        'instagram_url': instagramUrl,
        'twitter_url': twitterUrl,
        'tiktok_url': tiktokUrl,
        'youtube_url': youtubeUrl,
      };
}
