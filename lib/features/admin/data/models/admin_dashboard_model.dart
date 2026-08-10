class AdminDashboardSummary {
  final double totalSales;
  final int totalOrders;
  final int totalUsers;
  final int totalSellers;
  final int totalProducts;
  final int pendingApprovals;

  const AdminDashboardSummary({
    this.totalSales = 0.0,
    this.totalOrders = 0,
    this.totalUsers = 0,
    this.totalSellers = 0,
    this.totalProducts = 0,
    this.pendingApprovals = 0,
  });

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSummary(
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      totalSellers: (json['total_sellers'] as num?)?.toInt() ?? 0,
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      pendingApprovals: (json['pending_approvals'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardSales {
  final String? periodStart;
  final String? periodEnd;
  final double gmv;
  final double discounts;
  final double shipping;

  const AdminDashboardSales({
    this.periodStart,
    this.periodEnd,
    this.gmv = 0.0,
    this.discounts = 0.0,
    this.shipping = 0.0,
  });

  factory AdminDashboardSales.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>?;
    return AdminDashboardSales(
      periodStart: period?['start'] as String?,
      periodEnd: period?['end'] as String?,
      gmv: double.tryParse(json['gmv']?.toString() ?? '0') ?? 0.0,
      discounts: double.tryParse(json['discounts']?.toString() ?? '0') ?? 0.0,
      shipping: double.tryParse(json['shipping']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class AdminDashboardSellers {
  final int total;
  final int approved;
  final int pending;

  const AdminDashboardSellers({
    this.total = 0,
    this.approved = 0,
    this.pending = 0,
  });

  factory AdminDashboardSellers.fromJson(Map<String, dynamic> json) {
    return AdminDashboardSellers(
      total: (json['total'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardProducts {
  final int total;
  final int approved;
  final int pendingReview;

  const AdminDashboardProducts({
    this.total = 0,
    this.approved = 0,
    this.pendingReview = 0,
  });

  factory AdminDashboardProducts.fromJson(Map<String, dynamic> json) {
    return AdminDashboardProducts(
      total: (json['total'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      pendingReview: (json['pending_review'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardCustomers {
  final int total;
  final int verified;

  const AdminDashboardCustomers({this.total = 0, this.verified = 0});

  factory AdminDashboardCustomers.fromJson(Map<String, dynamic> json) {
    return AdminDashboardCustomers(
      total: (json['total'] as num?)?.toInt() ?? 0,
      verified: (json['verified'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardPayments {
  final int total;
  final int failed;
  final int successful;

  const AdminDashboardPayments({this.total = 0, this.failed = 0, this.successful = 0});

  factory AdminDashboardPayments.fromJson(Map<String, dynamic> json) {
    return AdminDashboardPayments(
      total: (json['total'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
      successful: (json['successful'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardRefunds {
  final int total;
  final int pending;

  const AdminDashboardRefunds({this.total = 0, this.pending = 0});

  factory AdminDashboardRefunds.fromJson(Map<String, dynamic> json) {
    return AdminDashboardRefunds(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardDelivery {
  final int total;
  final int failed;

  const AdminDashboardDelivery({this.total = 0, this.failed = 0});

  factory AdminDashboardDelivery.fromJson(Map<String, dynamic> json) {
    return AdminDashboardDelivery(
      total: (json['total'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardNotifications {
  final int total;
  final int failed;

  const AdminDashboardNotifications({this.total = 0, this.failed = 0});

  factory AdminDashboardNotifications.fromJson(Map<String, dynamic> json) {
    return AdminDashboardNotifications(
      total: (json['total'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminSystemAlert {
  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final bool resolved;
  final String? createdAt;

  const AdminSystemAlert({
    required this.id,
    this.type = '',
    this.severity = '',
    this.title = '',
    this.message = '',
    this.resolved = false,
    this.createdAt,
  });

  factory AdminSystemAlert.fromJson(Map<String, dynamic> json) {
    return AdminSystemAlert(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      resolved: json['resolved'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
    );
  }
}

class AdminActivityLog {
  final String id;
  final String? adminUserId;
  final String action;
  final String? resourceType;
  final String? resourceId;
  final String? details;
  final String? createdAt;

  const AdminActivityLog({
    required this.id,
    this.adminUserId,
    this.action = '',
    this.resourceType,
    this.resourceId,
    this.details,
    this.createdAt,
  });

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id']?.toString() ?? '',
      adminUserId: json['admin_user_id']?.toString(),
      action: json['action'] as String? ?? '',
      resourceType: json['resource_type'] as String?,
      resourceId: json['resource_id']?.toString(),
      details: json['details'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class NotificationPreferenceModel {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderUpdates;
  final bool promotionAlerts;
  final bool securityAlerts;

  const NotificationPreferenceModel({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.orderUpdates = true,
    this.promotionAlerts = true,
    this.securityAlerts = true,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
      orderUpdates: json['order_updates'] as bool? ?? true,
      promotionAlerts: json['promotion_alerts'] as bool? ?? true,
      securityAlerts: json['security_alerts'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'push_enabled': pushEnabled,
        'email_enabled': emailEnabled,
        'sms_enabled': smsEnabled,
        'order_updates': orderUpdates,
        'promotion_alerts': promotionAlerts,
        'security_alerts': securityAlerts,
      };

  NotificationPreferenceModel copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderUpdates,
    bool? promotionAlerts,
    bool? securityAlerts,
  }) {
    return NotificationPreferenceModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionAlerts: promotionAlerts ?? this.promotionAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
    );
  }
}

class NotificationSummary {
  final int total;
  final int unread;
  final int read;

  const NotificationSummary({this.total = 0, this.unread = 0, this.read = 0});

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      read: (json['read'] as num?)?.toInt() ?? 0,
    );
  }
}
