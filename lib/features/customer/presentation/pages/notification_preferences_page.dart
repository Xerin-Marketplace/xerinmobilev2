import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/notification_cubit.dart';
import '../../data/models/notification_model.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends State<NotificationPreferencesPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationPrefsLoaded) {
            final prefs = state.preferences;
            return ListView(
              children: [
                _SwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: prefs.pushEnabled,
                  onChanged: (v) => _update(context, prefs.copyWith(pushEnabled: v)),
                ),
                _SwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: prefs.emailEnabled,
                  onChanged: (v) => _update(context, prefs.copyWith(emailEnabled: v)),
                ),
                _SwitchTile(
                  title: 'SMS Notifications',
                  subtitle: 'Receive notifications via SMS',
                  value: prefs.smsEnabled,
                  onChanged: (v) => _update(context, prefs.copyWith(smsEnabled: v)),
                ),
                const Divider(),
                _SwitchTile(
                  title: 'Order Updates',
                  subtitle: 'Notifications about your order status',
                  value: prefs.orderUpdates,
                  onChanged: (v) => _update(context, prefs.copyWith(orderUpdates: v)),
                ),
                _SwitchTile(
                  title: 'Promotion Alerts',
                  subtitle: 'Deals, discounts, and promotional offers',
                  value: prefs.promotionAlerts,
                  onChanged: (v) => _update(context, prefs.copyWith(promotionAlerts: v)),
                ),
                _SwitchTile(
                  title: 'Security Alerts',
                  subtitle: 'Important security-related notifications',
                  value: prefs.securityAlerts,
                  onChanged: (v) => _update(context, prefs.copyWith(securityAlerts: v)),
                ),
              ],
            );
          }
          if (state is NotificationError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  void _update(BuildContext context, NotificationPreferenceModel prefs) {
    context.read<NotificationCubit>().updatePreferences(prefs);
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
