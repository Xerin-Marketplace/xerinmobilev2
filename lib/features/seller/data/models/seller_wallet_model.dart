import 'package:flutter/material.dart';

double _parseNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class SellerWalletModel {
  final String id;
  final String sellerId;
  final String currency;
  final double pendingBalance;
  final double availableBalance;
  final double reservedBalance;
  final double paidOutBalance;
  final double refundedBalance;
  final double debtBalance;
  final bool isFrozen;
  final String? createdAt;
  final String? updatedAt;

  const SellerWalletModel({
    required this.id,
    required this.sellerId,
    this.currency = 'TZS',
    this.pendingBalance = 0,
    this.availableBalance = 0,
    this.reservedBalance = 0,
    this.paidOutBalance = 0,
    this.refundedBalance = 0,
    this.debtBalance = 0,
    this.isFrozen = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerWalletModel.fromJson(Map<String, dynamic> json) {
    return SellerWalletModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      currency: json['currency'] as String? ?? 'TZS',
      pendingBalance: _parseNum(json['pending_balance']),
      availableBalance: _parseNum(json['available_balance']),
      reservedBalance: _parseNum(json['reserved_balance']),
      paidOutBalance: _parseNum(json['paid_out_balance']),
      refundedBalance: _parseNum(json['refunded_balance']),
      debtBalance: _parseNum(json['debt_balance']),
      isFrozen: json['is_frozen'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  double get totalBalance => pendingBalance + availableBalance + reservedBalance;
}

class WalletTransactionModel {
  final String id;
  final String walletId;
  final String transactionType;
  final double amount;
  final String currency;
  final String? reference;
  final String? description;
  final String? createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.walletId,
    required this.transactionType,
    this.amount = 0,
    this.currency = 'TZS',
    this.reference,
    this.description,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id']?.toString() ?? '',
      walletId: json['wallet_id']?.toString() ?? '',
      transactionType: json['transaction_type'] as String? ?? '',
      amount: _parseNum(json['amount']),
      currency: json['currency'] as String? ?? 'TZS',
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  bool get isCredit =>
      transactionType == 'sale_credit' ||
      transactionType == 'funds_release' ||
      transactionType == 'payout_released' ||
      transactionType == 'adjustment' && amount > 0;

  bool get isDebit =>
      transactionType == 'refund_debit' ||
      transactionType == 'payout_hold' ||
      transactionType == 'payout_completed' ||
      transactionType == 'adjustment' && amount < 0;

  String get typeLabel {
    switch (transactionType) {
      case 'sale_credit':
        return 'Sale Earning';
      case 'funds_release':
        return 'Funds Released';
      case 'payout_hold':
        return 'Payout Reserved';
      case 'payout_completed':
        return 'Payout Completed';
      case 'payout_released':
        return 'Payout Released';
      case 'refund_debit':
        return 'Refund Debit';
      case 'adjustment':
        return 'Admin Adjustment';
      default:
        return transactionType.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }

  IconData get typeIcon {
    switch (transactionType) {
      case 'sale_credit':
        return Icons.trending_up_rounded;
      case 'funds_release':
        return Icons.lock_open_rounded;
      case 'payout_hold':
        return Icons.pending_actions_rounded;
      case 'payout_completed':
        return Icons.check_circle_rounded;
      case 'payout_released':
        return Icons.undo_rounded;
      case 'refund_debit':
        return Icons.trending_down_rounded;
      case 'adjustment':
        return Icons.tune_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class WalletPayoutModel {
  final String id;
  final String sellerId;
  final String payoutAccountId;
  final double amount;
  final String currency;
  final String status;
  final String? providerReference;
  final String? sellerNote;
  final String? adminNote;
  final String? requestedAt;
  final String? processedAt;
  final String? completedAt;

  const WalletPayoutModel({
    required this.id,
    required this.sellerId,
    required this.payoutAccountId,
    this.amount = 0,
    this.currency = 'TZS',
    this.status = 'pending',
    this.providerReference,
    this.sellerNote,
    this.adminNote,
    this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory WalletPayoutModel.fromJson(Map<String, dynamic> json) {
    return WalletPayoutModel(
      id: json['id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      payoutAccountId: json['payout_account_id']?.toString() ?? '',
      amount: _parseNum(json['amount']),
      currency: json['currency'] as String? ?? 'TZS',
      status: json['status'] as String? ?? 'pending',
      providerReference: json['provider_reference'] as String?,
      sellerNote: json['seller_note'] as String?,
      adminNote: json['admin_note'] as String?,
      requestedAt: json['requested_at'] as String?,
      processedAt: json['processed_at'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get canCancel => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
