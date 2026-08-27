import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/security/admin_access.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../../core/theme/uicons.dart';

class AdminMoreTab extends StatelessWidget {
  const AdminMoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = GetIt.instance<TokenStorage>().currentUser;

    final sections = <_AdminSection>[
      _AdminSection('Alerts', Uicons.bell, const Color(0xFFE91E63), AppConstants.adminAlertsRoute, 'Alerts'),
      _AdminSection('Activity Logs', Uicons.clock, const Color(0xFF607D8B), AppConstants.adminActivityLogsRoute, 'ActivityLogs'),
      _AdminSection('Roles', Uicons.userShield, const Color(0xFF795548), AppConstants.adminRolesRoute, 'Roles'),
      _AdminSection('Finance', Uicons.accountBalance, const Color(0xFF4CAF50), AppConstants.adminFinanceRoute, 'Finance'),
      _AdminSection('Analytics', Uicons.barChart, const Color(0xFF3F51B5), AppConstants.adminAnalyticsRoute, 'Analytics'),
      _AdminSection('Catalog', Uicons.category, const Color(0xFF00BCD4), AppConstants.adminCatalogRoute, 'Catalog'),
      _AdminSection('Payments', Uicons.creditCard, const Color(0xFFCDDC39), AppConstants.adminPaymentsRoute, 'Payments'),
      _AdminSection('All Orders', Uicons.truckBox, const Color(0xFF03A9F4), AppConstants.adminAllOrdersRoute, 'Orders'),
      _AdminSection('Refunds', Uicons.rotateLeft, const Color(0xFFE53935), AppConstants.adminRefundsRoute, 'Refunds'),
      _AdminSection('Reviews', Uicons.star, const Color(0xFFFFC107), AppConstants.adminReviewsRoute, 'Reviews'),
      _AdminSection('Advertisements', Uicons.tags, const Color(0xFF8BC34A), AppConstants.adminAdvertisementsRoute, 'Advertisements'),
      _AdminSection('Marketplace', Uicons.settings, const Color(0xFF009688), AppConstants.adminMarketplaceSettingsRoute, 'MarketplaceSettings'),
    ];

    final visibleSections = sections
        .where((s) => AdminAccess.canAccessSection(user, s.accessKey))
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        const SizedBox(height: 8),
        Text(
          'All Features',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${visibleSections.length} sections available',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: visibleSections
              .map((s) => _sectionCard(context, colorScheme, isDark, s))
              .toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionCard(BuildContext context, ColorScheme cs, bool isDark, _AdminSection s) {
    return GestureDetector(
      onTap: () => context.push(s.route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(s.icon, size: 20, color: s.color),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Uicons.angleRight,
                  size: 14,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSection {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  final String accessKey;

  const _AdminSection(this.title, this.icon, this.color, this.route, this.accessKey);
}
