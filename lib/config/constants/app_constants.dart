/// General app constants.
abstract class AppConstants {
  static const String appName = 'XerinMarket';
  static const String appVersion = '1.0.2';

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
  static const String sellerDashboardRoute = '/seller-dashboard';
  static const String sellerOnboardingRoute = '/seller-onboarding';
  static const String sellerDetailsRoute = '/seller-details';
  static const String sellerShopDetailsRoute = '/seller/shop-details';
  static const String sellerShippingOptionsRoute = '/seller/shipping-options';
  static const String sellerPayoutsRoute = '/seller/payouts';
  static const String sellerReportsRoute = '/seller/reports';
  static const String sellerSupportRoute = '/seller/support';
  static const String sellerKycRoute = '/seller/kyc';
  static const String registrationSuccessRoute = '/registration-success';
  static const String termsRoute = '/terms';
  static const String privacyRoute = '/privacy';

  // Customer profile routes
  static const String profileInfoRoute = '/profile-info';
  static const String addressesRoute = '/addresses';
  static const String paymentMethodsRoute = '/payment-methods';
  static const String orderHistoryRoute = '/order-history';
  static const String orderDetailRoute = '/order-detail';
  static const String notificationsRoute = '/notifications';
  static const String settingsRoute = '/settings';
  static const String helpSupportRoute = '/help-support';
  static const String checkoutRoute = '/checkout';

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
