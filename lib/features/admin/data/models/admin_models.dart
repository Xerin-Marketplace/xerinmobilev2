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

// ─── Dashboard Summary ───
class AdminDashboardSummaryModel {
  final int totalOrders;
  final int totalUsers;
  final int totalSellers;
  final int totalProducts;
  final double gmv;
  final double totalDiscounts;
  final double totalShipping;
  final String currency;
  final String? periodStart;
  final String? periodEnd;

  const AdminDashboardSummaryModel({
    this.totalOrders = 0,
    this.totalUsers = 0,
    this.totalSellers = 0,
    this.totalProducts = 0,
    this.gmv = 0.0,
    this.totalDiscounts = 0.0,
    this.totalShipping = 0.0,
    this.currency = 'TZS',
    this.periodStart,
    this.periodEnd,
  });

  factory AdminDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummaryModel(
      totalOrders: _pi(json['total_orders'] ?? json['orders']),
      totalUsers: _pi(json['total_users'] ?? json['users']),
      totalSellers: _pi(json['total_sellers'] ?? json['sellers']),
      totalProducts: _pi(json['total_products'] ?? json['products']),
      gmv: _pd(json['gmv'] ?? json['total_revenue']),
      totalDiscounts: _pd(json['discounts']),
      totalShipping: _pd(json['shipping']),
      currency: _ps(json['currency'] ?? 'TZS'),
      periodStart: json['period']?['start']?.toString(),
      periodEnd: json['period']?['end']?.toString(),
    );
  }
}

// ─── Dashboard Orders ───
class AdminDashboardOrdersModel {
  final Map<String, int> byStatus;

  const AdminDashboardOrdersModel({this.byStatus = const {}});

  factory AdminDashboardOrdersModel.fromJson(Map<String, dynamic> json) {
    final raw = json['by_status'] as Map<String, dynamic>? ?? {};
    return AdminDashboardOrdersModel(
      byStatus: raw.map((k, v) => MapEntry(k, _pi(v))),
    );
  }
}

// ─── Dashboard Sellers ───
class AdminDashboardSellersModel {
  final int total;
  final int approved;
  final int pending;

  const AdminDashboardSellersModel({
    this.total = 0,
    this.approved = 0,
    this.pending = 0,
  });

  factory AdminDashboardSellersModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSellersModel(
      total: _pi(json['total']),
      approved: _pi(json['approved']),
      pending: _pi(json['pending']),
    );
  }
}

// ─── Dashboard Products ───
class AdminDashboardProductsModel {
  final int total;
  final int approved;
  final int pendingReview;

  const AdminDashboardProductsModel({
    this.total = 0,
    this.approved = 0,
    this.pendingReview = 0,
  });

  factory AdminDashboardProductsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardProductsModel(
      total: _pi(json['total']),
      approved: _pi(json['approved']),
      pendingReview: _pi(json['pending_review']),
    );
  }
}

// ─── Dashboard Customers ───
class AdminDashboardCustomersModel {
  final int total;
  final int verified;

  const AdminDashboardCustomersModel({this.total = 0, this.verified = 0});

  factory AdminDashboardCustomersModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardCustomersModel(
      total: _pi(json['total']),
      verified: _pi(json['verified']),
    );
  }
}

// ─── Dashboard Payments ───
class AdminDashboardPaymentsModel {
  final int total;
  final int failed;
  final int successful;

  const AdminDashboardPaymentsModel({
    this.total = 0,
    this.failed = 0,
    this.successful = 0,
  });

  factory AdminDashboardPaymentsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardPaymentsModel(
      total: _pi(json['total']),
      failed: _pi(json['failed']),
      successful: _pi(json['successful']),
    );
  }
}

// ─── Dashboard Refunds ───
class AdminDashboardRefundsModel {
  final int total;
  final int pending;

  const AdminDashboardRefundsModel({this.total = 0, this.pending = 0});

  factory AdminDashboardRefundsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardRefundsModel(
      total: _pi(json['total']),
      pending: _pi(json['pending']),
    );
  }
}

