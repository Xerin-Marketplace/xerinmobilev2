import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/theme/app_theme_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../../core/theme/uicons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              final user = homeState is HomeLoaded ? homeState.user : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, colorScheme),
                  const SizedBox(height: 20),
                  _buildProfileCard(context, colorScheme, user),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Appearance', colorScheme),
                  const SizedBox(height: 12),
                  _buildCard(context, colorScheme, child: BlocBuilder<AppThemeCubit, AppThemeState>(
                    builder: (context, themeState) {
                      final isDark = themeState.themeMode == ThemeMode.dark ||
                          (themeState.themeMode == ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                      return _buildSwitchTile(
                        icon: Uicons.darkMode,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Dark Mode',
                        subtitle: isDark ? 'Enabled' : 'Disabled',
                        value: isDark,
                        onChanged: (_) => context.read<AppThemeCubit>().toggleTheme(),
                        cs: colorScheme,
                      );
                    },
                  )),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Notifications', colorScheme),
                  const SizedBox(height: 12),
                  _buildCard(context, colorScheme, child: const _NotificationSection()),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Security', colorScheme),
                  const SizedBox(height: 12),
                  _buildCard(context, colorScheme, child: _SecuritySection(colorScheme: colorScheme)),
                  const SizedBox(height: 24),
                  _buildSectionLabel('About', colorScheme),
                  const SizedBox(height: 12),
                  _buildCard(context, colorScheme, child: Column(
                    children: [
                      _buildTile(
                        icon: Uicons.circleInfo,
                        iconColor: colorScheme.primary,
                        title: 'App Version',
                        subtitle: AppConstants.appVersion,
                        cs: colorScheme,
                      ),
                      _buildDivider(colorScheme),
                      _buildTile(
                        icon: Uicons.description,
                        iconColor: colorScheme.primary,
                        title: 'Terms of Service',
                        cs: colorScheme,
                        onTap: () => context.push(AppConstants.termsRoute),
                      ),
                      _buildDivider(colorScheme),
                      _buildTile(
                        icon: Uicons.shield,
                        iconColor: colorScheme.primary,
                        title: 'Privacy Policy',
                        cs: colorScheme,
                        onTap: () => context.push(AppConstants.privacyRoute),
                      ),
                    ],
                  )),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Text('Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, ColorScheme cs, UserModel? user) {
    final displayName = user?.fullName ?? 'Guest';
    final displayEmail = user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => context.push(AppConstants.profileInfoRoute),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.4)],
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: cs.surface,
                child: Text(initials,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  if (displayEmail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(displayEmail,
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Uicons.arrowForwardIos, size: 14, color: cs.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
    );
  }

  Widget _buildCard(BuildContext context, ColorScheme cs, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required ColorScheme cs,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Uicons.arrowForwardIos, size: 12, color: cs.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: cs.primary.withValues(alpha: 0.5),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06), indent: 62);
  }
}

class _NotificationSection extends StatefulWidget {
  const _NotificationSection();

  @override
  State<_NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<_NotificationSection> {
  late SharedPreferences _prefs;
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _payments = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _orderUpdates = _prefs.getBool('notif_order_updates') ?? true;
      _promotions = _prefs.getBool('notif_promotions') ?? true;
      _payments = _prefs.getBool('notif_payments') ?? false;
      _loaded = true;
    });
  }

  void _toggle(String key, bool value) {
    _prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      children: [
        _buildNotifTile(Uicons.shoppingBag, const Color(0xFF3B82F6), 'Order Updates',
            'Get notified about order status', _orderUpdates, (v) {
          setState(() => _orderUpdates = v);
          _toggle('notif_order_updates', v);
        }, cs),
        _buildDivider(cs),
        _buildNotifTile(Uicons.hashtag, const Color(0xFFF59E0B), 'Promotions & Deals',
            'Receive offers and discounts', _promotions, (v) {
          setState(() => _promotions = v);
          _toggle('notif_promotions', v);
        }, cs),
        _buildDivider(cs),
        _buildNotifTile(Uicons.creditCard, const Color(0xFF22C55E), 'Payment Notifications',
            'Transaction alerts', _payments, (v) {
          setState(() => _payments = v);
          _toggle('notif_payments', v);
        }, cs),
      ],
    );
  }

  Widget _buildNotifTile(IconData icon, Color color, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: cs.primary.withValues(alpha: 0.5),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06), indent: 62);
  }
}

class _SecuritySection extends StatefulWidget {
  final ColorScheme colorScheme;

  const _SecuritySection({required this.colorScheme});

  @override
  State<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<_SecuritySection> {
  late final SecurityService _security;
  late bool _pinEnabled;

  @override
  void initState() {
    super.initState();
    _security = GetIt.instance<SecurityService>();
    _pinEnabled = _security.isPinLockEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Uicons.lock, color: const Color(0xFFEF4444), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Lock PIN',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  _pinEnabled ? 'Enabled - PIN required on startup' : 'Require a PIN to open the app',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Switch(
            value: _pinEnabled,
            onChanged: (v) {
              if (v) {
                context.push(AppConstants.pinSetupRoute).then((_) {
                  if (mounted) {
                    setState(() => _pinEnabled = _security.isPinLockEnabled);
                  }
                });
              } else {
                _showDisablePinDialog();
              }
            },
            activeTrackColor: cs.primary.withValues(alpha: 0.5),
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  void _showDisablePinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Uicons.lock, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            Text('Disable PIN Lock?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Your app will no longer require a PIN on startup.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: widget.colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: widget.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          FilledButton(
            onPressed: () async {
              await _security.disablePin();
              if (mounted) {
                setState(() => _pinEnabled = false);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}
