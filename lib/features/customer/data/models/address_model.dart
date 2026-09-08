class AddressModel {
  final String id;
  final String? label;
  final String? recipientName;
  final String? recipientPhone;
  final String country;
  final String region;
  final String? district;
  final String? ward;
  final String city;
  final String street;
  final String? landmark;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? deliveryInstructions;
  final bool isDefault;
  final bool isActive;
  final bool isVerified;
  final bool deliveryReady;

  const AddressModel({
    required this.id,
    this.label,
    this.recipientName,
    this.recipientPhone,
    required this.country,
    required this.region,
    this.district,
    this.ward,
    required this.city,
    required this.street,
    this.landmark,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.deliveryInstructions,
    this.isDefault = false,
    this.isActive = true,
    this.isVerified = false,
    this.deliveryReady = false,
  });

  String get fullAddress => '$street, $city, $region, $country';

  String get summary => '$street, $city';

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        label: json['label'] as String?,
        recipientName: json['recipient_name'] as String?,
        recipientPhone: json['recipient_phone'] as String?,
        country: json['country'] as String? ?? '',
        region: json['region'] as String? ?? '',
        district: json['district'] as String?,
        ward: json['ward'] as String?,
        city: json['city'] as String? ?? '',
        street: json['street'] as String? ?? '',
        landmark: json['landmark'] as String?,
        postalCode: json['postal_code'] as String?,
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        formattedAddress: json['formatted_address'] as String?,
        deliveryInstructions: json['delivery_instructions'] as String?,
        isDefault: json['is_default'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        isVerified: json['is_verified'] as bool? ?? false,
        deliveryReady: json['delivery_ready'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'country': country,
        'region': region,
        'district': district,
        'ward': ward,
        'city': city,
        'street': street,
        'landmark': landmark,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'formatted_address': formattedAddress,
        'delivery_instructions': deliveryInstructions,
        'is_default': isDefault,
        'is_active': isActive,
      };

  String get coordinates =>
      latitude != null && longitude != null
          ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
          : '';

  bool get hasGps => latitude != null && longitude != null;
}
