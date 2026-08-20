import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/modern_bottom_nav.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../config/constants/app_constants.dart';
import '../cubit/seller_cubit.dart';
import '../cubit/seller_state.dart';
import 'tabs/seller_analytics_page.dart';
import 'tabs/seller_dashboard_page.dart';
import 'tabs/seller_orders_page.dart';
import 'tabs/seller_products_page.dart';
import 'tabs/seller_profile_page.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _kycRedirected = false;
  bool _productsLoaded = false;
  bool _ordersLoaded = false;
  bool _profileLoaded = false;

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
    final cubit = context.read<SellerCubit>();
    if (index == 1 && !_productsLoaded) {
      _productsLoaded = true;
      cubit.loadProductsTab();
    } else if (index == 2 && !_ordersLoaded) {
      _ordersLoaded = true;
      cubit.loadOrdersTab();
    } else if (index == 4 && !_profileLoaded) {
      _profileLoaded = true;
      cubit.loadProfileAndStore();
    }
  }

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Products'),
    NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Orders'),
    NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Analytics'),
    NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().loadDashboard();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut) {
          context.go(AppConstants.signInRoute);
        }
      },
      child: BlocBuilder<SellerCubit, SellerState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (previous is SellerDashboardLoaded && current is SellerDashboardLoaded) {
            final prevKyc = previous.kycStatus?.sellerStatus ??
                previous.profile?.status ?? 'pending';
            final currKyc = current.kycStatus?.sellerStatus ??
                current.profile?.status ?? 'pending';
            return prevKyc != currKyc;
          }
          return false;
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is SellerError) {
            final isSessionExpired = state.message.contains('session has expired');
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSessionExpired ? Icons.lock_outline : Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSessionExpired)
                        ElevatedButton(
                          onPressed: () {
                            context.read<AuthCubit>().logout();
                            context.go(AppConstants.signInRoute);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Sign In Again'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => context.read<SellerCubit>().loadDashboard(),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is SellerDashboardLoaded) {
            final kycStatus = state.kycStatus?.sellerStatus ??
                state.profile?.status ??
                'pending';
            if (kycStatus != 'approved' && kycStatus != 'under_review') {
              if (!_kycRedirected) {
                _kycRedirected = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go(AppConstants.sellerKycRoute);
                });
              }
              return Scaffold(
                backgroundColor: colorScheme.surface,
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  SellerDashboardPage(
                    onNavigate: (index) => _switchTab(index),
                  ),
                  SellerProductsPage(),
                  SellerOrdersPage(),
                  SellerAnalyticsPage(),
                  SellerProfilePage(),
                ],
              ),
              bottomNavigationBar: ModernBottomNav(
                selectedIndex: _selectedIndex,
                onTap: (index) => _switchTab(index),
                items: _navItems,
              ),
            );
          }

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
