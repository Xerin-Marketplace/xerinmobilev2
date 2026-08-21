import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/storage/token_storage.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/legal_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
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
import '../../features/customer/presentation/pages/trending_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static const _publicRoutes = [
    '/splash',
    '/onboarding',
    '/sign-in',
    '/register',
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
      final isAuthenticated = GetIt.instance<TokenStorage>().isAuthenticated;

      if (!isPublic && !isAuthenticated) {
        return AppConstants.signInRoute;
      }
      if (isPublic && isAuthenticated && path != '/splash' && path != '/onboarding') {
        return AppConstants.homeRoute;
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
