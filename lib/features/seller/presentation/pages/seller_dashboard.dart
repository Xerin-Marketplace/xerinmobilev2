import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/widgets/modern_bottom_nav.dart';
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
  bool _kycDismissed = false;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Products'),
    NavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Orders'),
    NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Analytics'),
    NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final List<Widget> _pages = const [
    SellerDashboardPage(),
    SellerProductsPage(),
    SellerOrdersPage(),
    SellerAnalyticsPage(),
    SellerProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().loadDashboard();
      _showKycDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _showKycDialog() {
    if (_kycDismissed) return;
    final cubit = context.read<SellerCubit>();
    final state = cubit.state;
    if (state is SellerDashboardLoaded) {
      final kycStatus = state.kycStatus;
      final sellerStatus = state.profile?.status ?? kycStatus?.sellerStatus ?? 'pending';
      if (sellerStatus == 'approved' || sellerStatus == 'under_review') {
        return;
      }
    }
    _showKycDialogUI();
  }

  void _showKycDialogUI() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFFF59E0B),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Complete Your KYC',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Verify your identity to unlock payouts, add products, and start selling on Xerin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildKycRequirement('TIN Number', Icons.receipt_long_outlined, colorScheme),
                _buildKycRequirement('Bank / Mobile Money', Icons.account_balance_wallet_outlined, colorScheme),
                _buildKycRequirement('Shop Logo', Icons.store_outlined, colorScheme),
                _buildKycRequirement('Business License', Icons.badge_outlined, colorScheme),
                _buildKycRequirement('ID / NIDA Verification', Icons.fingerprint_outlined, colorScheme),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go(AppConstants.sellerKycRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Complete KYC',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    setState(() => _kycDismissed = true);
                  },
                  child: Text(
                    'Remind me later',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKycRequirement(String label, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ModernBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _navItems,
      ),
    );
  }
}
