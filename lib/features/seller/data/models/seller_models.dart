double _pd(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
  return 0.0;
}

int _pi(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _ps(dynamic v) => v?.toString() ?? '';

// ─── Seller Profile ───
class SellerModel {
  final String id;
  final String? userId;
  final String businessName;
  final String? businessCategory;
  final String? contactEmail;
  final String? contactPhone;
  final String status;
  final bool isVerified;
  final String? rejectionReason;
  final String? createdAt;

  const SellerModel({
    required this.id,
    this.userId,
    required this.businessName,
    this.businessCategory,
    this.contactEmail,
    this.contactPhone,
    this.status = 'pending',
    this.isVerified = false,
    this.rejectionReason,
    this.createdAt,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: _ps(json['id']),
      userId: json['user_id']?.toString(),
      businessName: _ps(json['business_name']),
      businessCategory: json['business_category'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      status: _ps(json['status']),
      isVerified: json['is_verified'] as bool? ?? false,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class SellerBusinessProfileModel {
  final String id;
  final String sellerId;
  final String? businessDescription;
  final String? businessCountry;
  final String? businessRegion;
  final String? businessCity;
  final String? businessAddress;
  final String? productDescription;
  final String? yearsInBusiness;
  final String? websiteUrl;
  final String createdAt;

  const SellerBusinessProfileModel({
    required this.id,
    required this.sellerId,
    this.businessDescription,
    this.businessCountry,
    this.businessRegion,
    this.businessCity,
    this.businessAddress,
    this.productDescription,
    this.yearsInBusiness,
    this.websiteUrl,
    required this.createdAt,
  });

  factory SellerBusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return SellerBusinessProfileModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      businessDescription: json['business_description'] as String?,
      businessCountry: json['business_country'] as String?,
      businessRegion: json['business_region'] as String?,
      businessCity: json['business_city'] as String?,
      businessAddress: json['business_address'] as String?,
      productDescription: json['product_description'] as String?,
      yearsInBusiness: json['years_in_business'] as String?,
      websiteUrl: json['website_url'] as String?,
      createdAt: _ps(json['created_at']),
    );
  }
}

class BusinessCategoryModel {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final bool active;

  const BusinessCategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.active = true,
  });

  factory BusinessCategoryModel.fromJson(Map<String, dynamic> json) {
    return BusinessCategoryModel(
      id: _ps(json['id']),
      name: _ps(json['name']),
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

// ─── KYC ───
class SellerKycDocumentModel {
  final String id;
  final String? sellerId;
  final String documentType;
  final String? documentUrl;
  final String? fileUrl;
  final String? mimeType;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  const SellerKycDocumentModel({
    required this.id,
    this.sellerId,
    required this.documentType,
    this.documentUrl,
    this.fileUrl,
    this.mimeType,
    this.status = 'pending',
    this.rejectionReason,
    this.createdAt,
  });

  factory SellerKycDocumentModel.fromJson(Map<String, dynamic> json) {
    return SellerKycDocumentModel(
      id: _ps(json['id']),
      sellerId: json['seller_id']?.toString(),
      documentType: _ps(json['document_type']),
      documentUrl: json['document_url'] as String?,
      fileUrl: json['file_url'] as String?,
      mimeType: json['mime_type'] as String?,
      status: _ps(json['status']),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class SellerKycStatusModel {
  final String? sellerStatus;
  final List<String> requiredDocuments;
  final List<String> uploadedDocuments;
  final List<String> missingDocuments;
  final bool canSubmitForReview;

  const SellerKycStatusModel({
    this.sellerStatus,
    this.requiredDocuments = const [],
    this.uploadedDocuments = const [],
    this.missingDocuments = const [],
    this.canSubmitForReview = false,
  });

  factory SellerKycStatusModel.fromJson(Map<String, dynamic> json) {
    return SellerKycStatusModel(
      sellerStatus: json['seller_status'] as String?,
      requiredDocuments: (json['required_documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
      uploadedDocuments: (json['uploaded_documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
      missingDocuments: (json['missing_documents'] as List?)?.map((e) => e.toString()).toList() ?? [],
      canSubmitForReview: json['can_submit_for_review'] as bool? ?? false,
    );
  }
}

// ─── Payout Account ───
class PayoutAccountModel {
  final String id;
  final String? sellerId;
  final String accountType;
  final String provider;
  final String accountName;
  final String accountNumber;
  final String currency;
  final bool isDefault;
  final bool isActive;
  final String? verificationStatus;
  final String? providerReference;
  final String? verifiedAt;
  final String? createdAt;

  const PayoutAccountModel({
    required this.id,
    this.sellerId,
    required this.accountType,
    required this.provider,
    required this.accountName,
    required this.accountNumber,
    this.currency = 'TZS',
    this.isDefault = false,
    this.isActive = true,
    this.verificationStatus,
    this.providerReference,
    this.verifiedAt,
    this.createdAt,
  });

  factory PayoutAccountModel.fromJson(Map<String, dynamic> json) {
    return PayoutAccountModel(
      id: _ps(json['id']),
      sellerId: json['seller_id']?.toString(),
      accountType: _ps(json['account_type']),
      provider: _ps(json['provider']),
      accountName: _ps(json['account_name']),
      accountNumber: _ps(json['account_number']),
      currency: _ps(json['currency']),
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      verificationStatus: json['verification_status'] as String?,
      providerReference: json['provider_reference'] as String?,
      verifiedAt: json['verified_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

// ─── Dashboard Performance ───
class SellerDashboardPerformanceModel {
  final int productsTotal;
  final int productsApproved;
  final int productsPendingReview;
  final int activePromotions;
  final int ordersTotal;
  final int ordersNew;
  final int ordersProcessing;
  final int ordersReadyToShip;
  final String walletCurrency;
  final double walletPending;
  final double walletAvailable;
  final double walletReserved;
  final int pendingPayouts;
  final double ratingAverage;
  final int reviewCount;
  final int unansweredQuestions;

  const SellerDashboardPerformanceModel({
    this.productsTotal = 0,
    this.productsApproved = 0,
    this.productsPendingReview = 0,
    this.activePromotions = 0,
    this.ordersTotal = 0,
    this.ordersNew = 0,
    this.ordersProcessing = 0,
    this.ordersReadyToShip = 0,
    this.walletCurrency = 'TZS',
    this.walletPending = 0.0,
    this.walletAvailable = 0.0,
    this.walletReserved = 0.0,
    this.pendingPayouts = 0,
    this.ratingAverage = 0.0,
    this.reviewCount = 0,
    this.unansweredQuestions = 0,
  });

  factory SellerDashboardPerformanceModel.fromJson(Map<String, dynamic> json) {
    return SellerDashboardPerformanceModel(
      productsTotal: _pi(json['products_total']),
      productsApproved: _pi(json['products_approved']),
      productsPendingReview: _pi(json['products_pending_review']),
      activePromotions: _pi(json['active_promotions']),
      ordersTotal: _pi(json['orders_total']),
      ordersNew: _pi(json['orders_new']),
      ordersProcessing: _pi(json['orders_processing']),
      ordersReadyToShip: _pi(json['orders_ready_to_ship']),
      walletCurrency: _ps(json['wallet_currency']),
      walletPending: _pd(json['wallet_pending']),
      walletAvailable: _pd(json['wallet_available']),
      walletReserved: _pd(json['wallet_reserved']),
      pendingPayouts: _pi(json['pending_payouts']),
      ratingAverage: _pd(json['rating_average']),
      reviewCount: _pi(json['review_count']),
      unansweredQuestions: _pi(json['unanswered_questions']),
    );
  }
}

// ─── Seller Orders ───
class SellerOrderItemModel {
  final String id;
  final String productId;
  final String? variantId;
  final String storeId;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const SellerOrderItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.storeId,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory SellerOrderItemModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderItemModel(
      id: _ps(json['id']),
      productId: _ps(json['product_id']),
      variantId: json['variant_id']?.toString(),
      storeId: _ps(json['store_id']),
      productName: _ps(json['product_name']),
      variantName: json['variant_name'] as String?,
      quantity: _pi(json['quantity']),
      unitPrice: _pd(json['unit_price']),
      totalPrice: _pd(json['total_price']),
    );
  }
}

class SellerOrderModel {
  final String id;
  final String orderId;
  final String sellerId;
  final String storeId;
  final String? storeName;
  final String? storeCountry;
  final String orderStatus;
  final String sellerStatus;
  final String currency;
  final double sellerSubtotal;
  final int itemCount;
  final String customerName;
  final String? customerPhone;
  final Map<String, dynamic>? shippingAddress;
  final String? shippingMethodName;
  final String? shippingCarrier;
  final String? estimatedDeliveryFrom;
  final String? estimatedDeliveryTo;
  final String? sellerNotes;
  final String? cancellationReason;
  final List<SellerOrderItemModel> items;
  final Map<String, dynamic>? shipment;
  final String createdAt;
  final String? updatedAt;

  const SellerOrderModel({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.storeId,
    this.storeName,
    this.storeCountry,
    required this.orderStatus,
    required this.sellerStatus,
    required this.currency,
    required this.sellerSubtotal,
    required this.itemCount,
    required this.customerName,
    this.customerPhone,
    this.shippingAddress,
    this.shippingMethodName,
    this.shippingCarrier,
    this.estimatedDeliveryFrom,
    this.estimatedDeliveryTo,
    this.sellerNotes,
    this.cancellationReason,
    this.items = const [],
    this.shipment,
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return SellerOrderModel(
      id: _ps(json['id']),
      orderId: _ps(json['order_id']),
      sellerId: _ps(json['seller_id']),
      storeId: _ps(json['store_id']),
      storeName: json['store_name'] as String?,
      storeCountry: json['store_country'] as String?,
      orderStatus: _ps(json['order_status']),
      sellerStatus: _ps(json['seller_status']),
      currency: _ps(json['currency']),
      sellerSubtotal: _pd(json['seller_subtotal']),
      itemCount: _pi(json['item_count']),
      customerName: _ps(json['customer_name']),
      customerPhone: json['customer_phone'] as String?,
      shippingAddress: json['shipping_address'] as Map<String, dynamic>?,
      shippingMethodName: json['shipping_method_name'] as String?,
      shippingCarrier: json['shipping_carrier'] as String?,
      estimatedDeliveryFrom: json['estimated_delivery_from'] as String?,
      estimatedDeliveryTo: json['estimated_delivery_to'] as String?,
      sellerNotes: json['seller_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      items: itemsList.map((e) => SellerOrderItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      shipment: json['shipment'] as Map<String, dynamic>?,
      createdAt: _ps(json['created_at']),
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SellerOrderListResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<SellerOrderModel> results;

  const SellerOrderListResponse({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.results = const [],
  });

  factory SellerOrderListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return SellerOrderListResponse(
      total: _pi(json['total']),
      page: _pi(json['page']),
      pageSize: _pi(json['page_size']),
      results: list.map((e) => SellerOrderModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SellerOrderSummaryModel {
  final int totalOrders;
  final int newOrders;
  final int acceptedOrders;
  final int processingOrders;
  final int readyToShipOrders;
  final int shippedOrders;
  final int deliveredOrders;
  final int cancellationRequests;
  final double grossSales;
  final int unitsSold;

  const SellerOrderSummaryModel({
    this.totalOrders = 0,
    this.newOrders = 0,
    this.acceptedOrders = 0,
    this.processingOrders = 0,
    this.readyToShipOrders = 0,
    this.shippedOrders = 0,
    this.deliveredOrders = 0,
    this.cancellationRequests = 0,
    this.grossSales = 0.0,
    this.unitsSold = 0,
  });

  factory SellerOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderSummaryModel(
      totalOrders: _pi(json['total_orders']),
      newOrders: _pi(json['new_orders']),
      acceptedOrders: _pi(json['accepted_orders']),
      processingOrders: _pi(json['processing_orders']),
      readyToShipOrders: _pi(json['ready_to_ship_orders']),
      shippedOrders: _pi(json['shipped_orders']),
      deliveredOrders: _pi(json['delivered_orders']),
      cancellationRequests: _pi(json['cancellation_requests']),
      grossSales: _pd(json['gross_sales']),
      unitsSold: _pi(json['units_sold']),
    );
  }
}

class SellerOrderMessageModel {
  final String id;
  final String sellerOrderId;
  final String? senderUserId;
  final String? senderRoleLabel;
  final String message;
  final bool isInternal;
  final String createdAt;

  const SellerOrderMessageModel({
    required this.id,
    required this.sellerOrderId,
    this.senderUserId,
    this.senderRoleLabel,
    required this.message,
    this.isInternal = false,
    required this.createdAt,
  });

  factory SellerOrderMessageModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderMessageModel(
      id: _ps(json['id']),
      sellerOrderId: _ps(json['seller_order_id']),
      senderUserId: json['sender_user_id']?.toString(),
      senderRoleLabel: json['sender_role_label'] as String?,
      message: _ps(json['message']),
      isInternal: json['is_internal'] as bool? ?? false,
      createdAt: _ps(json['created_at']),
    );
  }
}

// ─── Seller Inventory ───
class SellerInventoryItemModel {
  final String inventoryId;
  final String productId;
  final String productName;
  final String productSku;
  final String? variantId;
  final String? variantName;
  final String? variantSku;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int lowStockThreshold;
  final String? warehouseLocation;
  final String? restockDate;
  final double unitPrice;
  final double inventoryValue;
  final bool isLowStock;
  final bool isOutOfStock;
  final String? updatedAt;

  const SellerInventoryItemModel({
    required this.inventoryId,
    required this.productId,
    required this.productName,
    required this.productSku,
    this.variantId,
    this.variantName,
    this.variantSku,
    required this.quantity,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.lowStockThreshold,
    this.warehouseLocation,
    this.restockDate,
    required this.unitPrice,
    required this.inventoryValue,
    required this.isLowStock,
    required this.isOutOfStock,
    this.updatedAt,
  });

  factory SellerInventoryItemModel.fromJson(Map<String, dynamic> json) {
    return SellerInventoryItemModel(
      inventoryId: _ps(json['inventory_id']),
      productId: _ps(json['product_id']),
      productName: _ps(json['product_name']),
      productSku: _ps(json['product_sku']),
      variantId: json['variant_id']?.toString(),
      variantName: json['variant_name'] as String?,
      variantSku: json['variant_sku'] as String?,
      quantity: _pi(json['quantity']),
      reservedQuantity: _pi(json['reserved_quantity']),
      availableQuantity: _pi(json['available_quantity']),
      lowStockThreshold: _pi(json['low_stock_threshold']),
      warehouseLocation: json['warehouse_location'] as String?,
      restockDate: json['restock_date'] as String?,
      unitPrice: _pd(json['unit_price']),
      inventoryValue: _pd(json['inventory_value']),
      isLowStock: json['is_low_stock'] as bool? ?? false,
      isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SellerInventoryListResponse {
  final int total;
  final int page;
  final int pageSize;
  final List<SellerInventoryItemModel> results;

  const SellerInventoryListResponse({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.results = const [],
  });

  factory SellerInventoryListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return SellerInventoryListResponse(
      total: _pi(json['total']),
      page: _pi(json['page']),
      pageSize: _pi(json['page_size']),
      results: list.map((e) => SellerInventoryItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SellerInventorySummaryModel {
  final int totalProducts;
  final int totalVariants;
  final int totalStockUnits;
  final int reservedUnits;
  final int availableUnits;
  final int lowStockVariants;
  final int outOfStockVariants;
  final double inventoryValue;

  const SellerInventorySummaryModel({
    this.totalProducts = 0,
    this.totalVariants = 0,
    this.totalStockUnits = 0,
    this.reservedUnits = 0,
    this.availableUnits = 0,
    this.lowStockVariants = 0,
    this.outOfStockVariants = 0,
    this.inventoryValue = 0.0,
  });

  factory SellerInventorySummaryModel.fromJson(Map<String, dynamic> json) {
    return SellerInventorySummaryModel(
      totalProducts: _pi(json['total_products']),
      totalVariants: _pi(json['total_variants']),
      totalStockUnits: _pi(json['total_stock_units']),
      reservedUnits: _pi(json['reserved_units']),
      availableUnits: _pi(json['available_units']),
      lowStockVariants: _pi(json['low_stock_variants']),
      outOfStockVariants: _pi(json['out_of_stock_variants']),
      inventoryValue: _pd(json['inventory_value']),
    );
  }
}

class SellerInventoryMovementModel {
  final String id;
  final String inventoryId;
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantName;
  final String movementType;
  final int adjustment;
  final int beforeQuantity;
  final int afterQuantity;
  final String? reference;
  final String? note;
  final String createdAt;

  const SellerInventoryMovementModel({
    required this.id,
    required this.inventoryId,
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.movementType,
    required this.adjustment,
    required this.beforeQuantity,
    required this.afterQuantity,
    this.reference,
    this.note,
    required this.createdAt,
  });

  factory SellerInventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return SellerInventoryMovementModel(
      id: _ps(json['id']),
      inventoryId: _ps(json['inventory_id']),
      productId: _ps(json['product_id']),
      productName: _ps(json['product_name']),
      variantId: json['variant_id']?.toString(),
      variantName: json['variant_name'] as String?,
      movementType: _ps(json['movement_type']),
      adjustment: _pi(json['adjustment']),
      beforeQuantity: _pi(json['before_quantity']),
      afterQuantity: _pi(json['after_quantity']),
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdAt: _ps(json['created_at']),
    );
  }
}

// ─── Wallet ───
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
  final String createdAt;
  final String? updatedAt;

  const SellerWalletModel({
    required this.id,
    required this.sellerId,
    required this.currency,
    required this.pendingBalance,
    required this.availableBalance,
    required this.reservedBalance,
    required this.paidOutBalance,
    required this.refundedBalance,
    required this.debtBalance,
    required this.isFrozen,
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerWalletModel.fromJson(Map<String, dynamic> json) {
    return SellerWalletModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      currency: _ps(json['currency']),
      pendingBalance: _pd(json['pending_balance']),
      availableBalance: _pd(json['available_balance']),
      reservedBalance: _pd(json['reserved_balance']),
      paidOutBalance: _pd(json['paid_out_balance']),
      refundedBalance: _pd(json['refunded_balance']),
      debtBalance: _pd(json['debt_balance']),
      isFrozen: json['is_frozen'] as bool? ?? false,
      createdAt: _ps(json['created_at']),
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class SellerWalletTransactionModel {
  final String id;
  final String transactionType;
  final double amount;
  final String currency;
  final String reference;
  final String? orderId;
  final String? eligibleAt;
  final String? releasedAt;
  final String? description;
  final String createdAt;

  const SellerWalletTransactionModel({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.currency,
    required this.reference,
    this.orderId,
    this.eligibleAt,
    this.releasedAt,
    this.description,
    required this.createdAt,
  });

  factory SellerWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return SellerWalletTransactionModel(
      id: _ps(json['id']),
      transactionType: _ps(json['transaction_type']),
      amount: _pd(json['amount']),
      currency: _ps(json['currency']),
      reference: _ps(json['reference']),
      orderId: json['order_id']?.toString(),
      eligibleAt: json['eligible_at'] as String?,
      releasedAt: json['released_at'] as String?,
      description: json['description'] as String?,
      createdAt: _ps(json['created_at']),
    );
  }
}

class PaginatedWalletTransactions {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<SellerWalletTransactionModel> results;

  const PaginatedWalletTransactions({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.results = const [],
  });

  factory PaginatedWalletTransactions.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return PaginatedWalletTransactions(
      total: _pi(json['total']),
      page: _pi(json['page']),
      pageSize: _pi(json['page_size']),
      totalPages: _pi(json['total_pages']),
      results: list.map((e) => SellerWalletTransactionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SellerPayoutModel {
  final String id;
  final String sellerId;
  final String payoutAccountId;
  final double amount;
  final String currency;
  final String status;
  final String? providerReference;
  final String? sellerNote;
  final String? adminNote;
  final String requestedAt;
  final String? processedAt;
  final String? completedAt;

  const SellerPayoutModel({
    required this.id,
    required this.sellerId,
    required this.payoutAccountId,
    required this.amount,
    required this.currency,
    required this.status,
    this.providerReference,
    this.sellerNote,
    this.adminNote,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory SellerPayoutModel.fromJson(Map<String, dynamic> json) {
    return SellerPayoutModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      payoutAccountId: _ps(json['payout_account_id']),
      amount: _pd(json['amount']),
      currency: _ps(json['currency']),
      status: _ps(json['status']),
      providerReference: json['provider_reference'] as String?,
      sellerNote: json['seller_note'] as String?,
      adminNote: json['admin_note'] as String?,
      requestedAt: _ps(json['requested_at']),
      processedAt: json['processed_at'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class PaginatedSellerPayouts {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<SellerPayoutModel> results;

  const PaginatedSellerPayouts({
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.results = const [],
  });

  factory PaginatedSellerPayouts.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List? ?? [];
    return PaginatedSellerPayouts(
      total: _pi(json['total']),
      page: _pi(json['page']),
      pageSize: _pi(json['page_size']),
      totalPages: _pi(json['total_pages']),
      results: list.map((e) => SellerPayoutModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SellerEarningsSummaryModel {
  final String currency;
  final double grossSales;
  final double commissionDeducted;
  final double netEarnings;
  final int transactionCount;

  const SellerEarningsSummaryModel({
    this.currency = 'TZS',
    this.grossSales = 0.0,
    this.commissionDeducted = 0.0,
    this.netEarnings = 0.0,
    this.transactionCount = 0,
  });

  factory SellerEarningsSummaryModel.fromJson(Map<String, dynamic> json) {
    return SellerEarningsSummaryModel(
      currency: _ps(json['currency']),
      grossSales: _pd(json['gross_sales']),
      commissionDeducted: _pd(json['commission_deducted']),
      netEarnings: _pd(json['net_earnings']),
      transactionCount: _pi(json['transaction_count']),
    );
  }
}

// ─── Analytics ───
class SellerAnalyticsOverviewModel {
  final String? startAt;
  final String? endAt;
  final String currency;
  final double grossSales;
  final double commissionRevenue;
  final double sellerNetEarnings;
  final double refundsCompleted;
  final double payoutsCompleted;
  final int orders;
  final int products;
  final int unitsSold;
  final double averageOrderValue;
  final double refundRatePercent;
  final double pendingWalletBalance;
  final double availableWalletBalance;
  final double pendingPayoutAmount;

  const SellerAnalyticsOverviewModel({
    this.startAt,
    this.endAt,
    this.currency = 'TZS',
    this.grossSales = 0.0,
    this.commissionRevenue = 0.0,
    this.sellerNetEarnings = 0.0,
    this.refundsCompleted = 0.0,
    this.payoutsCompleted = 0.0,
    this.orders = 0,
    this.products = 0,
    this.unitsSold = 0,
    this.averageOrderValue = 0.0,
    this.refundRatePercent = 0.0,
    this.pendingWalletBalance = 0.0,
    this.availableWalletBalance = 0.0,
    this.pendingPayoutAmount = 0.0,
  });

  factory SellerAnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    final money = json['money'] as Map<String, dynamic>? ?? {};
    final counts = json['counts'] as Map<String, dynamic>? ?? {};
    return SellerAnalyticsOverviewModel(
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      currency: _ps(money['currency']),
      grossSales: _pd(money['gross_sales']),
      commissionRevenue: _pd(money['commission_revenue']),
      sellerNetEarnings: _pd(money['seller_net_earnings']),
      refundsCompleted: _pd(money['refunds_completed']),
      payoutsCompleted: _pd(money['payouts_completed']),
      orders: _pi(counts['orders']),
      products: _pi(counts['products']),
      unitsSold: _pi(counts['units_sold']),
      averageOrderValue: _pd(json['average_order_value']),
      refundRatePercent: _pd(json['refund_rate_percent']),
      pendingWalletBalance: _pd(json['pending_wallet_balance']),
      availableWalletBalance: _pd(json['available_wallet_balance']),
      pendingPayoutAmount: _pd(json['pending_payout_amount']),
    );
  }
}

class AnalyticsSeriesPointModel {
  final String date;
  final double value;

  const AnalyticsSeriesPointModel({
    required this.date,
    required this.value,
  });

  factory AnalyticsSeriesPointModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSeriesPointModel(
      date: _ps(json['date']),
      value: _pd(json['value']),
    );
  }
}

class AnalyticsRankingRowModel {
  final String id;
  final String name;
  final double grossSales;
  final double netEarnings;
  final double commission;
  final int orderCount;
  final int units;

  const AnalyticsRankingRowModel({
    required this.id,
    required this.name,
    this.grossSales = 0.0,
    this.netEarnings = 0.0,
    this.commission = 0.0,
    this.orderCount = 0,
    this.units = 0,
  });

  factory AnalyticsRankingRowModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsRankingRowModel(
      id: _ps(json['id']),
      name: _ps(json['name']),
      grossSales: _pd(json['gross_sales']),
      netEarnings: _pd(json['net_earnings']),
      commission: _pd(json['commission']),
      orderCount: _pi(json['order_count']),
      units: _pi(json['units']),
    );
  }
}

// ─── Pricing Preview ───
class SellerPricingPreviewModel {
  final double sellerBasePrice;
  final double? sellerSalePrice;
  final double commissionRate;
  final double commissionAmount;
  final double customerPrice;
  final double? customerSalePrice;
  final String? commissionScope;
  final String currency;

  const SellerPricingPreviewModel({
    required this.sellerBasePrice,
    this.sellerSalePrice,
    required this.commissionRate,
    required this.commissionAmount,
    required this.customerPrice,
    this.customerSalePrice,
    this.commissionScope,
    this.currency = 'TZS',
  });

  factory SellerPricingPreviewModel.fromJson(Map<String, dynamic> json) {
    return SellerPricingPreviewModel(
      sellerBasePrice: _pd(json['seller_base_price']),
      sellerSalePrice: json['seller_sale_price'] != null ? _pd(json['seller_sale_price']) : null,
      commissionRate: _pd(json['commission_rate']),
      commissionAmount: _pd(json['commission_amount']),
      customerPrice: _pd(json['customer_price']),
      customerSalePrice: json['customer_sale_price'] != null ? _pd(json['customer_sale_price']) : null,
      commissionScope: json['commission_scope'] as String?,
      currency: _ps(json['currency']),
    );
  }
}

// ─── Refunds / Returns ───
class RefundItemModel {
  final String id;
  final String orderItemId;
  final String sellerId;
  final int quantity;
  final double unitAmount;
  final double refundAmount;
  final double commissionReversal;
  final double sellerReversal;
  final double sellerDebtAmount;
  final bool restock;
  final String? processedAt;

  const RefundItemModel({
    required this.id,
    required this.orderItemId,
    required this.sellerId,
    required this.quantity,
    required this.unitAmount,
    required this.refundAmount,
    required this.commissionReversal,
    required this.sellerReversal,
    required this.sellerDebtAmount,
    required this.restock,
    this.processedAt,
  });

  factory RefundItemModel.fromJson(Map<String, dynamic> json) {
    return RefundItemModel(
      id: _ps(json['id']),
      orderItemId: _ps(json['order_item_id']),
      sellerId: _ps(json['seller_id']),
      quantity: _pi(json['quantity']),
      unitAmount: _pd(json['unit_amount']),
      refundAmount: _pd(json['refund_amount']),
      commissionReversal: _pd(json['commission_reversal']),
      sellerReversal: _pd(json['seller_reversal']),
      sellerDebtAmount: _pd(json['seller_debt_amount']),
      restock: json['restock'] as bool? ?? true,
      processedAt: json['processed_at'] as String?,
    );
  }
}

class RefundEventModel {
  final String id;
  final String status;
  final String? note;
  final String? createdById;
  final String createdAt;

  const RefundEventModel({
    required this.id,
    required this.status,
    this.note,
    this.createdById,
    required this.createdAt,
  });

  factory RefundEventModel.fromJson(Map<String, dynamic> json) {
    return RefundEventModel(
      id: _ps(json['id']),
      status: _ps(json['status']),
      note: json['note'] as String?,
      createdById: json['created_by_id'] as String?,
      createdAt: _ps(json['created_at']),
    );
  }
}

class RefundModel {
  final String id;
  final String orderId;
  final String requestedById;
  final String status;
  final String reason;
  final String? reasonDetails;
  final String currency;
  final double itemsAmount;
  final double shippingAmount;
  final double taxAmount;
  final double totalAmount;
  final String? providerReference;
  final String idempotencyKey;
  final String? adminNote;
  final String requestedAt;
  final String? reviewedAt;
  final String? processedAt;
  final String? completedAt;
  final List<RefundItemModel> items;
  final List<RefundEventModel> events;

  const RefundModel({
    required this.id,
    required this.orderId,
    required this.requestedById,
    required this.status,
    required this.reason,
    this.reasonDetails,
    required this.currency,
    required this.itemsAmount,
    required this.shippingAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.providerReference,
    required this.idempotencyKey,
    this.adminNote,
    required this.requestedAt,
    this.reviewedAt,
    this.processedAt,
    this.completedAt,
    this.items = const [],
    this.events = const [],
  });

  factory RefundModel.fromJson(Map<String, dynamic> json) {
    return RefundModel(
      id: _ps(json['id']),
      orderId: _ps(json['order_id']),
      requestedById: _ps(json['requested_by_id']),
      status: _ps(json['status']),
      reason: _ps(json['reason']),
      reasonDetails: json['reason_details'] as String?,
      currency: _ps(json['currency']),
      itemsAmount: _pd(json['items_amount']),
      shippingAmount: _pd(json['shipping_amount']),
      taxAmount: _pd(json['tax_amount']),
      totalAmount: _pd(json['total_amount']),
      providerReference: json['provider_reference'] as String?,
      idempotencyKey: _ps(json['idempotency_key']),
      adminNote: json['admin_note'] as String?,
      requestedAt: _ps(json['requested_at']),
      reviewedAt: json['reviewed_at'] as String?,
      processedAt: json['processed_at'] as String?,
      completedAt: json['completed_at'] as String?,
      items: (json['items'] as List?)?.map((e) => RefundItemModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      events: (json['events'] as List?)?.map((e) => RefundEventModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}

// ─── Seller Order Package ───
class SellerOrderPackageAttachment {
  final String id;
  final String fileUrl;
  final String? fileName;
  final String? mimeType;
  final String createdAt;

  const SellerOrderPackageAttachment({
    required this.id,
    required this.fileUrl,
    this.fileName,
    this.mimeType,
    required this.createdAt,
  });

  factory SellerOrderPackageAttachment.fromJson(Map<String, dynamic> json) {
    return SellerOrderPackageAttachment(
      id: _ps(json['id']),
      fileUrl: _ps(json['file_url']),
      fileName: json['file_name'] as String?,
      mimeType: json['mime_type'] as String?,
      createdAt: _ps(json['created_at']),
    );
  }
}

class SellerOrderPackageModel {
  final String id;
  final String sellerOrderId;
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final int packageCount;
  final String? notes;
  final bool isReady;
  final String? preparedAt;
  final List<SellerOrderPackageAttachment> attachments;
  final String createdAt;
  final String? updatedAt;

  const SellerOrderPackageModel({
    required this.id,
    required this.sellerOrderId,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    required this.packageCount,
    this.notes,
    required this.isReady,
    this.preparedAt,
    this.attachments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory SellerOrderPackageModel.fromJson(Map<String, dynamic> json) {
    return SellerOrderPackageModel(
      id: _ps(json['id']),
      sellerOrderId: _ps(json['seller_order_id']),
      weightKg: json['weight_kg'] != null ? _pd(json['weight_kg']) : null,
      lengthCm: json['length_cm'] != null ? _pd(json['length_cm']) : null,
      widthCm: json['width_cm'] != null ? _pd(json['width_cm']) : null,
      heightCm: json['height_cm'] != null ? _pd(json['height_cm']) : null,
      packageCount: _pi(json['package_count']),
      notes: json['notes'] as String?,
      isReady: json['is_ready'] as bool? ?? false,
      preparedAt: json['prepared_at'] as String?,
      attachments: (json['attachments'] as List?)
              ?.map((e) =>
                  SellerOrderPackageAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: _ps(json['created_at']),
      updatedAt: json['updated_at'] as String?,
    );
  }
}

// ─── Shipment Handover ───
class ShipmentHandoverModel {
  final String id;
  final String shipmentId;
  final String sellerOrderId;
  final String sellerId;
  final String? logisticsCompanyId;
  final String status;
  final String? courierArrivedAt;
  final String? courierArrivedById;
  final double? courierArrivalLatitude;
  final double? courierArrivalLongitude;
  final String? courierArrivalNotes;
  final String? sellerConfirmedAt;
  final String? sellerConfirmedById;
  final String? sellerConfirmationNotes;
  final String createdAt;
  final String? updatedAt;

  const ShipmentHandoverModel({
    required this.id,
    required this.shipmentId,
    required this.sellerOrderId,
    required this.sellerId,
    this.logisticsCompanyId,
    required this.status,
    this.courierArrivedAt,
    this.courierArrivedById,
    this.courierArrivalLatitude,
    this.courierArrivalLongitude,
    this.courierArrivalNotes,
    this.sellerConfirmedAt,
    this.sellerConfirmedById,
    this.sellerConfirmationNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShipmentHandoverModel.fromJson(Map<String, dynamic> json) {
    return ShipmentHandoverModel(
      id: _ps(json['id']),
      shipmentId: _ps(json['shipment_id']),
      sellerOrderId: _ps(json['seller_order_id']),
      sellerId: _ps(json['seller_id']),
      logisticsCompanyId: json['logistics_company_id']?.toString(),
      status: _ps(json['status']),
      courierArrivedAt: json['courier_arrived_at'] as String?,
      courierArrivedById: json['courier_arrived_by_id']?.toString(),
      courierArrivalLatitude:
          json['courier_arrival_latitude'] != null ? _pd(json['courier_arrival_latitude']) : null,
      courierArrivalLongitude:
          json['courier_arrival_longitude'] != null ? _pd(json['courier_arrival_longitude']) : null,
      courierArrivalNotes: json['courier_arrival_notes'] as String?,
      sellerConfirmedAt: json['seller_confirmed_at'] as String?,
      sellerConfirmedById: json['seller_confirmed_by_id']?.toString(),
      sellerConfirmationNotes: json['seller_confirmation_notes'] as String?,
      createdAt: _ps(json['created_at']),
      updatedAt: json['updated_at'] as String?,
    );
  }
}

// ─── Fulfillment Readiness ───
class FulfillmentReadinessCheck {
  final String code;
  final String label;
  final bool ready;
  final bool blocking;
  final String? detail;

  const FulfillmentReadinessCheck({
    required this.code,
    required this.label,
    required this.ready,
    required this.blocking,
    this.detail,
  });

  factory FulfillmentReadinessCheck.fromJson(Map<String, dynamic> json) {
    return FulfillmentReadinessCheck(
      code: _ps(json['code']),
      label: _ps(json['label']),
      ready: json['ready'] as bool? ?? false,
      blocking: json['blocking'] as bool? ?? false,
      detail: json['detail'] as String?,
    );
  }
}

class SellerFulfillmentReadinessModel {
  final String sellerOrderId;
  final bool readyToShip;
  final String? pickupLocationId;
  final String? packageId;
  final List<String> packageIds;
  final int packageGroups;
  final int physicalPackageCount;
  final double totalWeightKg;
  final String? shipmentId;
  final List<String> blockers;
  final List<String> warnings;
  final List<FulfillmentReadinessCheck> checks;

  const SellerFulfillmentReadinessModel({
    required this.sellerOrderId,
    required this.readyToShip,
    this.pickupLocationId,
    this.packageId,
    this.packageIds = const [],
    this.packageGroups = 0,
    this.physicalPackageCount = 0,
    this.totalWeightKg = 0.0,
    this.shipmentId,
    this.blockers = const [],
    this.warnings = const [],
    this.checks = const [],
  });

  factory SellerFulfillmentReadinessModel.fromJson(Map<String, dynamic> json) {
    return SellerFulfillmentReadinessModel(
      sellerOrderId: _ps(json['seller_order_id']),
      readyToShip: json['ready_to_ship'] as bool? ?? false,
      pickupLocationId: json['pickup_location_id']?.toString(),
      packageId: json['package_id']?.toString(),
      packageIds: (json['package_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      packageGroups: _pi(json['package_groups']),
      physicalPackageCount: _pi(json['physical_package_count']),
      totalWeightKg: _pd(json['total_weight_kg']),
      shipmentId: json['shipment_id']?.toString(),
      blockers: (json['blockers'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      checks: (json['checks'] as List?)
              ?.map((e) =>
                  FulfillmentReadinessCheck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
