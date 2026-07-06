/// Permission codes used for role-based access control.
///
/// Mirrors the backend Python `PermissionCode` enum — each value is a
/// string identifier sent by the API.
enum PermissionCode {
  viewAllUsers('view_all_users'),
  canCreateUsers('can_create_users'),
  canViewUsers('can_view_users'),
  canUpdateUsers('can_update_users'),
  canDeleteUsers('can_delete_users'),
  canCreateAdminUsers('can_create_admin_users'),
  viewProfile('view_profile'),
  updateProfile('update_profile'),
  manageUsers('manage_users'),
  manageAddresses('manage_addresses'),
  viewSellerProfile('view_seller_profile'),
  updateSellerProfile('update_seller_profile'),
  uploadKyc('upload_kyc'),
  managePayoutAccounts('manage_payout_accounts'),
  manageProducts('manage_products'),

  canCreateBusinessCategories('can_create_business_categories'),
  canViewBusinessCategories('can_view_business_categories'),
  canUpdateBusinessCategories('can_update_business_categories'),
  canDeleteBusinessCategories('can_delete_business_categories'),

  canCreateProductCategories('can_create_product_categories'),
  canViewProductCategories('can_view_product_categories'),
  canDeleteProductCategories('can_delete_product_categories'),

  canCreateBrands('can_create_brands'),
  canViewBrands('can_view_brands'),
  canDeleteBrands('can_delete_brands'),

  canViewSellers('can_view_sellers'),
  canViewPendingSellers('can_view_pending_sellers'),
  canViewSellerDocuments('can_view_seller_documents'),
  canApproveSellers('can_approve_sellers'),
  canRejectSellers('can_reject_sellers'),

  canViewProducts('can_view_products'),
  canApproveProducts('can_approve_products'),
  canRejectProducts('can_reject_products');

  const PermissionCode(this.value);

  /// The string value sent by the backend API.
  final String value;

  /// Parse a string from the API into a [PermissionCode].
  /// Returns `null` if the value doesn't match any known permission.
  static PermissionCode? fromString(String? raw) {
    if (raw == null) return null;
    for (final code in PermissionCode.values) {
      if (code.value == raw) return code;
    }
    return null;
  }

  /// Convenience: check whether a list of permission strings contains
  /// this permission.
  bool isIn(List<String> permissions) => permissions.contains(value);
}
