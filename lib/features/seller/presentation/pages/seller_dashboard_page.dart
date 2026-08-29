import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme_cubit.dart';
import '../../../../core/theme/uicons.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../common/presentation/widgets/modern_bottom_nav.dart';
import '../cubit/seller_cubit.dart';
import 'tabs/seller_home_tab.dart';
import 'tabs/seller_orders_tab.dart';
import 'tabs/seller_products_tab.dart';
import 'tabs/seller_more_tab.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  int _selectedIndex = 0;
  late final SellerCubit _cubit;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SellerCubit>();
    _cubit.loadDashboard();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _refresh() {
    switch (_selectedIndex) {
      case 0:
        _cubit.loadDashboard(refresh: true);
        break;
      case 1:
        _cubit.loadOrders();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      const NavItem(icon: Uicons.home, activeIcon: Uicons.home, label: 'Home'),
      const NavItem(icon: Uicons.box, activeIcon: Uicons.box, label: 'Orders'),
      const NavItem(icon: Uicons.tags, activeIcon: Uicons.tags, label: 'Products'),
      const NavItem(icon: Uicons.grid, activeIcon: Uicons.grid, label: 'More'),
    ];

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(colorScheme, isDark),
                  Expanded(
                    child: _buildTabContent(context, state),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: ModernBottomNav(
              selectedIndex: _selectedIndex,
              onTap: _onNavTap,
              items: navItems,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isDark) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final state = _cubit.state;
    final logoUrl = state is SellerDashboardLoaded ? state.storeLogoUrl : null;
    final businessName = state is SellerDashboardLoaded ? state.seller?.businessName : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAccountSheet(context, cs, isDark),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.primary.withValues(alpha: 0.15), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  imageUrl: logoUrl,
                  width: 46,
                  height: 46,
                  borderRadius: 12,
                  placeholderIcon: Uicons.shop,
                  iconColor: cs.primary,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  businessName ?? 'Seller Panel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.fullName ?? 'Seller',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => sl<AppThemeCubit>().toggleTheme(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isDark ? Uicons.sun : Uicons.darkMode,
                color: cs.onSurface.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _refresh,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Uicons.refresh,
                color: cs.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, SellerState state) {
    switch (_selectedIndex) {
      case 0:
        if (state is SellerLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SellerError) {
          return _errorView(context, state.message);
        }
        if (state is SellerDashboardLoaded) {
          return SellerHomeTab(
            state: state,
            onRefresh: () => _cubit.loadDashboard(refresh: true),
          );
        }
        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cubit.loadDashboard();
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      case 1:
        return const SellerOrdersTab();
      case 2:
        return const SellerProductsTab();
      case 3:
        return const SellerMoreTab();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _errorView(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _cubit.loadDashboard(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAccountSheet(BuildContext context, ColorScheme cs, bool isDark) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final name = user?.fullName ?? 'Seller';
    final email = user?.email ?? '';
    final state = _cubit.state;
    final logoUrl = state is SellerDashboardLoaded ? state.storeLogoUrl : null;
    final businessName = state is SellerDashboardLoaded ? state.seller?.businessName : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.4)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.surface,
                  child: ClipOval(
                    child: AppNetworkImage(
                      imageUrl: logoUrl,
                      width: 72,
                      height: 72,
                      borderRadius: 36,
                      placeholderIcon: Uicons.shop,
                      iconColor: cs.primary,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(businessName ?? name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email,
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
              const SizedBox(height: 20),
              Divider(color: cs.onSurface.withValues(alpha: 0.06), height: 1),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Uicons.rightFromBracket, color: Color(0xFFE53935), size: 18),
                ),
                title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
                ),
                trailing: const Icon(Uicons.angleRight, size: 14, color: Color(0xFFE53935)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLogoutConfirmation(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Uicons.rightFromBracket, color: Color(0xFFE53935), size: 32),
            ),
            const SizedBox(height: 20),
            Text('Logout?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Are you sure you want to log out of your seller account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                context.go(AppConstants.signInRoute);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
