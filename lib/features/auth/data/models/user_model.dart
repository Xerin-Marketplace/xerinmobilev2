class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final bool isVerified;
  final String status;
  final String accountType;
  final List<String> roles;
  final List<String> permissions;
  final bool isSeller;
  final String? sellerStatus;
  final bool isBroker;
  final String? brokerStatus;
  final String? brokerCode;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.isVerified,
    required this.status,
    this.accountType = 'customer',
    this.roles = const [],
    this.permissions = const [],
    this.isSeller = false,
    this.sellerStatus,
    this.isBroker = false,
    this.brokerStatus,
    this.brokerCode,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin =>
      accountType == 'super_admin' ||
      accountType == 'admin' ||
      roles.contains('super_admin') ||
      roles.contains('admin');

  bool get isSuperAdmin =>
      accountType == 'super_admin' || roles.contains('super_admin');

  bool get isStaffUser {
    if (accountType == 'admin' ||
        accountType == 'super_admin' ||
        isSuperAdmin) {
      return true;
    }
    const basicNonStaffRoles = {'buyer', 'customer', 'seller', 'broker'};
    return roles.any((r) => !basicNonStaffRoles.contains(r.toLowerCase()));
  }

  bool hasPermission(String permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> perms) {
    if (perms.isEmpty || isSuperAdmin) return true;
    return perms.any(hasPermission);
  }

  bool hasAllPermissions(List<String> perms) {
    if (perms.isEmpty || isSuperAdmin) return true;
    return perms.every(hasPermission);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        status: json['status']?.toString() ?? 'active',
        accountType: json['account_type'] as String? ?? 'customer',
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        permissions: (json['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isSeller: json['is_seller'] as bool? ?? false,
        sellerStatus: json['seller_status']?.toString(),
        isBroker: json['is_broker'] as bool? ?? false,
        brokerStatus: json['broker_status']?.toString(),
        brokerCode: json['broker_code']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'is_verified': isVerified,
        'status': status,
        'account_type': accountType,
        'roles': roles,
        'permissions': permissions,
        'is_seller': isSeller,
        'seller_status': sellerStatus,
        'is_broker': isBroker,
        'broker_status': brokerStatus,
        'broker_code': brokerCode,
      };
}
