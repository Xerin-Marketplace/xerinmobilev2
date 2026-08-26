/// General app constants.
abstract class AppConstants {
  static const String appName = 'XerinMarket';
  static const String appVersion = '1.0.7';

  // Routes
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String signInRoute = '/sign-in';
  static const String registerRoute = '/register';
  static const String verifyOtpRoute = '/verify-otp';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String lockRoute = '/lock';
  static const String pinSetupRoute = '/pin-setup';
  static const String homeRoute = '/';
  static const String categoriesRoute = '/categories';
  static const String categoryProductsRoute = '/category-products';
  static const String exploreProductsRoute = '/explore-products';
  static const String productDetailRoute = '/product-detail';
  static const String registrationSuccessRoute = '/registration-success';
  static const String termsRoute = '/terms';
  static const String privacyRoute = '/privacy';

  // Customer profile routes
  static const String profileInfoRoute = '/profile-info';
  static const String addressesRoute = '/addresses';
  static const String paymentMethodsRoute = '/payment-methods';
  static const String orderHistoryRoute = '/order-history';
  static const String orderDetailRoute = '/order-detail';
  static const String invoiceRoute = '/invoice';
  static const String notificationsRoute = '/notifications';
  static const String settingsRoute = '/settings';
  static const String helpSupportRoute = '/help-support';
  static const String checkoutRoute = '/checkout';
  static const String paymentProcessingRoute = '/payment-processing';

  // Recommendation & discovery routes
  static const String forYouRoute = '/for-you';
  static const String trendingRoute = '/trending';
  static const String flashDealsRoute = '/flash-deals';
  static const String recentlyViewedRoute = '/recently-viewed';
  static const String newArrivalsRoute = '/new-arrivals';
  static const String topRatedRoute = '/top-rated';
  static const String bestSellersRoute = '/best-sellers';
  static const String storesRoute = '/stores';
  static const String orderTrackingRoute = '/order-tracking';
  static const String couponsRoute = '/coupons';

  // Review & Q&A routes
  static const String productReviewsRoute = '/product-reviews';
  static const String productQaRoute = '/product-qa';

  // Search & Promotions routes
  static const String searchRoute = '/search';
  static const String promotionsRoute = '/promotions';

  // Notification preferences route
  static const String notificationPreferencesRoute = '/notification-preferences';

  // Marketplace expansion routes
  static const String buyFromAbroadRoute = '/buy-from-abroad';
  static const String shopTanzaniaRoute = '/shop-tanzania';
  static const String wholesaleRoute = '/wholesale';

  // Seller panel routes
  static const String sellerDashboardRoute = '/seller-dashboard';
  static const String sellerOrdersRoute = '/seller-orders';
  static const String sellerOrderDetailRoute = '/seller-order-detail';
  static const String sellerProductsRoute = '/seller-products';
  static const String sellerInventoryRoute = '/seller-inventory';
  static const String sellerStoreRoute = '/seller-store';
  static const String sellerKycRoute = '/seller-kyc';
  static const String sellerWalletRoute = '/seller-wallet';
  static const String sellerAnalyticsRoute = '/seller-analytics';
  static const String sellerPromotionsRoute = '/seller-promotions';
  static const String sellerReviewsRoute = '/seller-reviews';
  static const String sellerQuestionsRoute = '/seller-questions';

  // Admin panel routes
  static const String adminDashboardRoute = '/admin-dashboard';
  static const String adminSellersRoute = '/admin-sellers';
  static const String adminSellerDetailRoute = '/admin-seller-detail';
  static const String adminProductsRoute = '/admin-products';
  static const String adminOrdersRoute = '/admin-orders';
  static const String adminUsersRoute = '/admin-users';
  static const String adminWalletsRoute = '/admin-wallets';
  static const String adminRefundsRoute = '/admin-refunds';
  static const String adminReviewsRoute = '/admin-reviews';
  static const String adminAnalyticsRoute = '/admin-analytics';
  static const String adminAlertsRoute = '/admin-alerts';
  static const String adminActivityLogsRoute = '/admin-activity-logs';

  // Timeouts
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double buttonHeight = 48.0;
}
