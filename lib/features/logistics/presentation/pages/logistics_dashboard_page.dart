import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_theme_cubit.dart';
import '../../../../core/theme/uicons.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../common/presentation/widgets/modern_bottom_nav.dart';
import '../cubit/logistics_cubit.dart';
import '../cubit/logistics_state.dart';
import 'tabs/logistics_home_tab.dart';
import 'tabs/logistics_shipments_tab.dart';
import 'tabs/logistics_more_tab.dart';

class LogisticsDashboardPage extends StatefulWidget {
  const LogisticsDashboardPage({super.key});

  @override
  State<LogisticsDashboardPage> createState() =>
      _LogisticsDashboardPageState();
}

class _LogisticsDashboardPageState extends State<LogisticsDashboardPage> {
  int _selectedIndex = 0;
  late final LogisticsCubit _cubit;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<LogisticsCubit>();
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
        _cubit.loadDashboard();
        break;
      case 1:
        _cubit.loadShipments();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      const NavItem(icon: Uicons.home, activeIcon: Uicons.home, label: 'Home'),
      const NavItem(icon: Uicons.truckBox, activeIcon: Uicons.truckBox, label: 'Shipments'),
      const NavItem(icon: Uicons.grid, activeIcon: Uicons.grid, label: 'More'),
    ];

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<LogisticsCubit, LogisticsState>(
        listener: (context, state) {
          if (state is LogisticsError) {
            NotificationService().error(state.message);
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAccountSheet(context, cs),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Uicons.truckBox,
                color: cs.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  user?.fullName ?? 'Logistics Partner',
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

  Widget _buildTabContent(BuildContext context, LogisticsState state) {
    switch (_selectedIndex) {
      case 0:
        if (state is LogisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is LogisticsError) {
          return _errorView(context, state.message);
        }
        if (state is LogisticsDashboardLoaded) {
          return LogisticsHomeTab(dashboardState: state);
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
        return const LogisticsShipmentsTab();
      case 2:
        return const LogisticsMoreTab();
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

  void _showAccountSheet(BuildContext context, ColorScheme cs) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final name = user?.fullName ?? 'Logistics Partner';
    final email = user?.email ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : '?';

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
                  radius: 32,
                  backgroundColor: cs.surface,
                  child: Text(initials,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(name,
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
            Text('Are you sure you want to log out of your logistics account?',
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
