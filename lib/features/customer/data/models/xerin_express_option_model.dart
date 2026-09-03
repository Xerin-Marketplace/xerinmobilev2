import 'package:equatable/equatable.dart';

class XerinExpressOption extends Equatable {
  final String tier;
  final String label;
  final num deliveryAmount;
  final String currency;
  final int promisedDeliveryMinutes;
  final String logisticsCompanyId;
  final String logisticsCompanyName;
  final String rateId;
  final String methodId;
  final bool supportsCod;
  final bool supportsTracking;

  const XerinExpressOption({
    required this.tier,
    required this.label,
    required this.deliveryAmount,
    required this.currency,
    required this.promisedDeliveryMinutes,
    required this.logisticsCompanyId,
    required this.logisticsCompanyName,
    required this.rateId,
    required this.methodId,
    required this.supportsCod,
    required this.supportsTracking,
  });

  bool get isExpress => tier == 'express';

  factory XerinExpressOption.fromJson(Map<String, dynamic> json) =>
      XerinExpressOption(
        tier: json['tier']?.toString() ?? 'standard',
        label: json['label']?.toString() ?? '',
        deliveryAmount: json['delivery_amount'] is num
            ? json['delivery_amount'] as num
            : num.tryParse(json['delivery_amount']?.toString() ?? '0') ?? 0,
        currency: json['currency']?.toString() ?? 'TZS',
        promisedDeliveryMinutes:
            json['promised_delivery_minutes'] as int? ?? 0,
        logisticsCompanyId: json['logistics_company_id']?.toString() ?? '',
        logisticsCompanyName:
            json['logistics_company_name']?.toString() ?? '',
        rateId: json['rate_id']?.toString() ?? '',
        methodId: json['method_id']?.toString() ?? '',
        supportsCod: json['supports_cod'] as bool? ?? false,
        supportsTracking: json['supports_tracking'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        tier,
        label,
        deliveryAmount,
        currency,
        promisedDeliveryMinutes,
        logisticsCompanyId,
        logisticsCompanyName,
        rateId,
        methodId,
        supportsCod,
        supportsTracking,
      ];
}
