class DeliveryProofModel {
  final String id;
  final String shipmentId;
  final String orderId;
  final String customerId;
  final String logisticsCompanyId;
  final String status;
  final String recipientName;
  final String? recipientPhoneLast4;
  final String photoUrl;
  final String deliveryLatitude;
  final String deliveryLongitude;
  final String destinationLatitude;
  final String destinationLongitude;
  final String distanceFromDestinationMeters;
  final String? otpExpiresAt;
  final int otpAttempts;
  final String? notes;
  final String? verifiedAt;
  final String? disputedAt;
  final String? disputeReason;
  final String? disputeNotes;
  final String settlementStatus;
  final String createdAt;
  final String? updatedAt;
  final List<DeliveryProofEventModel> events;

  const DeliveryProofModel({
    required this.id,
    required this.shipmentId,
    required this.orderId,
    required this.customerId,
    required this.logisticsCompanyId,
    required this.status,
    required this.recipientName,
    this.recipientPhoneLast4,
    required this.photoUrl,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distanceFromDestinationMeters,
    this.otpExpiresAt,
    required this.otpAttempts,
    this.notes,
    this.verifiedAt,
    this.disputedAt,
    this.disputeReason,
    this.disputeNotes,
    required this.settlementStatus,
    required this.createdAt,
    this.updatedAt,
    this.events = const [],
  });

  factory DeliveryProofModel.fromJson(Map<String, dynamic> json) =>
      DeliveryProofModel(
        id: json['id']?.toString() ?? '',
        shipmentId: json['shipment_id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        customerId: json['customer_id']?.toString() ?? '',
        logisticsCompanyId: json['logistics_company_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        recipientName: json['recipient_name']?.toString() ?? '',
        recipientPhoneLast4: json['recipient_phone_last4']?.toString(),
        photoUrl: json['photo_url']?.toString() ?? '',
        deliveryLatitude: json['delivery_latitude']?.toString() ?? '0',
        deliveryLongitude: json['delivery_longitude']?.toString() ?? '0',
        destinationLatitude: json['destination_latitude']?.toString() ?? '0',
        destinationLongitude: json['destination_longitude']?.toString() ?? '0',
        distanceFromDestinationMeters:
            json['distance_from_destination_meters']?.toString() ?? '0',
        otpExpiresAt: json['otp_expires_at']?.toString(),
        otpAttempts: json['otp_attempts'] as int? ?? 0,
        notes: json['notes']?.toString(),
        verifiedAt: json['verified_at']?.toString(),
        disputedAt: json['disputed_at']?.toString(),
        disputeReason: json['dispute_reason']?.toString(),
        disputeNotes: json['dispute_notes']?.toString(),
        settlementStatus: json['settlement_status']?.toString() ?? 'pending',
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString(),
        events: (json['events'] as List<dynamic>?)
                ?.map((e) => DeliveryProofEventModel.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class DeliveryProofEventModel {
  final String? id;
  final String eventType;
  final String? description;
  final String createdAt;

  const DeliveryProofEventModel({
    this.id,
    required this.eventType,
    this.description,
    required this.createdAt,
  });

  factory DeliveryProofEventModel.fromJson(Map<String, dynamic> json) =>
      DeliveryProofEventModel(
        id: json['id']?.toString(),
        eventType: json['event_type']?.toString() ?? '',
        description: json['description']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}
