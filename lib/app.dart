import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/constants/app_constants.dart';
import 'config/di/service_locator.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/customer/presentation/cubit/cart_cubit.dart';
import 'features/customer/presentation/cubit/customer_cubit.dart';
import 'features/customer/presentation/cubit/home_cubit.dart';
import 'features/customer/presentation/cubit/notification_cubit.dart';
import 'features/customer/presentation/cubit/promotion_cubit.dart';
import 'features/customer/presentation/cubit/recommendation_cubit.dart';
import 'features/customer/presentation/cubit/search_cubit.dart';
import 'features/customer/presentation/cubit/wishlist_cubit.dart';
import 'features/seller/presentation/cubit/seller_cubit.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';

/// Root app widget.
class XerinApp extends StatefulWidget {
  const XerinApp({super.key});

  @override
  State<XerinApp> createState() => _XerinAppState();
}

class _XerinAppState extends State<XerinApp> {
  @override
  void initState() {
    super.initState();
    sl<ApiClient>().setSessionExpiredCallback(() {
      AppRouter.router.go(AppConstants.signInRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AppThemeCubit>()),
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<HomeCubit>()..loadHome()),
        BlocProvider(create: (_) => sl<CustomerCubit>()..loadAll()),
        BlocProvider.value(value: sl<CartCubit>()),
        BlocProvider.value(value: sl<RecommendationCubit>()),
        BlocProvider(create: (_) => sl<WishlistCubit>()),
        BlocProvider(create: (_) => sl<NotificationCubit>()),
        BlocProvider(create: (_) => sl<PromotionCubit>()),
        BlocProvider(create: (_) => sl<SearchCubit>()),
        BlocProvider(create: (_) => sl<SellerCubit>()),
        BlocProvider(create: (_) => sl<AdminCubit>()),
      ],
      child: BlocBuilder<AppThemeCubit, AppThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: 'XerinMarket',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
