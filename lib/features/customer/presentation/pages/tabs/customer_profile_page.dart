import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../common/presentation/widgets/kpi_widgets.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../cubit/customer_cubit.dart';
import '../../cubit/customer_state.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../../../shared/widgets/currency_picker_tile.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuGroups = [
      {
        'title': 'Account',
        'items': [
          {'icon': Uicons.user, 'label': 'Personal Info', 'route': AppConstants.profileInfoRoute},
          {'icon': Uicons.mapPin, 'label': 'Addresses', 'route': AppConstants.addressesRoute},
          {'icon': Uicons.creditCard, 'label': 'Payment Methods', 'route': AppConstants.paymentMethodsRoute},
          {'icon': Uicons.lock, 'label': 'Security', 'route': AppConstants.customerSecurityRoute},
        ],
      },
      {
        'title': 'Shopping',
        'items': [
          {'icon': Uicons.shoppingBag, 'label': 'Order History', 'route': AppConstants.orderHistoryRoute},
          {'icon': Uicons.star, 'label': 'My Reviews', 'route': AppConstants.customerReviewsRoute},
          {'icon': Uicons.hashtag, 'label': 'Promotions & Deals', 'route': AppConstants.promotionsRoute},
        ],
      },
      {
        'title': 'Preferences',
        'items': [
          {'icon': Uicons.settingsSliders, 'label': 'Notification Preferences', 'route': AppConstants.notificationPreferencesRoute},
          {'icon': Uicons.settings, 'label': 'Settings', 'route': AppConstants.settingsRoute},
          {'icon': Uicons.circleQuestion, 'label': 'Help & Support', 'route': AppConstants.helpSupportRoute},
        ],
      },
    ];

    final tokenStorage = GetIt.instance<TokenStorage>();
    final isGuest = !tokenStorage.isAuthenticated && tokenStorage.isGuest;

    if (isGuest) {
      return _buildGuestProfile(context, colorScheme, isDark);
    }

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final user = homeState is HomeLoaded ? homeState.user : null;
        final displayName = user?.fullName ?? 'Guest';
        final displayEmail = user?.email ?? '';
        final initials = displayName.isNotEmpty
            ? displayName.split(' ').take(2).map((e) => e[0].toUpperCase()).join()
            : '?';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            // Banner with avatar overlay
            _buildBannerWithAvatar(displayName, displayEmail, initials, user, colorScheme, isDark),
            const SizedBox(height: 24),
            // KPI cards in two-column grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<CustomerCubit, CustomerState>(
                builder: (context, cState) {
                  final totalOrders = cState is CustomerLoaded ? cState.totalOrders : 0;
                  final totalSpent = cState is CustomerLoaded ? cState.totalSpent : 0.0;
                  final unreadNotifs = cState is CustomerLoaded ? cState.unreadNotifications : 0;
                  final addresses = cState is CustomerLoaded ? cState.addresses.length : 0;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    WhiteKpiCard(
                      label: 'Orders',
                      value: '$totalOrders',
                      icon: Uicons.shoppingBag,
                      color: const Color(0xFFF47524),
                    ),
                    WhiteKpiCard(
                      label: 'Total Spent',
                      value: _formatCompact(totalSpent),
                      icon: Uicons.accountBalanceWallet,
                      color: const Color(0xFF22C55E),
                    ),
                    WhiteKpiCard(
                      label: 'Alerts',
                      value: '$unreadNotifs',
                      icon: Uicons.bellRing,
                      color: const Color(0xFF3B82F6),
                    ),
                    WhiteKpiCard(
                      label: 'Addresses',
                      value: '$addresses',
                      icon: Uicons.mapPin,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                );
              },
              ),
            ),
            const SizedBox(height: 24),
            // Currency picker
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CurrencyPickerTile(),
            ),
            const SizedBox(height: 24),
            // Menu groups
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: menuGroups.map((group) => _buildMenuGroup(
                  context, group, colorScheme, isDark,
                )).toList(),
              ),
            ),
            // Logout
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.15)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: _buildLogoutTile(context, colorScheme, isDark),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildBannerWithAvatar(String displayName, String displayEmail, String initials, UserModel? user, ColorScheme cs, bool isDark) {
    final isVerified = user?.isVerified == true;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isVerified ? Uicons.badgeCheck : Uicons.clock, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(isVerified ? 'Verified' : 'Pending',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 110,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? const Color(0xFF2A2A2A) : cs.primary.withValues(alpha: 0.08),
                  backgroundImage: const AssetImage('assets/images/avatar.png'),
                  child: initials.isNotEmpty
                      ? Text(initials,
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: isDark ? Colors.white : cs.primary))
                      : null,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 218,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(displayName,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                if (displayEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(displayEmail,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGroup(BuildContext context, Map<String, dynamic> group, ColorScheme cs, bool isDark) {
    final items = group['items'] as List<dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(group['title'] as String,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(items.length, (index) {
                  final item = items[index] as Map<String, dynamic>;
                  return Column(
                    children: [
                      _buildMenuTile(context, item, cs),
                      if (index < items.length - 1) _buildDivider(cs),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, Map<String, dynamic> item, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.push(item['route'] as String),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: colorScheme.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Uicons.arrowForwardIos,
              size: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return InkWell(
      onTap: () => _showLogoutConfirmation(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Uicons.rightFromBracket,
                color: Color(0xFFE53935),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),
            Icon(
              Uicons.arrowForwardIos,
              size: 14,
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context, ColorScheme cs, bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Uicons.user, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 20),
            Text('Welcome, Guest',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text('Sign in to unlock the full experience',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppConstants.signInRoute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go(AppConstants.registerRoute),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: cs.primary,
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CurrencyPickerTile(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: colorScheme.onSurface.withValues(alpha: 0.06),
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(1)}B';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  void _showLogoutConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Uicons.rightFromBracket,
                color: Color(0xFFE53935),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Logout?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of your account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
