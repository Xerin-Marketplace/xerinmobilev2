import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuItems = [
      {'icon': Icons.person_outline, 'label': 'Personal info', 'route': AppConstants.profileInfoRoute},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Order History', 'route': AppConstants.orderHistoryRoute},
      {'icon': Icons.location_on_outlined, 'label': 'Addresses', 'route': AppConstants.addressesRoute},
      {'icon': Icons.credit_card_outlined, 'label': 'Payment Methods', 'route': AppConstants.paymentMethodsRoute},
      {'icon': Icons.lock_outline, 'label': 'Security', 'route': AppConstants.customerSecurityRoute},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': AppConstants.settingsRoute},
      {'icon': Icons.help_outline, 'label': 'Help & Support', 'route': AppConstants.helpSupportRoute},
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
            // Simple header
            _buildSimpleHeader(displayName, displayEmail, initials, user, colorScheme, isDark),
            const SizedBox(height: 32),
            // Menu items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(menuItems.length, (index) {
                  return Column(
                    children: [
                      _buildMenuTile(context, menuItems[index], colorScheme),
                      if (index < menuItems.length - 1) _buildDivider(colorScheme),
                    ],
                  );
                }),
              ),
            ),
            // Logout
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildLogoutTile(context, colorScheme, isDark),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildSimpleHeader(String displayName, String displayEmail, String initials, UserModel? user, ColorScheme cs, bool isDark) {
    final isVerified = user?.isVerified == true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: isDark ? const Color(0xFF2A2A2A) : cs.primary.withValues(alpha: 0.08),
            backgroundImage: const AssetImage('assets/images/avatar.png'),
            child: initials.isNotEmpty
                ? Text(initials,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: isDark ? Colors.white : cs.primary))
                : null,
          ),
          const SizedBox(height: 14),
          Text(displayName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          if (displayEmail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(displayEmail,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
          const SizedBox(height: 8),
          Text(isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
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
            Icon(
              item['icon'] as IconData,
              color: colorScheme.primary,
              size: 20,
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
              Icons.chevron_right,
              size: 20,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Color(0xFFE53935),
              size: 22,
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
              Icons.chevron_right,
              size: 18,
              color: const Color(0xFFE53935).withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context, ColorScheme cs, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 40,
              backgroundColor: cs.primary.withValues(alpha: 0.1),
              child: Text('?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            const SizedBox(height: 20),
            Text('Welcome, Guest',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text('Sign in to unlock the full experience',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(AppConstants.signInRoute),
                child: const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
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
            const Spacer(),
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

  void _showLogoutConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.logout,
              color: Color(0xFFE53935),
              size: 32,
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
