import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/registration_success_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/customer/presentation/pages/addresses_page.dart';
import '../../features/customer/presentation/pages/categories_page.dart';
import '../../features/customer/presentation/pages/category_products_page.dart';
import '../../features/customer/presentation/pages/customer_dashboard.dart';
import '../../features/customer/data/models/product_model.dart';
import '../../features/customer/presentation/pages/explore_products_page.dart';
import '../../features/customer/presentation/pages/help_support_page.dart';
import '../../features/customer/presentation/pages/checkout_page.dart';
import '../../features/customer/presentation/pages/notifications_page.dart';
import '../../features/customer/presentation/pages/order_history_page.dart';
import '../../features/customer/presentation/pages/payment_methods_page.dart';
import '../../features/customer/presentation/pages/product_detail_page.dart';
import '../../features/customer/presentation/pages/profile_info_page.dart';
import '../../features/customer/presentation/pages/settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/seller/presentation/pages/kyc_page.dart';
import '../../features/seller/presentation/pages/payouts_page.dart';
import '../../features/seller/presentation/pages/reports_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard.dart';
import '../../features/seller/presentation/pages/seller_details_page.dart';
import '../../features/seller/presentation/pages/seller_onboarding_page.dart';
import '../../features/seller/presentation/pages/seller_support_page.dart';
import '../../features/seller/presentation/pages/shipping_options_page.dart';
import '../../features/seller/presentation/pages/shop_details_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../constants/app_constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    debugLogDiagnostics: true,
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
          );
        },
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        builder: (context, state) => const ForgotPasswordPage(),
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
        path: AppConstants.sellerDashboardRoute,
        builder: (context, state) => const SellerDashboard(),
      ),
      GoRoute(
        path: AppConstants.sellerOnboardingRoute,
        builder: (context, state) => const SellerOnboardingPage(),
      ),
      GoRoute(
        path: AppConstants.sellerDetailsRoute,
        builder: (context, state) => const SellerDetailsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerShopDetailsRoute,
        builder: (context, state) => const ShopDetailsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerShippingOptionsRoute,
        builder: (context, state) => const ShippingOptionsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerPayoutsRoute,
        builder: (context, state) => const PayoutsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerReportsRoute,
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: AppConstants.sellerSupportRoute,
        builder: (context, state) => const SellerSupportPage(),
      ),
      GoRoute(
        path: AppConstants.sellerKycRoute,
        builder: (context, state) => const KycPage(),
      ),
      GoRoute(
        path: AppConstants.registrationSuccessRoute,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RegistrationSuccessPage(
            isSeller: extra?['isSeller'] as bool? ?? true,
            shopName: extra?['shopName'] as String? ?? 'XerinMart Store',
          );
        },
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
