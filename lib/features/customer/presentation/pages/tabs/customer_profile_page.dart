import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
        final tokenStorage = GetIt.instance<TokenStorage>();
    final isGuest = !tokenStorage.isAuthenticated && tokenStorage.isGuest;

    if (isGuest) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 64, color: cs.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Welcome, Guest',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text('Sign in to unlock the full experience',
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppConstants.signInRoute),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.go(AppConstants.registerRoute),
                    child: const Text('Create Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final state = context.watch<HomeCubit>().state;
    final user = state is HomeLoaded ? state.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('My Xerin')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Avatar + name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(user?.fullName ?? 'User'),
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          _tile(context, Icons.person_outline, 'Personal Information',
              AppConstants.profileInfoRoute, cs),
          _tile(context, Icons.location_on_outlined, 'Addresses',
              AppConstants.addressesRoute, cs),
          _tile(context, Icons.credit_card_outlined, 'Payment Methods',
              AppConstants.paymentMethodsRoute, cs),
          _tile(context, Icons.receipt_long_outlined, 'My Orders',
              AppConstants.orderHistoryRoute, cs),
          _tile(context, Icons.local_offer_outlined, 'Coupons & Offers',
              AppConstants.promotionsRoute, cs),
          _tile(context, Icons.help_outline, 'Help Center',
              AppConstants.helpSupportRoute, cs),
          _tile(context, Icons.privacy_tip_outlined, 'Privacy & Terms',
              AppConstants.termsRoute, cs),
          _tile(context, Icons.settings_outlined, 'Settings',
              AppConstants.settingsRoute, cs),
          const Divider(),
          _tile(context, Icons.logout, 'Logout', null, cs, isLogout: true),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'XerinMarket v1.0.0',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.25)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      String? route, ColorScheme cs,
      {bool isLogout = false}) {
    final color = isLogout ? const Color(0xFFE53935) : cs.onSurface;
    return ListTile(
      leading: Icon(icon, color: color.withValues(alpha: 0.7), size: 22),
      title: Text(
        label,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color),
      ),
      trailing: Icon(Icons.chevron_right,
          size: 20, color: cs.onSurface.withValues(alpha: 0.2)),
      onTap: () {
        if (isLogout) {
          _showLogoutDialog(context);
        } else if (route != null) {
          context.push(route);
        }
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                context.go(AppConstants.signInRoute);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
