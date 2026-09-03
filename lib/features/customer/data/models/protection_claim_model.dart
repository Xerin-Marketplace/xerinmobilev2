import 'package:equatable/equatable.dart';

class ProtectionClaim extends Equatable {
  final String id;
  final String orderId;
  final String customerId;
  final String? orderItemId;
  final String scope;
  final String reason;
  final String? notes;
  final String? whenNoticed;
  final bool? packageDamaged;
  final bool? productUsed;
  final List<String> evidenceUrls;
  final String likelyResponsibility;
  final String status;
  final bool holdApplied;
  final String? adminResolutionNote;
  final String? resolvedAt;
  final String createdAt;

  const ProtectionClaim({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.orderItemId,
    required this.scope,
    required this.reason,
    this.notes,
    this.whenNoticed,
    this.packageDamaged,
    this.productUsed,
    required this.evidenceUrls,
    required this.likelyResponsibility,
    required this.status,
    required this.holdApplied,
    this.adminResolutionNote,
    this.resolvedAt,
    required this.createdAt,
  });

  factory ProtectionClaim.fromJson(Map<String, dynamic> json) =>
      ProtectionClaim(
        id: json['id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        customerId: json['customer_id']?.toString() ?? '',
        orderItemId: json['order_item_id']?.toString(),
        scope: json['scope']?.toString() ?? 'order',
        reason: json['reason']?.toString() ?? 'other',
        notes: json['notes']?.toString(),
        whenNoticed: json['when_noticed']?.toString(),
        packageDamaged: json['package_damaged'] as bool?,
        productUsed: json['product_used'] as bool?,
        evidenceUrls: (json['evidence_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        likelyResponsibility:
            json['likely_responsibility']?.toString() ?? 'unknown',
        status: json['status']?.toString() ?? 'pending',
        holdApplied: json['hold_applied'] as bool? ?? false,
        adminResolutionNote: json['admin_resolution_note']?.toString(),
        resolvedAt: json['resolved_at']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        orderId,
        customerId,
        orderItemId,
        scope,
        reason,
        notes,
        whenNoticed,
        packageDamaged,
        productUsed,
        evidenceUrls,
        likelyResponsibility,
        status,
        holdApplied,
        adminResolutionNote,
        resolvedAt,
        createdAt,
      ];
}
