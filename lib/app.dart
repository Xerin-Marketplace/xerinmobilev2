import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/di/service_locator.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/theme/app_theme_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/customer/presentation/cubit/home_cubit.dart';
import 'features/seller/presentation/cubit/seller_cubit.dart';

/// Root app widget.
class XerinApp extends StatelessWidget {
  const XerinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AppThemeCubit>()),
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<HomeCubit>()..loadHome()),
        BlocProvider(create: (_) => sl<SellerCubit>()..loadDashboard()),
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
