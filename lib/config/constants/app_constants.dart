import '../../features/auth/data/models/user_model.dart';

/// General app constants.
abstract class AppConstants {
  static const String appName = 'XerinMarket';
  static const String appVersion = '1.0.10';

  // Routes
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String signInRoute = '/sign-in';
  static const String registerRoute = '/register';
  static const String sellerRegisterRoute = '/seller-register';
  static const String brokerRegisterRoute = '/broker-register';
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
  static const String supportTicketsRoute = '/support-tickets';
  static const String supportTicketDetailRoute = '/support-ticket-detail';
  static const String supportTicketCreateRoute = '/support-ticket-create';
  static const String deliveryVerificationRoute = '/delivery-verification';
  static const String customerSecurityRoute = '/customer-security';
  static const String customerReviewsRoute = '/customer-reviews';
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
  static const String sellerPickupLocationsRoute = '/seller-pickup-locations';
  static const String sellerFulfillmentRoute = '/seller-fulfillment';
  static const String sellerFulfillmentDetailRoute = '/seller-fulfillment-detail';
  static const String sellerCancellationsRoute = '/seller-cancellations';
  static const String sellerReturnsRoute = '/seller-returns';

  // Broker panel routes
  static const String brokerDashboardRoute = '/broker-dashboard';
  static const String brokerKycRoute = '/broker-kyc';
  static const String brokerWalletRoute = '/broker-wallet';
  static const String brokerOpportunitiesRoute = '/broker-opportunities';
  static const String brokerProductsRoute = '/broker-products';
  static const String brokerAnalyticsRoute = '/broker-analytics';
  static const String brokerEarningsRoute = '/broker-earnings';
  static const String mawingaFindProductsRoute = '/mawinga-find-products';
  static const String mawingaShareEarnRoute = '/mawinga-share-earn';
  static const String mawingaLeaderboardRoute = '/mawinga-leaderboard';
  static const String mawingaAcademyRoute = '/mawinga-academy';
  static const String mawingaStoreRoute = '/mawinga-store';
  static const String mawingaReferralRoute = '/mawinga-referral';

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
  static const String adminRolesRoute = '/admin-roles';
  static const String adminFinanceRoute = '/admin-finance';
  static const String adminAdvertisementsRoute = '/admin-advertisements';
  static const String adminMarketplaceSettingsRoute = '/admin-marketplace-settings';

  // Admin additional routes
  static const String adminCatalogRoute = '/admin-catalog';
  static const String adminPaymentsRoute = '/admin-payments';
  static const String adminAllOrdersRoute = '/admin-all-orders';
  static const String adminOrderDetailRoute = '/admin-order-detail';

  // Logistics panel routes
  static const String logisticsDashboardRoute = '/logistics-dashboard';
  static const String logisticsShipmentsRoute = '/logistics-shipments';
  static const String logisticsWalletRoute = '/logistics-wallet';
  static const String logisticsTeamRoute = '/logistics-team';
  static const String logisticsPricingRoute = '/logistics-pricing';
  static const String logisticsIntegrationRoute = '/logistics-integration';
  static const String logisticsOnboardingRoute = '/logistics-onboarding';
  static const String logisticsSettingsRoute = '/logistics-settings';

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

  /// Returns the dashboard route based on the user's role.
  /// Admin → admin dashboard, Seller → seller dashboard,
  /// Broker → broker dashboard, default → customer home.
  static String dashboardRouteForUser(UserModel? user) {
    if (user == null) return homeRoute;
    if (user.isAdmin) return adminDashboardRoute;
    if (user.isSeller) return sellerDashboardRoute;
    if (user.isBroker) return brokerDashboardRoute;
    return homeRoute;
  }

  /// Routes that require authentication (guests are blocked).
  static const authRequiredRoutes = [
    checkoutRoute,
    paymentProcessingRoute,
    orderHistoryRoute,
    orderDetailRoute,
    invoiceRoute,
    orderTrackingRoute,
    profileInfoRoute,
    addressesRoute,
    paymentMethodsRoute,
    notificationsRoute,
    notificationPreferencesRoute,
    settingsRoute,
    helpSupportRoute,
    supportTicketsRoute,
    supportTicketDetailRoute,
    supportTicketCreateRoute,
    deliveryVerificationRoute,
    customerSecurityRoute,
    customerReviewsRoute,
    sellerDashboardRoute,
    brokerDashboardRoute,
    adminDashboardRoute,
  ];

  /// Routes that guests are allowed to browse.
  static const guestAllowedRoutes = [
    homeRoute,
    categoriesRoute,
    categoryProductsRoute,
    exploreProductsRoute,
    productDetailRoute,
    searchRoute,
    storesRoute,
    promotionsRoute,
    trendingRoute,
    forYouRoute,
    flashDealsRoute,
    recentlyViewedRoute,
    newArrivalsRoute,
    topRatedRoute,
    bestSellersRoute,
    buyFromAbroadRoute,
    shopTanzaniaRoute,
    wholesaleRoute,
    productReviewsRoute,
    productQaRoute,
    couponsRoute,
    termsRoute,
    privacyRoute,
  ];
}
