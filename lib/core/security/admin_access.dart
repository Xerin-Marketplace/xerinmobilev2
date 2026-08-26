import '../../features/auth/data/models/user_model.dart';

/// Mirrors the web frontend `admin-access.ts` permission system.
///
/// Every admin page and action maps to one or more permission codes.
/// Super admins bypass all checks. Staff users with at least one
/// permission can access the admin shell but only see sections/items
/// they are authorised for.
class AdminAccess {
  AdminAccess._();

  // ─── Section-level permissions ───────────────────────────────
  static const Map<String, List<String>> sectionPermissions = {
    'Dashboard': [
      'admin_dashboard:read',
      'admin_dashboard_operations:read',
      'admin_dashboard_finance:read',
      'admin_dashboard_security:read',
    ],
    'Sellers': [
      'can_view_sellers',
      'can_view_pending_sellers',
      'can_view_seller_documents',
      'can_approve_sellers',
      'can_reject_sellers',
    ],
    'Products': [
      'can_view_products',
      'manage_products',
      'can_approve_products',
      'can_reject_products',
    ],
    'Orders': ['orders:read'],
    'Users': [
      'view_all_users',
      'can_view_users',
      'manage_users',
      'can_create_users',
      'can_update_users',
      'can_delete_users',
    ],
    'Wallets': [
      'wallet:read',
      'wallet:adjust',
      'payouts:read',
      'payouts:approve',
    ],
    'Refunds': [
      'refunds:read',
      'refunds:review',
      'refunds:process',
    ],
    'Reviews': [
      'admin_reviews:read',
      'admin_reviews:moderate',
    ],
    'Analytics': [
      'analytics:admin_read',
      'admin_dashboard_finance:read',
      'admin_dashboard_operations:read',
    ],
    'Alerts': [
      'admin_dashboard_security:read',
      'admin_system_alerts:manage',
    ],
    'ActivityLogs': [
      'admin_activity_logs:read',
      'audit_logs:read',
    ],
    'Roles': [
      'can_assign_permissions',
      'manage_users',
    ],
    'Catalog': [
      'admin_brands:read',
      'admin_product_categories:read',
      'admin_business_categories:read',
    ],
    'Payments': [
      'admin_dashboard_finance:read',
    ],
  };

  // ─── Item-level / action-level permissions ───────────────────
  static const Map<String, List<String>> itemPermissions = {
    // Dashboard
    'dashboard.view': ['admin_dashboard:read'],
    'dashboard.orders': ['admin_dashboard_operations:read'],
    'dashboard.sellers': ['admin_dashboard_operations:read'],
    'dashboard.products': ['admin_dashboard_operations:read'],
    'dashboard.customers': ['admin_dashboard:read'],
    'dashboard.payments': ['admin_dashboard_finance:read'],
    'dashboard.refunds': ['admin_dashboard_finance:read'],
    'dashboard.alerts': ['admin_dashboard_security:read'],
    'dashboard.activity_logs': ['admin_activity_logs:read'],

    // Sellers
    'sellers.view': ['can_view_sellers'],
    'sellers.view_pending': ['can_view_pending_sellers'],
    'sellers.view_documents': ['can_view_seller_documents'],
    'sellers.approve': ['can_approve_sellers'],
    'sellers.reject': ['can_reject_sellers'],
    'sellers.start_review': ['can_view_pending_sellers'],

    // Products
    'products.view_pending': ['can_view_products', 'manage_products'],
    'products.approve': ['can_approve_products', 'manage_products'],
    'products.reject': ['can_reject_products', 'manage_products'],

    // Orders
    'orders.view': ['orders:read'],

    // Users
    'users.view': ['view_all_users', 'can_view_users'],
    'users.create': ['can_create_users'],
    'users.update': ['can_update_users'],
    'users.delete': ['can_delete_users'],

    // Wallets
    'wallets.view': ['wallet:read'],
    'wallets.adjust': ['wallet:adjust'],
    'payouts.view': ['payouts:read'],
    'payouts.approve': ['payouts:approve'],

    // Refunds
    'refunds.view': ['refunds:read'],
    'refunds.review': ['refunds:review'],
    'refunds.approve': ['refunds:review'],
    'refunds.reject': ['refunds:review'],
    'refunds.process': ['refunds:process'],

    // Reviews
    'reviews.view': ['admin_reviews:read'],
    'reviews.moderate': ['admin_reviews:moderate'],

    // Analytics
    'analytics.view': ['analytics:admin_read'],

    // Alerts
    'alerts.view': ['admin_dashboard_security:read'],
    'alerts.resolve': ['admin_system_alerts:manage'],

    // Activity logs
    'activity_logs.view': ['admin_activity_logs:read'],

    // Roles & permissions
    'roles.view': ['can_assign_permissions'],
    'roles.edit_permissions': ['can_assign_permissions'],
    'users.assign_permissions': ['can_assign_permissions'],
  };

