import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/theme/app_theme_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            final user = homeState is HomeLoaded ? homeState.user : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProfileRow(context, colorScheme, user),
                const SizedBox(height: 28),
                  _buildSectionLabel('Appearance', colorScheme),
                  const SizedBox(height: 12),
                  BlocBuilder<AppThemeCubit, AppThemeState>(
                    builder: (context, themeState) {
                      final isDark = themeState.themeMode == ThemeMode.dark ||
                          (themeState.themeMode == ThemeMode.system &&
                              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                      return _buildSwitchRow(
                        title: 'Dark Mode',
                        subtitle: isDark ? 'Enabled' : 'Disabled',
                        value: isDark,
                        onChanged: (_) => context.read<AppThemeCubit>().toggleTheme(),
                        cs: colorScheme,
                      );
                    },
                  ),
                  _buildDivider(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Notifications', colorScheme),
                  const SizedBox(height: 12),
                  const _NotificationSection(),
                  const SizedBox(height: 24),
                  _buildSectionLabel('Security', colorScheme),
                  const SizedBox(height: 12),
                  _SecuritySection(colorScheme: colorScheme),
                  _buildDivider(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionLabel('About', colorScheme),
                  const SizedBox(height: 12),
                  _buildSimpleTile('App Version', AppConstants.appVersion, colorScheme),
                  _buildDivider(colorScheme),
                  _buildSimpleTile('Terms of Service', null, colorScheme, onTap: () => context.push(AppConstants.termsRoute)),
                  _buildDivider(colorScheme),
                  _buildSimpleTile('Privacy Policy', null, colorScheme, onTap: () => context.push(AppConstants.privacyRoute)),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
    );
  }

  Widget _buildProfileRow(BuildContext context, ColorScheme cs, UserModel? user) {
    final displayName = user?.fullName ?? 'Guest';
    final displayEmail = user?.email ?? '';
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => context.push(AppConstants.profileInfoRoute),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withValues(alpha: 0.08),
            child: Text(initials, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                if (displayEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(displayEmail, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: cs.onSurface.withValues(alpha: 0.25)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)));
  }

  Widget _buildSimpleTile(String title, String? subtitle, ColorScheme cs, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06));
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
        _buildNotifRow('Order Updates', 'Get notified about order status', _orderUpdates, (v) {
          setState(() => _orderUpdates = v);
          _toggle('notif_order_updates', v);
        }, cs),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        _buildNotifRow('Promotions & Deals', 'Receive offers and discounts', _promotions, (v) {
          setState(() => _promotions = v);
          _toggle('notif_promotions', v);
        }, cs),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        _buildNotifRow('Payment Notifications', 'Transaction alerts', _payments, (v) {
          setState(() => _payments = v);
          _toggle('notif_payments', v);
        }, cs),
      ],
    );
  }

  Widget _buildNotifRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Lock PIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
          ),
        ],
      ),
    );
  }

  void _showDisablePinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}
