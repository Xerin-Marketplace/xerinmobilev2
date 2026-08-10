import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/customer_cubit.dart';
import '../../cubit/customer_state.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuItems = [
      {'icon': Icons.person_outline_rounded, 'label': 'Personal info'},
      {'icon': Icons.location_on_outlined, 'label': 'Addresses'},
      {'icon': Icons.payment_rounded, 'label': 'Payment Methods'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Order History'},
      {'icon': Icons.local_offer_outlined, 'label': 'Promotions & Deals'},
      {'icon': Icons.notifications_outlined, 'label': 'Notifications'},
      {'icon': Icons.tune_outlined, 'label': 'Notification Preferences'},
      {'icon': Icons.search_rounded, 'label': 'Search Products'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
      {'icon': Icons.help_outline_rounded, 'label': 'Help & Support'},
      {'icon': Icons.logout_rounded, 'label': 'Logout', 'color': const Color(0xFFE53935)},
    ];

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Powa avatar with two gradient rings
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.8),
                        colorScheme.primary.withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : colorScheme.primary.withValues(alpha: 0.08),
                    backgroundImage: const AssetImage('assets/images/avatar.png'),
                    child: initials.isNotEmpty
                        ? Text(initials,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : colorScheme.primary,
                            ))
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (displayEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                displayEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // KPI row from CustomerCubit
            BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, cState) {
                final totalOrders = cState is CustomerLoaded ? cState.totalOrders : 0;
                final totalSpent = cState is CustomerLoaded ? cState.totalSpent : 0.0;
                final unreadNotifs = cState is CustomerLoaded ? cState.unreadNotifications : 0;
                final addresses = cState is CustomerLoaded ? cState.addresses.length : 0;

                return Row(
                  children: [
                    Expanded(child: _buildStatCard('Orders', '$totalOrders', Icons.shopping_bag_rounded, const Color(0xFFF47524), colorScheme)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Spent', _formatCompact(totalSpent), Icons.account_balance_wallet_rounded, const Color(0xFF22C55E), colorScheme)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Alerts', '$unreadNotifs', Icons.notifications_active_rounded, const Color(0xFF3B82F6), colorScheme)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Addresses', '$addresses', Icons.location_on_rounded, const Color(0xFF8B5CF6), colorScheme)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (sl<TokenStorage>().isGuestMode)
              _buildGuestBanner(context, colorScheme),
            if (sl<TokenStorage>().isGuestMode)
              const SizedBox(height: 24),
            // Menu items with gradient icons
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: menuItems.map((item) {
                    final color = item['color'] as Color? ?? colorScheme.onSurface;
                    final isLogout = item['label'] == 'Logout';
                    return InkWell(
                      onTap: () {
                        final label = item['label'] as String;
                        switch (label) {
                          case 'Logout':
                            _showLogoutConfirmation(context);
                            break;
                          case 'Personal Info':
                            context.push(AppConstants.profileInfoRoute);
                            break;
                          case 'Addresses':
                            context.push(AppConstants.addressesRoute);
                            break;
                          case 'Payment Methods':
                            context.push(AppConstants.paymentMethodsRoute);
                            break;
                          case 'Order History':
                            context.push(AppConstants.orderHistoryRoute);
                            break;
                          case 'Notifications':
                            context.push(AppConstants.notificationsRoute);
                            break;
                          case 'Promotions & Deals':
                            context.push(AppConstants.promotionsRoute);
                            break;
                          case 'Notification Preferences':
                            context.push(AppConstants.notificationPreferencesRoute);
                            break;
                          case 'Search Products':
                            context.push(AppConstants.searchRoute);
                            break;
                          case 'Settings':
                            context.push(AppConstants.settingsRoute);
                            break;
                          case 'Help & Support':
                            context.push(AppConstants.helpSupportRoute);
                            break;
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLogout
                                      ? [const Color(0xFFE53935), const Color(0xFFE53935).withValues(alpha: 0.7)]
                                      : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isLogout ? const Color(0xFFE53935) : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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

  String _formatCompact(double amount) {
    if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(1)}B';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: cs.onSurface),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Browsing as Guest',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text('Sign in to access your orders, wishlist, and saved addresses.',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppConstants.signInRoute),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
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
                Icons.logout_rounded,
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
