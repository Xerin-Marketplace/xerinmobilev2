/// API-related constants.
abstract class ApiConstants {
    static const String _defaultBaseUrl = 'http://187.124.32.94:8080';
    static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

    static String get baseUrl => _resolveBaseUrl(_envBaseUrl);

    static String _resolveBaseUrl(String candidate) {
        final raw = candidate.trim();
        if (raw.isEmpty) return _defaultBaseUrl;

        final withScheme = raw.contains('://') ? raw : 'http://$raw';
        final parsed = Uri.tryParse(withScheme);
        if (parsed == null || parsed.host.isEmpty) return _defaultBaseUrl;

        return parsed.toString().replaceFirst(RegExp(r'/$'), '');
    }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String registerSeller = '/auth/register-seller';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String myProfile = '/users/me';

  // Address endpoints
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';

  // Seller endpoints
  static const String sellerProfile = '/sellers/me';
  static const String sellerBusinessProfile = '/sellers/profile';
  static const String sellerKycDocuments = '/sellers/kyc-documents';
  static const String sellerKycBulkUpload = '/sellers/kyc-documents/bulk';
  static const String sellerKycStatus = '/sellers/kyc-status';
  static const String sellerPayoutAccounts = '/sellers/payout-accounts';
  static String sellerPayoutAccountById(String id) =>
      '/sellers/payout-accounts/$id';

  // Seller admin endpoints
  static const String adminPendingSellers = '/sellers/admin/pending';
  static String adminSellerDocuments(String sellerId) =>
      '/sellers/admin/$sellerId/documents';
  static String adminApproveSeller(String sellerId) =>
      '/sellers/admin/$sellerId/approve';
  static String adminRejectSeller(String sellerId) =>
      '/sellers/admin/$sellerId/reject';

  // Admin endpoints
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static const String adminCreateAdmin = '/admin/admins';
  static const String adminBusinessCategories = '/admin/business-categories';
  static String adminBusinessCategoryById(String id) =>
      '/admin/business-categories/$id';
  static const String adminProductCategories = '/admin/product-categories';
  static String adminProductCategoryById(String id) =>
      '/admin/product-categories/$id';
  static const String adminBrands = '/admin/brands';
  static String adminBrandById(String id) => '/admin/brands/$id';
  static const String adminSellers = '/admin/sellers';
  static const String adminSellersPending = '/admin/sellers/pending';
  static String adminSellerById(String id) => '/admin/sellers/$id';
  static String adminSellerDocs(String id) => '/admin/sellers/$id/documents';
  static String adminApproveSellerById(String id) =>
      '/admin/sellers/$id/approve';
  static String adminRejectSellerById(String id) =>
      '/admin/sellers/$id/reject';
  static const String adminProductsPending = '/admin/products/pending';
  static String adminApproveProduct(String id) =>
      '/admin/products/$id/approve';
  static String adminRejectProduct(String id) =>
      '/admin/products/$id/reject';

  // Store endpoints (used by seller datasource)
  static const String myStore = '/stores/me';
  static const String myStoreLogo = '/stores/me/logo';
  static const String myStoreBanner = '/stores/me/banner';
  static const String publicStores = '/stores';
  static String publicStoreBySlug(String slug) => '/stores/$slug';

  // Inventory endpoints (used by seller datasource)
  static const String inventory = '/inventory';
  static const String myInventory = '/inventory/my-inventory';
  static const String lowStockInventory = '/inventory/low-stock';
  static String inventoryByProduct(String productId) =>
      '/inventory/product/$productId';
  static String inventoryById(String id) => '/inventory/$id';

  // Product endpoints
  static const String products = '/products';
  static const String myProducts = '/products/my-products';
  static const String productCategories = '/products/categories';
  static const String productBrands = '/products/brands';
  static String productById(String id) => '/products/$id';
  static String productImages(String id) => '/products/$id/images';
  static String productImageById(String productId, String imageId) =>
      '/products/$productId/images/$imageId';
  static String productVariants(String id) => '/products/$id/variants';
  static String productVariantById(String productId, String variantId) =>
      '/products/$productId/variants/$variantId';
  static String productTags(String id) => '/products/$id/tags';
  static String productTagById(String productId, String tagId) =>
      '/products/$productId/tags/$tagId';
  static String categoryById(String id) => '/products/categories/$id';
  static String brandById(String id) => '/products/brands/$id';

  // Cart endpoints
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItemById(String id) => '/cart/items/$id';
  static const String cartApplyCoupon = '/cart/apply-coupon';
  static const String cartRemoveCoupon = '/cart/coupon';

  // Order endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // Payment endpoints
  static const String paymentsInitiate = '/payments/initiate';
  static const String paymentsCallback = '/payments/callback';
  static String paymentById(String id) => '/payments/$id';
  static String paymentCallbackByProvider(String provider) =>
      '/payments/callback/$provider';

  // Payment method endpoints
  static const String paymentMethods = '/payment-methods';
  static String paymentMethodById(String id) => '/payment-methods/$id';

  // Coupon endpoints
  static const String coupons = '/coupons';
  static String couponById(String id) => '/coupons/$id';
  static String couponValidate(String code) => '/coupons/validate/$code';

  // Recommendation endpoints
  static const String recommendedProducts = '/products/recommended';
  static const String trendingProducts = '/products/trending';
  static const String flashDeals = '/products/flash-deals';
  static const String recentlyViewed = '/products/recently-viewed';
  static const String relatedProducts = '/products/related';
  static String relatedByProduct(String productId) =>
      '/products/$productId/related';
  static const String newArrivals = '/products/new-arrivals';
  static const String topRated = '/products/top-rated';
  static const String bestSellers = '/products/best-sellers';

  // Store endpoints (public browsing)
  static String storeProducts(String slug) => '/stores/$slug/products';

  // Notification endpoints
  static const String notifications = '/notifications';

  // Wishlist endpoints
  static const String wishlist = '/wishlists';
  static String wishlistById(String id) => '/wishlists/$id';
  static String toggleWishlistItem(String productId) => '/wishlists/toggle/$productId';

  // Common headers
  static const String contentType = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
