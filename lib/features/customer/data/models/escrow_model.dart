import 'package:equatable/equatable.dart';

class EscrowItemSummary extends Equatable {
  final String orderItemId;
  final String? sellerId;
  final String status;
  final num sellerAmount;
  final num releasedAmount;
  final num remainingAmount;
  final String? releaseAfter;
  final bool canCustomerAccept;
  final bool canReportProblem;

  const EscrowItemSummary({
    required this.orderItemId,
    this.sellerId,
    required this.status,
    required this.sellerAmount,
    required this.releasedAmount,
    required this.remainingAmount,
    this.releaseAfter,
    required this.canCustomerAccept,
    required this.canReportProblem,
  });

  factory EscrowItemSummary.fromJson(Map<String, dynamic> json) =>
      EscrowItemSummary(
        orderItemId: json['order_item_id']?.toString() ?? '',
        sellerId: json['seller_id']?.toString(),
        status: json['status']?.toString() ?? 'held',
        sellerAmount: json['seller_amount'] is num
            ? json['seller_amount'] as num
            : num.tryParse(json['seller_amount']?.toString() ?? '0') ?? 0,
        releasedAmount: json['released_amount'] is num
            ? json['released_amount'] as num
            : num.tryParse(json['released_amount']?.toString() ?? '0') ?? 0,
        remainingAmount: json['remaining_amount'] is num
            ? json['remaining_amount'] as num
            : num.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0,
        releaseAfter: json['release_after']?.toString(),
        canCustomerAccept: json['can_customer_accept'] as bool? ?? false,
        canReportProblem: json['can_report_problem'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        orderItemId,
        sellerId,
        status,
        sellerAmount,
        releasedAmount,
        remainingAmount,
        releaseAfter,
        canCustomerAccept,
        canReportProblem,
      ];
}

class EscrowSummary extends Equatable {
  final String orderId;
  final String currency;
  final String status;
  final int holdCount;
  final num grossAmount;
  final num sellerAmount;
  final num commissionAmount;
  final num releasedAmount;
  final num remainingAmount;
  final String? releaseAfter;
  final String? deliveryVerifiedAt;
  final int? sellerReleaseGraceHours;
  final bool allowCustomerEarlyAcceptance;
  final bool canCustomerApprove;
  final bool canReportProblem;
  final List<EscrowItemSummary> items;

  const EscrowSummary({
    required this.orderId,
    required this.currency,
    required this.status,
    required this.holdCount,
    required this.grossAmount,
    required this.sellerAmount,
    required this.commissionAmount,
    required this.releasedAmount,
    required this.remainingAmount,
    this.releaseAfter,
    this.deliveryVerifiedAt,
    this.sellerReleaseGraceHours,
    required this.allowCustomerEarlyAcceptance,
    required this.canCustomerApprove,
    required this.canReportProblem,
    required this.items,
  });

  factory EscrowSummary.fromJson(Map<String, dynamic> json) => EscrowSummary(
        orderId: json['order_id']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'TZS',
        status: json['status']?.toString() ?? 'not_applicable',
        holdCount: json['hold_count'] as int? ?? 0,
        grossAmount: json['gross_amount'] is num
            ? json['gross_amount'] as num
            : num.tryParse(json['gross_amount']?.toString() ?? '0') ?? 0,
        sellerAmount: json['seller_amount'] is num
            ? json['seller_amount'] as num
            : num.tryParse(json['seller_amount']?.toString() ?? '0') ?? 0,
        commissionAmount: json['commission_amount'] is num
            ? json['commission_amount'] as num
            : num.tryParse(json['commission_amount']?.toString() ?? '0') ?? 0,
        releasedAmount: json['released_amount'] is num
            ? json['released_amount'] as num
            : num.tryParse(json['released_amount']?.toString() ?? '0') ?? 0,
        remainingAmount: json['remaining_amount'] is num
            ? json['remaining_amount'] as num
            : num.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0,
        releaseAfter: json['release_after']?.toString(),
        deliveryVerifiedAt: json['delivery_verified_at']?.toString(),
        sellerReleaseGraceHours: json['seller_release_grace_hours'] as int?,
        allowCustomerEarlyAcceptance:
            json['allow_customer_early_acceptance'] as bool? ?? false,
        canCustomerApprove: json['can_customer_approve'] as bool? ?? false,
        canReportProblem: json['can_report_problem'] as bool? ?? false,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => EscrowItemSummary.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props => [
        orderId,
        currency,
        status,
        holdCount,
        grossAmount,
        sellerAmount,
        commissionAmount,
        releasedAmount,
        remainingAmount,
        releaseAfter,
        deliveryVerifiedAt,
        sellerReleaseGraceHours,
        allowCustomerEarlyAcceptance,
        canCustomerApprove,
        canReportProblem,
        items,
      ];
}
