import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/theme/app_theme_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              final user = homeState is HomeLoaded ? homeState.user : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BackIconButton(
                        onTap: () => context.pop(),
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Text('Settings',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCard(context, colorScheme, user),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Appearance', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    colorScheme,
                    child: BlocBuilder<AppThemeCubit, AppThemeState>(
                      builder: (context, themeState) {
                        final isDark = themeState.themeMode == ThemeMode.dark ||
                            (themeState.themeMode == ThemeMode.system &&
                                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                        return _buildTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Dark Mode',
                          subtitle: isDark ? 'Enabled' : 'Disabled',
                          trailing: Switch(
                            value: isDark,
                            onChanged: (_) => context.read<AppThemeCubit>().toggleTheme(),
                            activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                            activeThumbColor: colorScheme.primary,
                          ),
                          colorScheme: colorScheme,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Notifications', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    colorScheme,
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.shopping_bag_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Order Updates',
                          subtitle: 'Get notified about order status',
                          trailing: Switch(value: true, onChanged: (v) {}, activeTrackColor: colorScheme.primary.withValues(alpha: 0.5), activeThumbColor: colorScheme.primary),
                          colorScheme: colorScheme,
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.local_offer_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Promotions & Deals',
                          subtitle: 'Receive offers and discounts',
                          trailing: Switch(value: true, onChanged: (v) {}, activeTrackColor: colorScheme.primary.withValues(alpha: 0.5), activeThumbColor: colorScheme.primary),
                          colorScheme: colorScheme,
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.payment_rounded,
                          iconColor: const Color(0xFF22C55E),
                          title: 'Payment Notifications',
                          subtitle: 'Transaction alerts',
                          trailing: Switch(value: false, onChanged: (v) {}, activeTrackColor: colorScheme.primary.withValues(alpha: 0.5), activeThumbColor: colorScheme.primary),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Account', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    colorScheme,
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Personal Information',
                          subtitle: 'View and edit your profile',
                          trailing: TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          colorScheme: colorScheme,
                          onTap: () => context.push(AppConstants.profileInfoRoute),
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          title: 'Language',
                          subtitle: 'English',
                          trailing: TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          colorScheme: colorScheme,
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.monetization_on_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Currency',
                          subtitle: 'TZS - Tanzanian Shilling',
                          trailing: TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionTitle('About', colorScheme),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    colorScheme,
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: colorScheme.primary,
                          title: 'App Version',
                          subtitle: '1.0.0',
                          colorScheme: colorScheme,
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.description_outlined,
                          iconColor: colorScheme.primary,
                          title: 'Terms of Service',
                          trailing: TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          colorScheme: colorScheme,
                        ),
                        _buildDivider(colorScheme),
                        _buildTile(
                          icon: Icons.shield_outlined,
                          iconColor: colorScheme.primary,
                          title: 'Privacy Policy',
                          trailing: TrailingChevron(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ColorScheme colorScheme, UserModel? user) {
    final displayName = user?.fullName ?? 'Guest';
    final displayEmail = user?.email ?? '';
    final initials = displayName.isNotEmpty ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push(AppConstants.profileInfoRoute),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(initials,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(displayEmail,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text('View Profile',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
            TrailingChevron(color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildSettingCard(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconContainer(
              icon: icon,
              color: iconColor,
              size: 40,
              iconSize: AppIconSize.md,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.06), indent: 70);
  }
}