// ─── System Alert ───
class AdminSystemAlertModel {
  final String id;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final bool isResolved;
  final String? createdAt;

  const AdminSystemAlertModel({
    required this.id,
    this.alertType = '',
    this.severity = '',
    this.title = '',
    this.message = '',
    this.isResolved = false,
    this.createdAt,
  });

  factory AdminSystemAlertModel.fromJson(Map<String, dynamic> json) {
    return AdminSystemAlertModel(
      id: _ps(json['id']),
      alertType: _ps(json['type'] ?? json['alert_type']),
      severity: _ps(json['severity']),
      title: _ps(json['title']),
      message: _ps(json['message']),
      isResolved: json['resolved'] as bool? ?? false,
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Activity Log ───
class AdminActivityLogModel {
  final String id;
  final String? adminUserId;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? details;
  final String? createdAt;

  const AdminActivityLogModel({
    required this.id,
    this.adminUserId,
    this.action = '',
    this.resourceType,
    this.resourceId,
    this.details,
    this.createdAt,
  });

  factory AdminActivityLogModel.fromJson(Map<String, dynamic> json) {
    return AdminActivityLogModel(
      id: _ps(json['id']),
      adminUserId: json['admin_user_id']?.toString(),
      action: _ps(json['action']),
      resourceType: json['resource_type']?.toString(),
      resourceId: json['resource_id']?.toString(),
      details: json['details']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Admin Seller ───
class AdminSellerModel {
  final String id;
  final String? userId;
  final String businessName;
  final String? businessCategory;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String status;
  final bool isVerified;
  final String? rejectionReason;
  final String? createdAt;

  const AdminSellerModel({
    required this.id,
    this.userId,
    required this.businessName,
    this.businessCategory,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.status = 'pending',
    this.isVerified = false,
    this.rejectionReason,
    this.createdAt,
  });

  factory AdminSellerModel.fromJson(Map<String, dynamic> json) {
    return AdminSellerModel(
      id: _ps(json['id']),
      userId: json['user_id']?.toString(),
      businessName: _ps(json['business_name']),
      businessCategory: json['business_category']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      address: json['address']?.toString(),
      status: _ps(json['status']),
      isVerified: json['is_verified'] as bool? ?? false,
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Admin Seller KYC Document ───
class AdminSellerDocumentModel {
  final String id;
  final String sellerId;
  final String documentType;
  final String? fileUrl;
  final String status;
  final String? rejectionReason;
  final String? createdAt;

  const AdminSellerDocumentModel({
    required this.id,
    this.sellerId = '',
    this.documentType = '',
    this.fileUrl,
    this.status = 'pending',
    this.rejectionReason,
    this.createdAt,
  });

  factory AdminSellerDocumentModel.fromJson(Map<String, dynamic> json) {
    return AdminSellerDocumentModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      documentType: _ps(json['document_type']),
      fileUrl: json['file_url']?.toString(),
      status: _ps(json['status']),
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Admin User ───
class AdminUserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String status;
  final bool isVerified;
  final String? createdAt;
  final List<String> roles;

  const AdminUserModel({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone,
    this.status = 'active',
    this.isVerified = false,
    this.createdAt,
    this.roles = const [],
  });

  String get fullName => '$firstName $lastName'.trim();

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final rolesList = json['roles'] as List<dynamic>? ?? [];
    return AdminUserModel(
      id: _ps(json['id']),
      firstName: _ps(json['first_name']),
      lastName: _ps(json['last_name']),
      email: _ps(json['email']),
      phone: json['phone']?.toString(),
      status: _ps(json['status']),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at']?.toString(),
      roles: rolesList.map((r) {
        if (r is String) return r;
        if (r is Map) return _ps(r['name']);
        return r.toString();
      }).toList(),
    );
  }
}

// ─── Admin Wallet ───
class AdminWalletModel {
  final String id;
  final String sellerId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarnings;
  final String currency;
  final String? createdAt;

  const AdminWalletModel({
    required this.id,
    this.sellerId = '',
    this.availableBalance = 0.0,
    this.pendingBalance = 0.0,
    this.totalEarnings = 0.0,
    this.currency = 'TZS',
    this.createdAt,
  });

  factory AdminWalletModel.fromJson(Map<String, dynamic> json) {
    return AdminWalletModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      availableBalance: _pd(json['available_balance']),
      pendingBalance: _pd(json['pending_balance']),
      totalEarnings: _pd(json['total_earnings']),
      currency: _ps(json['currency'] ?? 'TZS'),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Admin Payout ───
class AdminPayoutModel {
  final String id;
  final String sellerId;
  final double amount;
  final String currency;
  final String status;
  final String? provider;
  final String? providerReference;
  final String? note;
  final String? requestedAt;

  const AdminPayoutModel({
    required this.id,
    this.sellerId = '',
    this.amount = 0.0,
    this.currency = 'TZS',
    this.status = 'pending',
    this.provider,
    this.providerReference,
    this.note,
    this.requestedAt,
  });

  factory AdminPayoutModel.fromJson(Map<String, dynamic> json) {
    return AdminPayoutModel(
      id: _ps(json['id']),
      sellerId: _ps(json['seller_id']),
      amount: _pd(json['amount']),
      currency: _ps(json['currency'] ?? 'TZS'),
      status: _ps(json['status']),
      provider: json['provider']?.toString(),
      providerReference: json['provider_reference']?.toString(),
      note: json['note']?.toString(),
      requestedAt: json['requested_at']?.toString(),
    );
  }
}

// ─── Admin Refund ───
class AdminRefundModel {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final String? reason;
  final String? note;
  final String? providerReference;
  final String? requestedAt;

  const AdminRefundModel({
    required this.id,
    this.orderId = '',
    this.amount = 0.0,
    this.currency = 'TZS',
    this.status = 'requested',
    this.reason,
    this.note,
    this.providerReference,
    this.requestedAt,
  });

  factory AdminRefundModel.fromJson(Map<String, dynamic> json) {
    return AdminRefundModel(
      id: _ps(json['id']),
      orderId: _ps(json['order_id']),
      amount: _pd(json['amount']),
      currency: _ps(json['currency'] ?? 'TZS'),
      status: _ps(json['status']),
      reason: json['reason']?.toString(),
      note: json['note']?.toString(),
      providerReference: json['provider_reference']?.toString(),
      requestedAt: json['requested_at']?.toString(),
    );
  }
}

// ─── Admin Review ───
class AdminReviewModel {
  final String id;
  final String productId;
  final String? productName;
  final String? customerName;
  final int rating;
  final String? comment;
  final String status;
  final String? createdAt;

  const AdminReviewModel({
    required this.id,
    this.productId = '',
    this.productName,
    this.customerName,
    this.rating = 0,
    this.comment,
    this.status = 'pending',
    this.createdAt,
  });

  factory AdminReviewModel.fromJson(Map<String, dynamic> json) {
    return AdminReviewModel(
      id: _ps(json['id']),
      productId: _ps(json['product_id']),
      productName: json['product_name']?.toString(),
      customerName: json['customer_name']?.toString(),
      rating: _pi(json['rating']),
      comment: json['comment']?.toString(),
      status: _ps(json['status']),
      createdAt: json['created_at']?.toString(),
    );
  }
}

// ─── Analytics Overview ───
class AdminAnalyticsOverviewModel {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final int totalCustomers;
  final int totalSellers;
  final int totalProducts;
  final String currency;

  const AdminAnalyticsOverviewModel({
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    this.avgOrderValue = 0.0,
    this.totalCustomers = 0,
    this.totalSellers = 0,
    this.totalProducts = 0,
    this.currency = 'TZS',
  });

  factory AdminAnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsOverviewModel(
      totalRevenue: _pd(json['total_revenue'] ?? json['revenue']),
      totalOrders: _pi(json['total_orders'] ?? json['orders']),
      avgOrderValue: _pd(json['avg_order_value'] ?? json['aov']),
      totalCustomers: _pi(json['total_customers'] ?? json['customers']),
      totalSellers: _pi(json['total_sellers'] ?? json['sellers']),
      totalProducts: _pi(json['total_products'] ?? json['products']),
      currency: _ps(json['currency'] ?? 'TZS'),
    );
  }
}

// ─── Analytics Sales Point ───
class AdminAnalyticsSalesPointModel {
  final String date;
  final double revenue;
  final int orders;

  const AdminAnalyticsSalesPointModel({
    this.date = '',
    this.revenue = 0.0,
    this.orders = 0,
  });

  factory AdminAnalyticsSalesPointModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsSalesPointModel(
      date: _ps(json['date'] ?? json['period']),
      revenue: _pd(json['revenue'] ?? json['gmv']),
      orders: _pi(json['orders']),
    );
  }
}

// ─── Analytics Seller Ranking ───
class AdminAnalyticsSellerRankingModel {
  final String sellerId;
  final String sellerName;
  final double revenue;
  final int orders;
  final int products;

  const AdminAnalyticsSellerRankingModel({
    this.sellerId = '',
    this.sellerName = '',
    this.revenue = 0.0,
    this.orders = 0,
    this.products = 0,
  });

  factory AdminAnalyticsSellerRankingModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsSellerRankingModel(
      sellerId: _ps(json['seller_id'] ?? json['id']),
      sellerName: _ps(json['seller_name'] ?? json['business_name']),
      revenue: _pd(json['revenue']),
      orders: _pi(json['orders']),
      products: _pi(json['products']),
    );
  }
}

// ─── Analytics Product Ranking ───
class AdminAnalyticsProductRankingModel {
  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;

  const AdminAnalyticsProductRankingModel({
    this.productId = '',
    this.productName = '',
    this.unitsSold = 0,
    this.revenue = 0.0,
  });

  factory AdminAnalyticsProductRankingModel.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsProductRankingModel(
      productId: _ps(json['product_id'] ?? json['id']),
      productName: _ps(json['product_name'] ?? json['name']),
      unitsSold: _pi(json['units_sold'] ?? json['sold']),
      revenue: _pd(json['revenue']),
    );
  }
}

// ─── Paginated Admin Users ───
class PaginatedAdminUsers {
  final int total;
  final int page;
  final int pageSize;
  final List<AdminUserModel> results;

  const PaginatedAdminUsers({
    this.total = 0,
    this.page = 1,
    this.pageSize = 10,
    this.results = const [],
  });

  factory PaginatedAdminUsers.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return PaginatedAdminUsers(
      total: _pi(json['total']),
      page: _pi(json['page']),
      pageSize: _pi(json['page_size']),
      results: list
          .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Roles & Permissions ─────────────────────────────────────

class AdminRoleModel {
  final String id;
  final String name;
  final String? description;

  const AdminRoleModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory AdminRoleModel.fromJson(Map<String, dynamic> json) => AdminRoleModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
      );
}

class AdminPermissionModel {
  final String id;
  final String code;
  final String name;
  final String? description;

  const AdminPermissionModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory AdminPermissionModel.fromJson(Map<String, dynamic> json) =>
      AdminPermissionModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
      );
}

class AdminRolePermissionsModel {
  final String roleId;
  final String roleName;
  final List<String> permissions;

  const AdminRolePermissionsModel({
    required this.roleId,
    required this.roleName,
    required this.permissions,
  });

  factory AdminRolePermissionsModel.fromJson(Map<String, dynamic> json) =>
      AdminRolePermissionsModel(
        roleId: json['role_id']?.toString() ?? '',
        roleName: json['role_name']?.toString() ?? '',
        permissions: (json['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class AdminUserPermissionsModel {
  final String userId;
  final List<String> permissions;

  const AdminUserPermissionsModel({
    required this.userId,
    required this.permissions,
  });

  factory AdminUserPermissionsModel.fromJson(Map<String, dynamic> json) =>
      AdminUserPermissionsModel(
        userId: json['user_id']?.toString() ?? '',
        permissions: (json['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
