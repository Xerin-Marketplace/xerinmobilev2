import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/security/admin_access.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/legal_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/seller_register_page.dart';
import '../../features/auth/presentation/pages/broker_register_page.dart';
import '../../features/auth/presentation/pages/registration_success_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/customer/presentation/pages/addresses_page.dart';
import '../../features/customer/presentation/pages/categories_page.dart';
import '../../features/customer/presentation/pages/category_products_page.dart';
import '../../features/customer/presentation/pages/customer_dashboard.dart';
import '../../features/customer/data/models/product_model.dart';
import '../../features/customer/data/models/order_model.dart';
import '../../features/customer/presentation/pages/explore_products_page.dart';
import '../../features/customer/presentation/pages/help_support_page.dart';
import '../../features/customer/presentation/pages/checkout_page.dart';
import '../../features/customer/presentation/pages/payment_processing_page.dart';
import '../../features/customer/presentation/pages/coupons_page.dart';
import '../../features/customer/presentation/pages/for_you_page.dart';
import '../../features/customer/presentation/pages/notifications_page.dart';
import '../../features/customer/presentation/pages/notification_preferences_page.dart';
import '../../features/customer/presentation/pages/order_detail_page.dart';
import '../../features/customer/presentation/pages/order_history_page.dart';
import '../../features/customer/presentation/pages/invoice_page.dart';
import '../../features/customer/presentation/pages/order_tracking_page.dart';
import '../../features/customer/presentation/pages/payment_methods_page.dart';
import '../../features/customer/presentation/pages/product_detail_page.dart';
import '../../features/customer/presentation/pages/product_reviews_page.dart';
import '../../features/customer/presentation/pages/product_qa_page.dart';
import '../../features/customer/presentation/pages/profile_info_page.dart';
import '../../features/customer/presentation/pages/promotions_page.dart';
import '../../features/customer/presentation/pages/buy_from_abroad_page.dart';
import '../../features/customer/presentation/pages/shop_tanzania_page.dart';
import '../../features/customer/presentation/pages/wholesale_page.dart';
import '../../features/customer/presentation/pages/recently_viewed_page.dart';
import '../../features/customer/presentation/pages/search_page.dart';
import '../../features/customer/presentation/pages/settings_page.dart';
import '../../features/customer/presentation/pages/stores_page.dart';
import '../../features/customer/presentation/pages/support_tickets_page.dart';
import '../../features/customer/presentation/pages/support_ticket_detail_page.dart';
import '../../features/customer/presentation/pages/support_ticket_create_page.dart';
import '../../features/customer/presentation/pages/delivery_verification_page.dart';
import '../../features/customer/presentation/pages/customer_security_page.dart';
import '../../features/customer/presentation/pages/customer_reviews_page.dart';
import '../../features/customer/presentation/pages/trending_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_order_detail_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/seller/presentation/pages/seller_inventory_page.dart';
import '../../features/seller/presentation/pages/seller_store_page.dart';
import '../../features/seller/presentation/pages/seller_kyc_page.dart';
import '../../features/seller/presentation/pages/seller_wallet_page.dart';
import '../../features/seller/presentation/pages/seller_analytics_page.dart';
import '../../features/seller/presentation/pages/seller_promotions_page.dart';
import '../../features/seller/presentation/pages/seller_reviews_page.dart';
import '../../features/seller/presentation/pages/seller_questions_page.dart';
import '../../features/seller/presentation/pages/seller_pickup_locations_page.dart';
import '../../features/seller/presentation/pages/seller_fulfillment_page.dart';
import '../../features/seller/presentation/pages/seller_fulfillment_detail_page.dart';
import '../../features/seller/presentation/pages/seller_cancellations_page.dart';
import '../../features/seller/presentation/pages/seller_returns_page.dart';
import '../../features/broker/presentation/pages/broker_dashboard_page.dart';
import '../../features/broker/presentation/pages/broker_kyc_page.dart';
import '../../features/broker/presentation/pages/broker_wallet_page.dart';
import '../../features/broker/presentation/pages/broker_opportunities_page.dart';
import '../../features/broker/presentation/pages/broker_products_page.dart';
import '../../features/broker/presentation/pages/broker_analytics_page.dart';
import '../../features/broker/presentation/pages/broker_earnings_page.dart';
import '../../features/broker/presentation/pages/mawinga_find_products_page.dart';
import '../../features/broker/presentation/pages/mawinga_share_earn_page.dart';
import '../../features/broker/presentation/pages/mawinga_leaderboard_page.dart';
import '../../features/broker/presentation/pages/mawinga_academy_page.dart';
import '../../features/broker/presentation/pages/mawinga_store_page.dart';
import '../../features/broker/presentation/pages/mawinga_referral_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_sellers_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_wallets_page.dart';
import '../../features/admin/presentation/pages/admin_refunds_page.dart';
import '../../features/admin/presentation/pages/admin_reviews_page.dart';
import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/admin/presentation/pages/admin_alerts_page.dart';
import '../../features/admin/presentation/pages/admin_activity_logs_page.dart';
import '../../features/admin/presentation/pages/admin_roles_page.dart';
import '../../features/admin/presentation/pages/admin_finance_page.dart';
import '../../features/admin/presentation/pages/admin_advertisements_page.dart';
import '../../features/admin/presentation/pages/admin_marketplace_settings_page.dart';
import '../../features/admin/presentation/pages/admin_catalog_page.dart';
import '../../features/admin/presentation/pages/admin_payments_page.dart';
import '../../features/admin/presentation/pages/admin_all_orders_page.dart';
import '../../features/admin/presentation/pages/admin_order_detail_page.dart';
import '../../features/logistics/presentation/pages/logistics_dashboard_page.dart';
import '../../features/logistics/presentation/pages/logistics_shipments_page.dart';
import '../../features/logistics/presentation/pages/logistics_wallet_page.dart';
import '../../features/logistics/presentation/pages/logistics_team_page.dart';
import '../../features/logistics/presentation/pages/logistics_pricing_page.dart';
import '../../features/logistics/presentation/pages/logistics_integration_page.dart';
import '../../features/logistics/presentation/pages/logistics_onboarding_page.dart';
import '../../features/logistics/presentation/pages/logistics_settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static const _publicRoutes = [
    '/splash',
    '/onboarding',
    '/sign-in',
    '/register',
    '/seller-register',
    '/broker-register',
    '/verify-otp',
    '/forgot-password',
    '/reset-password',
    '/terms',
    '/privacy',
    '/registration-success',
  ];

  static final GoRouter router = GoRouter(
    navigatorKey: NotificationService.navigatorKey,
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      final isPublic = _publicRoutes.contains(path);
      final tokenStorage = GetIt.instance<TokenStorage>();
      final isAuthenticated = tokenStorage.isAuthenticated;
      final isGuest = tokenStorage.isGuest;

      // Authenticated users skip splash/onboarding/sign-in
      if (isPublic && isAuthenticated && path != '/splash' && path != '/onboarding') {
        final user = tokenStorage.currentUser;
        return AppConstants.dashboardRouteForUser(user);
      }

      // Guests can browse guest-allowed routes
      if (!isPublic && !isAuthenticated && isGuest) {
        if (AppConstants.authRequiredRoutes.contains(path)) {
          return AppConstants.signInRoute;
        }
        return null;
      }

      // Non-authenticated, non-guest users must sign in
      if (!isPublic && !isAuthenticated) {
        return AppConstants.signInRoute;
      }

      // Admin route protection — check role-based permissions
      if (isAuthenticated && AdminAccess.routeToSection.containsKey(path)) {
        final UserModel? user = tokenStorage.currentUser;
        if (!AdminAccess.canAccessRoute(user, path)) {
          return AppConstants.homeRoute;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppConstants.onboardingRoute,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppConstants.signInRoute,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppConstants.sellerRegisterRoute,
        builder: (context, state) => const SellerRegisterPage(),
      ),
      GoRoute(
        path: AppConstants.brokerRegisterRoute,
        builder: (context, state) => const BrokerRegisterPage(),
      ),
      GoRoute(
        path: AppConstants.verifyOtpRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyOtpPage(
            phone: extra?['phone'] as String? ?? '',
            fromLogin: extra?['fromLogin'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppConstants.resetPasswordRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResetPasswordPage(
            email: extra?['email'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppConstants.lockRoute,
        builder: (context, state) => const LockScreenPage(),
      ),
      GoRoute(
        path: AppConstants.pinSetupRoute,
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        builder: (context, state) => const CustomerDashboard(),
      ),
      GoRoute(
        path: AppConstants.categoriesRoute,
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: AppConstants.categoryProductsRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CategoryProductsPage(
            category: extra?['category'] as String? ?? 'All',
            categoryId: extra?['categoryId'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppConstants.productDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final product = extra?['product'] as ProductModel?;
          return ProductDetailPage(
            product: product ??
                ProductModel(
                  id: '0',
                  sellerId: '',
                  categoryId: '',
                  sku: '',
                  name: 'Product',
                  slug: 'product',
                  price: 0.0,
                ),
            category: extra?['category'] as String? ?? 'All',
          );
        },
      ),
      GoRoute(
        path: AppConstants.exploreProductsRoute,
        builder: (context, state) => const ExploreProductsPage(),
      ),
      GoRoute(
        path: AppConstants.registrationSuccessRoute,
        builder: (context, state) => const RegistrationSuccessPage(),
      ),
      GoRoute(
        path: AppConstants.termsRoute,
        builder: (context, state) => LegalPage.termsOfService(),
      ),
      GoRoute(
        path: AppConstants.privacyRoute,
        builder: (context, state) => LegalPage.privacyPolicy(),
      ),
      // Customer profile sub-pages
      GoRoute(
        path: AppConstants.profileInfoRoute,
        builder: (context, state) => const ProfileInfoPage(),
      ),
      GoRoute(
        path: AppConstants.addressesRoute,
        builder: (context, state) => const AddressesPage(),
      ),
      GoRoute(
        path: AppConstants.paymentMethodsRoute,
        builder: (context, state) => const PaymentMethodsPage(),
      ),
      GoRoute(
        path: AppConstants.orderHistoryRoute,
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: AppConstants.orderDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final order = extra?['order'] as OrderModel?;
          if (order == null) {
            return const Scaffold(
              body: Center(child: Text('Order not found')),
            );
          }
          return OrderDetailPage(order: order);
        },
      ),
      GoRoute(
        path: AppConstants.invoiceRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final order = extra?['order'] as OrderModel?;
          if (order == null) {
            return const Scaffold(
              body: Center(child: Text('Order not found')),
            );
          }
          return InvoicePage(order: order);
        },
      ),
      GoRoute(
        path: AppConstants.notificationsRoute,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppConstants.settingsRoute,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppConstants.helpSupportRoute,
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: AppConstants.supportTicketsRoute,
        builder: (context, state) => const SupportTicketsPage(),
      ),
      GoRoute(
        path: AppConstants.supportTicketDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SupportTicketDetailPage(
            ticketId: extra?['ticketId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppConstants.supportTicketCreateRoute,
        builder: (context, state) => const SupportTicketCreatePage(),
      ),
      GoRoute(
        path: AppConstants.deliveryVerificationRoute,
        builder: (context, state) => const DeliveryVerificationPage(),
      ),
      GoRoute(
        path: AppConstants.customerSecurityRoute,
        builder: (context, state) => const CustomerSecurityPage(),
      ),
      GoRoute(
        path: AppConstants.customerReviewsRoute,
        builder: (context, state) => const CustomerReviewsPage(),
      ),
      GoRoute(
        path: AppConstants.checkoutRoute,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: AppConstants.paymentProcessingRoute,
        builder: (context, state) {
          final paymentId = state.uri.queryParameters['payment_id'];
          final orderId = state.uri.queryParameters['order_id'];
          final checkoutUrl = state.uri.queryParameters['checkout_url'];
          return PaymentProcessingPage(
            paymentId: paymentId,
            orderId: orderId,
            checkoutUrl: checkoutUrl,
          );
        },
      ),
      // Recommendation & discovery routes
      GoRoute(
        path: AppConstants.forYouRoute,
        builder: (context, state) => const ForYouPage(),
      ),
      GoRoute(
        path: AppConstants.trendingRoute,
        builder: (context, state) => const TrendingPage(),
      ),
      GoRoute(
        path: AppConstants.flashDealsRoute,
        builder: (context, state) => const TrendingPage(),
      ),
      GoRoute(
        path: AppConstants.recentlyViewedRoute,
        builder: (context, state) => const RecentlyViewedPage(),
      ),
      GoRoute(
        path: AppConstants.newArrivalsRoute,
        builder: (context, state) => const ForYouPage(),
      ),
      GoRoute(
        path: AppConstants.topRatedRoute,
        builder: (context, state) => const ForYouPage(),
      ),
      GoRoute(
        path: AppConstants.bestSellersRoute,
        builder: (context, state) => const ForYouPage(),
      ),
      GoRoute(
        path: AppConstants.storesRoute,
        builder: (context, state) => const StoresPage(),
      ),
      GoRoute(
        path: AppConstants.orderTrackingRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final order = extra?['order'] as OrderModel?;
          if (order == null) {
            return const Scaffold(
              body: Center(child: Text('Order not found')),
            );
          }
          return OrderTrackingPage(order: order);
        },
      ),
      GoRoute(
        path: AppConstants.couponsRoute,
        builder: (context, state) => const CouponsPage(),
      ),
      // New feature routes
      GoRoute(
        path: AppConstants.productReviewsRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProductReviewsPage(
            productId: extra?['productId'] as String? ?? '',
            productName: extra?['productName'] as String? ?? 'Product',
          );
        },
      ),
      GoRoute(
        path: AppConstants.productQaRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProductQaPage(
            productId: extra?['productId'] as String? ?? '',
            productName: extra?['productName'] as String? ?? 'Product',
          );
        },
      ),
      GoRoute(
        path: AppConstants.searchRoute,
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: AppConstants.promotionsRoute,
        builder: (context, state) => const PromotionsPage(),
      ),
      GoRoute(
        path: AppConstants.notificationPreferencesRoute,
        builder: (context, state) => const NotificationPreferencesPage(),
      ),
      // Marketplace expansion routes
      GoRoute(
        path: AppConstants.buyFromAbroadRoute,
        builder: (context, state) => const BuyFromAbroadPage(),
      ),
      GoRoute(
        path: AppConstants.shopTanzaniaRoute,
        builder: (context, state) => const ShopTanzaniaPage(),
      ),
      GoRoute(
        path: AppConstants.wholesaleRoute,
        builder: (context, state) => const WholesalePage(),
      ),
      // Seller panel routes
      GoRoute(
        path: AppConstants.sellerDashboardRoute,
        builder: (context, state) => const SellerDashboardPage(),
      ),
      GoRoute(
        path: AppConstants.sellerOrdersRoute,
        builder: (context, state) => const SellerOrdersPage(),
      ),
      GoRoute(
        path: AppConstants.sellerOrderDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as String? ?? '';
          return SellerOrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppConstants.sellerProductsRoute,
        builder: (context, state) => const SellerProductsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerInventoryRoute,
        builder: (context, state) => const SellerInventoryPage(),
      ),
      GoRoute(
        path: AppConstants.sellerStoreRoute,
        builder: (context, state) => const SellerStorePage(),
      ),
      GoRoute(
        path: AppConstants.sellerKycRoute,
        builder: (context, state) => const SellerKycPage(),
      ),
      GoRoute(
        path: AppConstants.sellerWalletRoute,
        builder: (context, state) => const SellerWalletPage(),
      ),
      GoRoute(
        path: AppConstants.sellerAnalyticsRoute,
        builder: (context, state) => const SellerAnalyticsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerPromotionsRoute,
        builder: (context, state) => const SellerPromotionsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerReviewsRoute,
        builder: (context, state) => const SellerReviewsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerQuestionsRoute,
        builder: (context, state) => const SellerQuestionsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerPickupLocationsRoute,
        builder: (context, state) => const SellerPickupLocationsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerFulfillmentRoute,
        builder: (context, state) => const SellerFulfillmentPage(),
      ),
      GoRoute(
        path: AppConstants.sellerFulfillmentDetailRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SellerFulfillmentDetailPage(
            sellerOrderId: extra?['sellerOrderId'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppConstants.sellerCancellationsRoute,
        builder: (context, state) => const SellerCancellationsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerReturnsRoute,
        builder: (context, state) => const SellerReturnsPage(),
      ),
      // Broker panel routes
      GoRoute(
        path: AppConstants.brokerDashboardRoute,
        builder: (context, state) => const BrokerDashboardPage(),
      ),
      GoRoute(
        path: AppConstants.brokerKycRoute,
        builder: (context, state) => const BrokerKycPage(),
      ),
      GoRoute(
        path: AppConstants.brokerWalletRoute,
        builder: (context, state) => const BrokerWalletPage(),
      ),
      GoRoute(
        path: AppConstants.brokerOpportunitiesRoute,
        builder: (context, state) => const BrokerOpportunitiesPage(),
      ),
      GoRoute(
        path: AppConstants.brokerProductsRoute,
        builder: (context, state) => const BrokerProductsPage(),
      ),
      GoRoute(
        path: AppConstants.brokerAnalyticsRoute,
        builder: (context, state) => const BrokerAnalyticsPage(),
      ),
      GoRoute(
        path: AppConstants.brokerEarningsRoute,
        builder: (context, state) => const BrokerEarningsPage(),
      ),
      GoRoute(
        path: AppConstants.mawingaFindProductsRoute,
        builder: (context, state) => const MawingaFindProductsPage(),
      ),
      GoRoute(
        path: AppConstants.mawingaShareEarnRoute,
        builder: (context, state) => const MawingaShareEarnPage(),
      ),
      GoRoute(
        path: AppConstants.mawingaLeaderboardRoute,
        builder: (context, state) => const MawingaLeaderboardPage(),
      ),
      GoRoute(
        path: AppConstants.mawingaAcademyRoute,
        builder: (context, state) => const MawingaAcademyPage(),
      ),
      GoRoute(
        path: AppConstants.mawingaStoreRoute,
        builder: (context, state) => const MawingaStorePage(),
      ),
      GoRoute(
        path: AppConstants.mawingaReferralRoute,
        builder: (context, state) => const MawingaReferralPage(),
      ),
      // Admin panel routes
      GoRoute(
        path: AppConstants.adminDashboardRoute,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppConstants.adminSellersRoute,
        builder: (context, state) => const AdminSellersPage(),
      ),
      GoRoute(
        path: AppConstants.adminSellerDetailRoute,
        builder: (context, state) => const AdminSellersPage(),
      ),
      GoRoute(
        path: AppConstants.adminProductsRoute,
        builder: (context, state) => const AdminProductsPage(),
      ),
      GoRoute(
        path: AppConstants.adminOrdersRoute,
        builder: (context, state) => const AdminOrdersPage(),
      ),
      GoRoute(
        path: AppConstants.adminUsersRoute,
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: AppConstants.adminWalletsRoute,
        builder: (context, state) => const AdminWalletsPage(),
      ),
      GoRoute(
        path: AppConstants.adminRefundsRoute,
        builder: (context, state) => const AdminRefundsPage(),
      ),
      GoRoute(
        path: AppConstants.adminReviewsRoute,
        builder: (context, state) => const AdminReviewsPage(),
      ),
      GoRoute(
        path: AppConstants.adminAnalyticsRoute,
        builder: (context, state) => const AdminAnalyticsPage(),
      ),
      GoRoute(
        path: AppConstants.adminAlertsRoute,
        builder: (context, state) => const AdminAlertsPage(),
      ),
      GoRoute(
        path: AppConstants.adminActivityLogsRoute,
        builder: (context, state) => const AdminActivityLogsPage(),
      ),
      GoRoute(
        path: AppConstants.adminRolesRoute,
        builder: (context, state) => const AdminRolesPage(),
      ),
      GoRoute(
        path: AppConstants.adminFinanceRoute,
        builder: (context, state) => const AdminFinancePage(),
      ),
      GoRoute(
        path: AppConstants.adminAdvertisementsRoute,
        builder: (context, state) => const AdminAdvertisementsPage(),
      ),
      GoRoute(
        path: AppConstants.adminMarketplaceSettingsRoute,
        builder: (context, state) => const AdminMarketplaceSettingsPage(),
      ),
      GoRoute(
        path: AppConstants.adminCatalogRoute,
        builder: (context, state) => const AdminCatalogPage(),
      ),
      GoRoute(
        path: AppConstants.adminPaymentsRoute,
        builder: (context, state) => const AdminPaymentsPage(),
      ),
      GoRoute(
        path: AppConstants.adminAllOrdersRoute,
        builder: (context, state) => const AdminAllOrdersPage(),
      ),
      GoRoute(
        path: AppConstants.adminOrderDetailRoute,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['id'] ?? '';
          return AdminOrderDetailPage(orderId: orderId);
        },
      ),
      // Logistics panel routes
      GoRoute(
        path: AppConstants.logisticsDashboardRoute,
        builder: (context, state) => const LogisticsDashboardPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsShipmentsRoute,
        builder: (context, state) => const LogisticsShipmentsPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsWalletRoute,
        builder: (context, state) => const LogisticsWalletPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsTeamRoute,
        builder: (context, state) => const LogisticsTeamPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsPricingRoute,
        builder: (context, state) => const LogisticsPricingPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsIntegrationRoute,
        builder: (context, state) => const LogisticsIntegrationPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsOnboardingRoute,
        builder: (context, state) => const LogisticsOnboardingPage(),
      ),
      GoRoute(
        path: AppConstants.logisticsSettingsRoute,
        builder: (context, state) => const LogisticsSettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
