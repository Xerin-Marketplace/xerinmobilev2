class BrokerModel {
  final String id;
  final String userId;
  final String brokerCode;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String country;
  final String region;
  final String city;
  final String? nidaNumber;
  final String status;
  final String? approvedAt;
  final String? rejectedAt;
  final String? suspendedAt;
  final String? statusReason;
  final String createdAt;

  BrokerModel({
    required this.id,
    required this.userId,
    required this.brokerCode,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    required this.country,
    required this.region,
    required this.city,
    this.nidaNumber,
    required this.status,
    this.approvedAt,
    this.rejectedAt,
    this.suspendedAt,
    this.statusReason,
    required this.createdAt,
  });

  factory BrokerModel.fromJson(Map<String, dynamic> json) {
    return BrokerModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      brokerCode: json['broker_code']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      country: json['country']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      nidaNumber: json['nida_number']?.toString(),
      status: json['status']?.toString() ?? 'pending_kyc',
      approvedAt: json['approved_at']?.toString(),
      rejectedAt: json['rejected_at']?.toString(),
      suspendedAt: json['suspended_at']?.toString(),
      statusReason: json['status_reason']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';
  bool get isPending => status == 'pending_kyc';
  bool get isKycSubmitted => status == 'kyc_submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isRejected => status == 'rejected';
}

class BrokerKycStatusModel {
  final String brokerStatus;
  final List<String> requiredDocuments;
  final List<String> uploadedDocuments;
  final List<String> missingDocuments;
  final bool canSubmitForReview;
  final bool canUseBrokerFeatures;

  BrokerKycStatusModel({
    required this.brokerStatus,
    required this.requiredDocuments,
    required this.uploadedDocuments,
    required this.missingDocuments,
    required this.canSubmitForReview,
    required this.canUseBrokerFeatures,
  });

  factory BrokerKycStatusModel.fromJson(Map<String, dynamic> json) {
    return BrokerKycStatusModel(
      brokerStatus: json['broker_status']?.toString() ?? 'pending_kyc',
      requiredDocuments: (json['required_documents'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      uploadedDocuments: (json['uploaded_documents'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      missingDocuments: (json['missing_documents'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      canSubmitForReview: json['can_submit_for_review'] as bool? ?? false,
      canUseBrokerFeatures: json['can_use_broker_features'] as bool? ?? false,
    );
  }
}

class BrokerKycDocumentModel {
  final String id;
  final String brokerId;
  final String documentType;
  final String? originalFilename;
  final String? mimeType;
  final String status;
  final String? rejectionReason;
  final String? reviewedAt;
  final String createdAt;

  BrokerKycDocumentModel({
    required this.id,
    required this.brokerId,
    required this.documentType,
    this.originalFilename,
    this.mimeType,
    required this.status,
    this.rejectionReason,
    this.reviewedAt,
    required this.createdAt,
  });

  factory BrokerKycDocumentModel.fromJson(Map<String, dynamic> json) {
    return BrokerKycDocumentModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      originalFilename: json['original_filename']?.toString(),
      mimeType: json['mime_type']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejection_reason']?.toString(),
      reviewedAt: json['reviewed_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class BrokerWalletModel {
  final String id;
  final String brokerId;
  final String currency;
  final String pendingBalance;
  final String availableBalance;
  final String reservedBalance;
  final String paidOutBalance;
  final String reversedBalance;
  final String debtBalance;
  final bool isFrozen;
  final String createdAt;
  final String? updatedAt;

  BrokerWalletModel({
    required this.id,
    required this.brokerId,
    required this.currency,
    required this.pendingBalance,
    required this.availableBalance,
    required this.reservedBalance,
    required this.paidOutBalance,
    required this.reversedBalance,
    required this.debtBalance,
    required this.isFrozen,
    required this.createdAt,
    this.updatedAt,
  });

  factory BrokerWalletModel.fromJson(Map<String, dynamic> json) {
    return BrokerWalletModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'TZS',
      pendingBalance: json['pending_balance']?.toString() ?? '0',
      availableBalance: json['available_balance']?.toString() ?? '0',
      reservedBalance: json['reserved_balance']?.toString() ?? '0',
      paidOutBalance: json['paid_out_balance']?.toString() ?? '0',
      reversedBalance: json['reversed_balance']?.toString() ?? '0',
      debtBalance: json['debt_balance']?.toString() ?? '0',
      isFrozen: json['is_frozen'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class BrokerCommissionSummaryModel {
  final String currency;
  final String pendingAmount;
  final String availableAmount;
  final String reversedAmount;
  final String lifetimeCommission;
  final int totalRecords;

  BrokerCommissionSummaryModel({
    required this.currency,
    required this.pendingAmount,
    required this.availableAmount,
    required this.reversedAmount,
    required this.lifetimeCommission,
    required this.totalRecords,
  });

  factory BrokerCommissionSummaryModel.fromJson(Map<String, dynamic> json) {
    return BrokerCommissionSummaryModel(
      currency: json['currency']?.toString() ?? 'TZS',
      pendingAmount: json['pending_amount']?.toString() ?? '0',
      availableAmount: json['available_amount']?.toString() ?? '0',
      reversedAmount: json['reversed_amount']?.toString() ?? '0',
      lifetimeCommission: json['lifetime_commission']?.toString() ?? '0',
      totalRecords: json['total_records'] as int? ?? 0,
    );
  }
}

class BrokerAnalyticsOverviewModel {
  final String currency;
  final int periodDays;
  final int totalClicks;
  final int uniqueVisitors;
  final int attributedCustomers;
  final int attributedOrders;
  final int successfulSales;
  final int refundedSales;
  final String conversionRate;
  final String pendingEarnings;
  final String availableEarnings;
  final String lifetimeEarnings;
  final String walletAvailable;
  final String walletPending;
  final String walletPaidOut;
  final int currentlyPromoting;
  final int availableOpportunities;
  final int ownProductsActive;
  final int ownProductsExpired;
  final int ownProductsDraft;

  BrokerAnalyticsOverviewModel({
    required this.currency,
    required this.periodDays,
    required this.totalClicks,
    required this.uniqueVisitors,
    required this.attributedCustomers,
    required this.attributedOrders,
    required this.successfulSales,
    required this.refundedSales,
    required this.conversionRate,
    required this.pendingEarnings,
    required this.availableEarnings,
    required this.lifetimeEarnings,
    required this.walletAvailable,
    required this.walletPending,
    required this.walletPaidOut,
    required this.currentlyPromoting,
    required this.availableOpportunities,
    required this.ownProductsActive,
    required this.ownProductsExpired,
    required this.ownProductsDraft,
  });

  factory BrokerAnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return BrokerAnalyticsOverviewModel(
      currency: json['currency']?.toString() ?? 'TZS',
      periodDays: json['period_days'] as int? ?? 30,
      totalClicks: json['total_clicks'] as int? ?? 0,
      uniqueVisitors: json['unique_visitors'] as int? ?? 0,
      attributedCustomers: json['attributed_customers'] as int? ?? 0,
      attributedOrders: json['attributed_orders'] as int? ?? 0,
      successfulSales: json['successful_sales'] as int? ?? 0,
      refundedSales: json['refunded_sales'] as int? ?? 0,
      conversionRate: json['conversion_rate']?.toString() ?? '0',
      pendingEarnings: json['pending_earnings']?.toString() ?? '0',
      availableEarnings: json['available_earnings']?.toString() ?? '0',
      lifetimeEarnings: json['lifetime_earnings']?.toString() ?? '0',
      walletAvailable: json['wallet_available']?.toString() ?? '0',
      walletPending: json['wallet_pending']?.toString() ?? '0',
      walletPaidOut: json['wallet_paid_out']?.toString() ?? '0',
      currentlyPromoting: json['currently_promoting'] as int? ?? 0,
      availableOpportunities: json['available_opportunities'] as int? ?? 0,
      ownProductsActive: json['own_products_active'] as int? ?? 0,
      ownProductsExpired: json['own_products_expired'] as int? ?? 0,
      ownProductsDraft: json['own_products_draft'] as int? ?? 0,
    );
  }
}

class BrokerOpportunityModel {
  final String offerId;
  final String productId;
  final String productName;
  final String? productImage;
  final String commissionType;
  final String commissionValue;
  final String estimatedRewardPerUnit;
  final String estimatedSellerNetPerUnit;
  final int availableQuantity;
  final bool alreadyAccepted;
  final bool isActive;
  final String startsAt;
  final String? endsAt;

  BrokerOpportunityModel({
    required this.offerId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.commissionType,
    required this.commissionValue,
    required this.estimatedRewardPerUnit,
    required this.estimatedSellerNetPerUnit,
    required this.availableQuantity,
    required this.alreadyAccepted,
    required this.isActive,
    required this.startsAt,
    this.endsAt,
  });

  factory BrokerOpportunityModel.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] as Map<String, dynamic>? ?? {};
    final product = json['product'] as Map<String, dynamic>? ?? {};
    return BrokerOpportunityModel(
      offerId: offer['id']?.toString() ?? '',
      productId: product['id']?.toString() ?? '',
      productName: product['name']?.toString() ?? '',
      productImage: product['image_url']?.toString(),
      commissionType: offer['commission_type']?.toString() ?? 'fixed',
      commissionValue: offer['commission_value']?.toString() ?? '0',
      estimatedRewardPerUnit:
          offer['estimated_reward_per_unit']?.toString() ?? '0',
      estimatedSellerNetPerUnit:
          offer['estimated_seller_net_per_unit']?.toString() ?? '0',
      availableQuantity: json['available_quantity'] as int? ?? 0,
      alreadyAccepted: json['already_accepted'] as bool? ?? false,
      isActive: offer['is_active'] as bool? ?? false,
      startsAt: offer['starts_at']?.toString() ?? '',
      endsAt: offer['ends_at']?.toString(),
    );
  }
}

class BrokerPayoutAccountModel {
  final String id;
  final String brokerId;
  final String accountType;
  final String provider;
  final String accountName;
  final String accountNumber;
  final String currency;
  final bool isDefault;
  final bool isActive;
  final String verificationStatus;
  final String? verificationNote;
  final String? verifiedAt;
  final String createdAt;

  BrokerPayoutAccountModel({
    required this.id,
    required this.brokerId,
    required this.accountType,
    required this.provider,
    required this.accountName,
    required this.accountNumber,
    required this.currency,
    required this.isDefault,
    required this.isActive,
    required this.verificationStatus,
    this.verificationNote,
    this.verifiedAt,
    required this.createdAt,
  });

  factory BrokerPayoutAccountModel.fromJson(Map<String, dynamic> json) {
    return BrokerPayoutAccountModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? 'mobile_money',
      provider: json['provider']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'TZS',
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      verificationStatus: json['verification_status']?.toString() ?? 'pending',
      verificationNote: json['verification_note']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class BrokerProductModel {
  final String id;
  final String brokerId;
  final String categoryId;
  final String? brandId;
  final String sku;
  final String name;
  final String slug;
  final String? description;
  final String price;
  final String? salePrice;
  final String currency;
  final String? weight;
  final String status;
  final bool isActive;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final String? fulfillmentLocation;
  final String createdAt;
  final String? primaryImageUrl;

  BrokerProductModel({
    required this.id,
    required this.brokerId,
    required this.categoryId,
    this.brandId,
    required this.sku,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    required this.currency,
    this.weight,
    required this.status,
    required this.isActive,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    this.fulfillmentLocation,
    required this.createdAt,
    this.primaryImageUrl,
  });

  factory BrokerProductModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? [];
    String? primaryImage;
    for (final img in images) {
      final imgMap = img as Map<String, dynamic>;
      if (imgMap['is_primary'] == true) {
        primaryImage = imgMap['image_url']?.toString();
        break;
      }
    }
    primaryImage ??= images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['image_url']?.toString()
        : null;

    return BrokerProductModel(
      id: json['id']?.toString() ?? '',
      brokerId: json['broker_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      brandId: json['brand_id']?.toString(),
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      price: json['price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString(),
      currency: json['currency']?.toString() ?? 'TZS',
      weight: json['weight']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      isActive: json['is_active'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 0,
      reservedQuantity: json['reserved_quantity'] as int? ?? 0,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      fulfillmentLocation: json['fulfillment_location']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      primaryImageUrl: primaryImage,
    );
  }
}
