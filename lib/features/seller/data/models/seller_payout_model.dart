class SellerPayoutAccountModel {
  final String id;
  final String sellerId;
  final String accountType;
  final String provider;
  final String accountName;
  final String accountNumber;
  final String currency;
  final bool isDefault;
  final String? createdAt;

  const SellerPayoutAccountModel({
    required this.id,
    required this.sellerId,
    required this.accountType,
    required this.provider,
    required this.accountName,
    required this.accountNumber,
    this.currency = 'TZS',
    this.isDefault = false,
    this.createdAt,
  });

  factory SellerPayoutAccountModel.fromJson(Map<String, dynamic> json) {
    return SellerPayoutAccountModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      accountType: json['account_type'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      currency: json['currency'] as String? ?? 'TZS',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'account_type': accountType,
        'provider': provider,
        'account_name': accountName,
        'account_number': accountNumber,
        'currency': currency,
        'is_default': isDefault,
      };
}
