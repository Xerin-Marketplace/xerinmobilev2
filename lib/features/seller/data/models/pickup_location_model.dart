class PickupLocationModel {
  final String id;
  final String sellerId;
  final String label;
  final String formattedAddress;
  final String country;
  final String region;
  final String city;
  final String? district;
  final String? ward;
  final String? street;
  final String? landmark;
  final String? postalCode;
  final String? placeId;
  final String latitude;
  final String longitude;
  final String pickupContactName;
  final String pickupPhone;
  final String? pickupInstructions;
  final bool isDefault;
  final bool isVerified;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  const PickupLocationModel({
    required this.id,
    required this.sellerId,
    required this.label,
    required this.formattedAddress,
    required this.country,
    required this.region,
    required this.city,
    this.district,
    this.ward,
    this.street,
    this.landmark,
    this.postalCode,
    this.placeId,
    required this.latitude,
    required this.longitude,
    required this.pickupContactName,
    required this.pickupPhone,
    this.pickupInstructions,
    required this.isDefault,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory PickupLocationModel.fromJson(Map<String, dynamic> json) =>
      PickupLocationModel(
        id: json['id']?.toString() ?? '',
        sellerId: json['seller_id']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Main pickup',
        formattedAddress: json['formatted_address']?.toString() ?? '',
        country: json['country']?.toString() ?? 'Tanzania',
        region: json['region']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        district: json['district']?.toString(),
        ward: json['ward']?.toString(),
        street: json['street']?.toString(),
        landmark: json['landmark']?.toString(),
        postalCode: json['postal_code']?.toString(),
        placeId: json['place_id']?.toString(),
        latitude: json['latitude']?.toString() ?? '0',
        longitude: json['longitude']?.toString() ?? '0',
        pickupContactName: json['pickup_contact_name']?.toString() ?? '',
        pickupPhone: json['pickup_phone']?.toString() ?? '',
        pickupInstructions: json['pickup_instructions']?.toString(),
        isDefault: json['is_default'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'formatted_address': formattedAddress,
        'country': country,
        'region': region,
        'city': city,
        if (district != null) 'district': district,
        if (ward != null) 'ward': ward,
        if (street != null) 'street': street,
        if (landmark != null) 'landmark': landmark,
        if (postalCode != null) 'postal_code': postalCode,
        if (placeId != null) 'place_id': placeId,
        'latitude': latitude,
        'longitude': longitude,
        'pickup_contact_name': pickupContactName,
        'pickup_phone': pickupPhone,
        if (pickupInstructions != null) 'pickup_instructions': pickupInstructions,
        'is_default': isDefault,
        'is_active': isActive,
      };
}

class SellerFulfillmentModel {
  final String id;
  final String sellerOrderId;
  final String status;
  final String? carrier;
  final String? trackingNumber;
  final String? fulfillmentType;
  final String? pickupLocationLabel;
  final String? pickupAddress;
  final String? pickupContactName;
  final String? pickupPhone;
  final String? pickupInstructions;
  final String? estimatedPickupAt;
  final String? pickedUpAt;
  final String? dispatchedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final List<FulfillmentTrackingEvent> trackingEvents;
  final String createdAt;
  final String? updatedAt;

  const SellerFulfillmentModel({
    required this.id,
    required this.sellerOrderId,
    required this.status,
    this.carrier,
    this.trackingNumber,
    this.fulfillmentType,
    this.pickupLocationLabel,
    this.pickupAddress,
    this.pickupContactName,
    this.pickupPhone,
    this.pickupInstructions,
    this.estimatedPickupAt,
    this.pickedUpAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.trackingEvents = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerFulfillmentModel.fromJson(Map<String, dynamic> json) =>
      SellerFulfillmentModel(
        id: json['id']?.toString() ?? '',
        sellerOrderId: json['seller_order_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        carrier: json['carrier']?.toString(),
        trackingNumber: json['tracking_number']?.toString(),
        fulfillmentType: json['fulfillment_type']?.toString(),
        pickupLocationLabel: json['pickup_location_label']?.toString(),
        pickupAddress: json['pickup_address']?.toString(),
        pickupContactName: json['pickup_contact_name']?.toString(),
        pickupPhone: json['pickup_phone']?.toString(),
        pickupInstructions: json['pickup_instructions']?.toString(),
        estimatedPickupAt: json['estimated_pickup_at']?.toString(),
        pickedUpAt: json['picked_up_at']?.toString(),
        dispatchedAt: json['dispatched_at']?.toString(),
        deliveredAt: json['delivered_at']?.toString(),
        cancelledAt: json['cancelled_at']?.toString(),
        cancellationReason: json['cancellation_reason']?.toString(),
        trackingEvents: (json['tracking_events'] as List<dynamic>?)
                ?.map((e) => FulfillmentTrackingEvent.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString(),
      );
}

class FulfillmentTrackingEvent {
  final String? id;
  final String status;
  final String? description;
  final String? location;
  final String createdAt;

  const FulfillmentTrackingEvent({
    this.id,
    required this.status,
    this.description,
    this.location,
    required this.createdAt,
  });

  factory FulfillmentTrackingEvent.fromJson(Map<String, dynamic> json) =>
      FulfillmentTrackingEvent(
        id: json['id']?.toString(),
        status: json['status']?.toString() ?? '',
        description: json['description']?.toString(),
        location: json['location']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}