  // ─── Core helpers ────────────────────────────────────────────

  static bool isSuperAdmin(UserModel? user) =>
      user?.isSuperAdmin ?? false;

  static bool isStaffUser(UserModel? user) => user?.isStaffUser ?? false;

  static bool can(UserModel? user, String permission) {
    if (user == null) return false;
    return user.hasPermission(permission);
  }

  static bool canAny(UserModel? user, List<String> permissions) {
    if (permissions.isEmpty || isSuperAdmin(user)) return true;
    return user?.hasAnyPermission(permissions) ?? false;
  }

  static bool canAll(UserModel? user, List<String> permissions) {
    if (permissions.isEmpty || isSuperAdmin(user)) return true;
    return user?.hasAllPermissions(permissions) ?? false;
  }

  // ─── Section / item checks ───────────────────────────────────

  static bool canAccessSection(UserModel? user, String section) {
    if (isSuperAdmin(user)) return true;
    final perms = sectionPermissions[section];
    if (perms == null) return isStaffUser(user);
    return canAny(user, perms);
  }

  static bool canAccessItem(UserModel? user, String item) {
    if (isSuperAdmin(user)) return true;
    final required = itemPermissions[item];
    if (required == null) return isStaffUser(user);
    if (required.isEmpty) return isStaffUser(user);
    return canAny(user, required);
  }

  static bool canAccessAdminDashboard(UserModel? user) {
    if (user == null) return false;
    return user.isStaffUser &&
        (isSuperAdmin(user) ||
            canAny(user, sectionPermissions['Dashboard']!) ||
            user.permissions.isNotEmpty);
  }

  // ─── Admin route → section mapping ───────────────────────────

  static const Map<String, String> routeToSection = {
    '/admin-dashboard': 'Dashboard',
    '/admin-sellers': 'Sellers',
    '/admin-seller-detail': 'Sellers',
    '/admin-products': 'Products',
    '/admin-orders': 'Orders',
    '/admin-users': 'Users',
    '/admin-wallets': 'Wallets',
    '/admin-refunds': 'Refunds',
    '/admin-reviews': 'Reviews',
    '/admin-analytics': 'Analytics',
    '/admin-alerts': 'Alerts',
    '/admin-activity-logs': 'ActivityLogs',
    '/admin-roles': 'Roles',
    '/admin-finance': 'Finance',
    '/admin-advertisements': 'Advertisements',
    '/admin-marketplace-settings': 'MarketplaceSettings',
    '/admin-catalog': 'Catalog',
    '/admin-payments': 'Payments',
    '/admin-all-orders': 'Orders',
    '/admin-order-detail': 'Orders',
  };

  /// Returns `true` if [routePath] is an admin route that the [user]
  /// is allowed to access.  Non-admin routes always return `true`.
  static bool canAccessRoute(UserModel? user, String routePath) {
    final section = routeToSection[routePath];
    if (section == null) return true; // not an admin route
    return canAccessSection(user, section);
  }
}
