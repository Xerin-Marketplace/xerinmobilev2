class LogisticsDashboardModel {
  final int shipmentsTotal;
  final int pickupJobsTotal;
  final int activeZones;
  final int members;
  final int activeServices;
  final int webhookEvents24h;
  final int webhookFailures24h;
  final Map<String, int> shipmentsByStatus;
  final Map<String, int> pickupJobsByStatus;

  const LogisticsDashboardModel({
    required this.shipmentsTotal,
    required this.pickupJobsTotal,
    required this.activeZones,
    required this.members,
    required this.activeServices,
    required this.webhookEvents24h,
    required this.webhookFailures24h,
    required this.shipmentsByStatus,
    required this.pickupJobsByStatus,
  });

  factory LogisticsDashboardModel.fromJson(Map<String, dynamic> json) =>
      LogisticsDashboardModel(
        shipmentsTotal: json['shipments_total'] as int? ?? 0,
        pickupJobsTotal: json['pickup_jobs_total'] as int? ?? 0,
        activeZones: json['active_zones'] as int? ?? 0,
        members: json['members'] as int? ?? 0,
        activeServices: json['active_services'] as int? ?? 0,
        webhookEvents24h: json['webhook_events_24h'] as int? ?? 0,
        webhookFailures24h: json['webhook_failures_24h'] as int? ?? 0,
        shipmentsByStatus: _parseStatusMap(json['shipments_by_status']),
        pickupJobsByStatus: _parseStatusMap(json['pickup_jobs_by_status']),
      );

  static Map<String, int> _parseStatusMap(dynamic data) {
    if (data is! Map) return {};
    return data.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
  }
}

class LogisticsCompanyModel {
  final String id;
  final String name;
  final String? status;
  final String? logoUrl;
  final String? country;
  final String? city;
  final String? phone;
  final String? email;

  const LogisticsCompanyModel({
    required this.id,
    required this.name,
    this.status,
    this.logoUrl,
    this.country,
    this.city,
    this.phone,
    this.email,
  });

  factory LogisticsCompanyModel.fromJson(Map<String, dynamic> json) =>
      LogisticsCompanyModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString(),
        logoUrl: json['logo_url']?.toString(),
        country: json['country']?.toString(),
        city: json['city']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
      );
}

class LogisticsAccountModel {
  final String memberId;
  final String memberRole;
  final LogisticsCompanyModel company;

  const LogisticsAccountModel({
    required this.memberId,
    required this.memberRole,
    required this.company,
  });

  factory LogisticsAccountModel.fromJson(Map<String, dynamic> json) =>
      LogisticsAccountModel(
        memberId: json['member_id']?.toString() ?? '',
        memberRole: json['member_role']?.toString() ?? '',
        company: LogisticsCompanyModel.fromJson(
            json['company'] as Map<String, dynamic>? ?? {}),
      );
}

class LogisticsShipmentModel {
  final String id;
  final String status;
  final String? trackingNumber;
  final String? orderId;
  final String? sellerName;
  final String? customerName;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? createdAt;
  final String? estimatedDelivery;

  const LogisticsShipmentModel({
    required this.id,
    required this.status,
    this.trackingNumber,
    this.orderId,
    this.sellerName,
    this.customerName,
    this.pickupAddress,
    this.deliveryAddress,
    this.createdAt,
    this.estimatedDelivery,
  });

  factory LogisticsShipmentModel.fromJson(Map<String, dynamic> json) =>
      LogisticsShipmentModel(
        id: json['id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        trackingNumber: json['tracking_number']?.toString(),
        orderId: json['order_id']?.toString(),
        sellerName: json['seller_name']?.toString(),
        customerName: json['customer_name']?.toString(),
        pickupAddress: json['pickup_address']?.toString(),
        deliveryAddress: json['delivery_address']?.toString(),
        createdAt: json['created_at']?.toString(),
        estimatedDelivery: json['estimated_delivery']?.toString(),
      );
}

class LogisticsWalletModel {
  final String balance;
  final String currency;
  final String? pendingPayouts;
  final String? totalEarned;

  const LogisticsWalletModel({
    required this.balance,
    required this.currency,
    this.pendingPayouts,
    this.totalEarned,
  });

  factory LogisticsWalletModel.fromJson(Map<String, dynamic> json) =>
      LogisticsWalletModel(
        balance: json['balance']?.toString() ?? '0',
        currency: json['currency']?.toString() ?? 'TZS',
        pendingPayouts: json['pending_payouts']?.toString(),
        totalEarned: json['total_earned']?.toString(),
      );
}

class LogisticsTeamMemberModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isActive;

  const LogisticsTeamMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  factory LogisticsTeamMemberModel.fromJson(Map<String, dynamic> json) =>
      LogisticsTeamMemberModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'member',
        phone: json['phone']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

class LogisticsServiceModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final String? serviceType;

  const LogisticsServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.serviceType,
  });

  factory LogisticsServiceModel.fromJson(Map<String, dynamic> json) =>
      LogisticsServiceModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
        serviceType: json['service_type']?.toString(),
      );
}

class LogisticsRateModel {
  final String id;
  final String? zoneName;
  final String? serviceName;
  final String baseRate;
  final String? perKmRate;
  final String? perKgRate;
  final String currency;
  final bool isActive;

  const LogisticsRateModel({
    required this.id,
    this.zoneName,
    this.serviceName,
    required this.baseRate,
    this.perKmRate,
    this.perKgRate,
    required this.currency,
    this.isActive = true,
  });

  factory LogisticsRateModel.fromJson(Map<String, dynamic> json) =>
      LogisticsRateModel(
        id: json['id']?.toString() ?? '',
        zoneName: json['zone_name']?.toString(),
        serviceName: json['service_name']?.toString(),
        baseRate: json['base_rate']?.toString() ?? '0',
        perKmRate: json['per_km_rate']?.toString(),
        perKgRate: json['per_kg_rate']?.toString(),
        currency: json['currency']?.toString() ?? 'TZS',
        isActive: json['is_active'] as bool? ?? true,
      );
}

class LogisticsIntegrationModel {
  final String? apiKey;
  final String? webhookUrl;
  final bool isActive;
  final List<Map<String, dynamic>> recentEvents;

  const LogisticsIntegrationModel({
    this.apiKey,
    this.webhookUrl,
    this.isActive = false,
    this.recentEvents = const [],
  });

  factory LogisticsIntegrationModel.fromJson(Map<String, dynamic> json) =>
      LogisticsIntegrationModel(
        apiKey: json['api_key']?.toString(),
        webhookUrl: json['webhook_url']?.toString(),
        isActive: json['is_active'] as bool? ?? false,
        recentEvents: (json['recent_events'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            const [],
      );
}

class LogisticsOnboardingModel {
  final String status;
  final List<String> completedSteps;
  final List<String> pendingSteps;
  final bool canSubmit;

  const LogisticsOnboardingModel({
    required this.status,
    required this.completedSteps,
    required this.pendingSteps,
    required this.canSubmit,
  });

  factory LogisticsOnboardingModel.fromJson(Map<String, dynamic> json) =>
      LogisticsOnboardingModel(
        status: json['status']?.toString() ?? 'pending',
        completedSteps: (json['completed_steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        pendingSteps: (json['pending_steps'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        canSubmit: json['can_submit'] as bool? ?? false,
      );
}
