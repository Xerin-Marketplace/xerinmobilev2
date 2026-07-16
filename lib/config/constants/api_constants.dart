/// API-related constants.
abstract class ApiConstants {
    static const String _defaultBaseUrl = 'https://187.124.32.94:8080';
    static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

    static String get baseUrl => _resolveBaseUrl(_envBaseUrl);

    static String _resolveBaseUrl(String candidate) {
        final raw = candidate.trim();
        if (raw.isEmpty) return _defaultBaseUrl;

        final withScheme = raw.contains('://') ? raw : 'https://$raw';
        final parsed = Uri.tryParse(withScheme);
        if (parsed == null || parsed.host.isEmpty) return _defaultBaseUrl;

        final secureUri = parsed.scheme == 'http'
                ? parsed.replace(scheme: 'https')
                : parsed;

        return secureUri.toString().replaceFirst(RegExp(r'/$'), '');
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
  static const String sellerRegister = '/sellers/register';
  static const String sellerProfile = '/sellers/me';
  static const String sellerBusinessProfile = '/sellers/profile';
  static const String sellerKycDocuments = '/sellers/kyc-documents';
  static const String sellerKycBulkUpload = '/sellers/kyc-documents/bulk';
  static const String sellerKycStatus = '/sellers/kyc-status';
  static const String sellerPayoutAccounts = '/sellers/payout-accounts';
  static String sellerPayoutAccountById(String id) =>
      '/sellers/payout-accounts/$id';

  // Store endpoints
  static const String myStore = '/stores/me';
  static const String myStoreLogo = '/stores/me/logo';
  static const String myStoreBanner = '/stores/me/banner';
  static const String publicStores = '/stores';
  static String publicStoreBySlug(String slug) => '/stores/$slug';

  // Inventory endpoints
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

  // Order endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';

  // Payment method endpoints
  static const String paymentMethods = '/payment-methods';
  static String paymentMethodById(String id) => '/payment-methods/$id';

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
