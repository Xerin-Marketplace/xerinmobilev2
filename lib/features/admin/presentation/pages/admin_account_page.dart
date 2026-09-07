import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/uicons.dart';

class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = GetIt.instance<TokenStorage>().currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Profile section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                  child: Text(
                    (user != null && user.fullName.isNotEmpty ? user.fullName : user?.email ?? 'A')[0].toUpperCase(),
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Admin User',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.accountType.toUpperCase() ?? 'ADMIN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // Account details
          Card(
            child: Column(children: [
              _detailRow(cs, 'User ID', user?.id ?? '—'),
              const Divider(height: 1),
              _detailRow(cs, 'Phone', user?.phone ?? '—'),
              const Divider(height: 1),
              _detailRow(cs, 'Role', user?.accountType ?? 'admin'),
              const Divider(height: 1),
              _detailRow(cs, 'Status', user?.status ?? 'active'),
              const Divider(height: 1),
              _detailRow(cs, 'Verified', user?.isVerified == true ? 'Yes' : 'No'),
              const Divider(height: 1),
              _detailRow(cs, 'Is Seller', user?.isSeller == true ? 'Yes' : 'No'),
              const Divider(height: 1),
              _detailRow(cs, 'Is Broker', user?.isBroker == true ? 'Yes' : 'No'),
            ]),
          ),
          const SizedBox(height: 16),
          // Permissions summary
          if (user != null && user.permissions.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Permissions (${user.permissions.length})',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: user.permissions.take(10).map((p) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(p, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.primary)),
                    )).toList(),
                  ),
                  if (user.permissions.length > 10) ...[
                    const SizedBox(height: 4),
                    Text('+${user.permissions.length - 10} more',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Roles
          if (user != null && user.roles.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Roles',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: user.roles.map((r) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(r, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                    )).toList(),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Quick links
          Card(
            child: Column(children: [
              _linkTile(cs, context, 'Roles & Permissions', '/admin-roles'),
              const Divider(height: 1),
              _linkTile(cs, context, 'Activity Logs', '/admin-activity-logs'),
              const Divider(height: 1),
              _linkTile(cs, context, 'Alerts', '/admin-alerts'),
              const Divider(height: 1),
              _linkTile(cs, context, 'System Management', '/admin-system-management'),
              const Divider(height: 1),
              _linkTile(cs, context, 'Marketplace Settings', '/admin-marketplace-settings'),
            ]),
          ),
          const SizedBox(height: 16),
          // Security
          Card(
            child: Column(children: [
              _linkTile(cs, context, 'Change Password', '/settings'),
              const Divider(height: 1),
              _linkTile(cs, context, 'Notification Preferences', '/settings'),
            ]),
          ),
          const SizedBox(height: 24),
          // Logout
          FilledButton(
            onPressed: () async {
              await GetIt.instance<TokenStorage>().clearTokens();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _linkTile(ColorScheme cs, BuildContext context, String title, String route) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface)),
      trailing: Icon(Uicons.angleRight, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
      onTap: () => context.push(route),
    );
  }
}
