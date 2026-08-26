import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/uicons.dart';

class LogisticsSettingsPage extends StatefulWidget {
  const LogisticsSettingsPage({super.key});

  @override
  State<LogisticsSettingsPage> createState() => _LogisticsSettingsPageState();
}

class _LogisticsSettingsPageState extends State<LogisticsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle(cs, 'Company'),
            const SizedBox(height: 8),
            _navCard(cs, 'Company Profile', Uicons.storeAlt, () {}),
            _navCard(cs, 'Documents', Uicons.clipboard, () {}),
            const SizedBox(height: 24),
            _sectionTitle(cs, 'Operations'),
            const SizedBox(height: 8),
            _navCard(cs, 'Services & Pricing',
                Uicons.money, () => context.go('/logistics-pricing')),
            _navCard(cs, 'Zones', Uicons.map, () {}),
            _navCard(cs, 'Team Members',
                Uicons.users, () => context.go('/logistics-team')),
            const SizedBox(height: 24),
            _sectionTitle(cs, 'Developer'),
            const SizedBox(height: 8),
            _navCard(cs, 'API Integration',
                Uicons.bolt, () => context.go('/logistics-integration')),
            _navCard(cs, 'Webhook Events', Uicons.bolt, () {}),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _navCard(
      ColorScheme cs, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 20, color: cs.primary),
        title: Text(title,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        trailing: Icon(Uicons.angleRight,
            size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
        onTap: onTap,
      ),
    );
  }
}
