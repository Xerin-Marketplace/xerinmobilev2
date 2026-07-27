class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final String currency;
  final String method;
  final String? provider;
  final String status;
  final String? providerTransactionId;
  final String? paidAt;
  final List<PaymentTransactionModel> transactions;
  final String? createdAt;
  final String? updatedAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    this.amount = 0.0,
    this.currency = 'TZS',
    required this.method,
    this.provider,
    required this.status,
    this.providerTransactionId,
    this.paidAt,
    this.transactions = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get formattedAmount {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final txList = json['transactions'] as List<dynamic>? ?? [];
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      amount: _parsePrice(json['amount']),
      currency: json['currency'] as String? ?? 'TZS',
      method: json['method'] as String? ?? '',
      provider: json['provider'] as String?,
      status: json['status'] as String? ?? 'pending',
      providerTransactionId: json['provider_transaction_id'] as String?,
      paidAt: json['paid_at'] as String?,
      transactions: txList
          .map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}

class PaymentTransactionModel {
  final String id;
  final String transactionType;
  final String status;
  final double? amount;
  final Map<String, dynamic>? providerResponse;
  final String? createdAt;

  const PaymentTransactionModel({
    required this.id,
    required this.transactionType,
    required this.status,
    this.amount,
    this.providerResponse,
    this.createdAt,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: json['amount'] != null
          ? (json['amount'] as num?)?.toDouble()
          : null,
      providerResponse: json['provider_response'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String?,
    );
  }
}
