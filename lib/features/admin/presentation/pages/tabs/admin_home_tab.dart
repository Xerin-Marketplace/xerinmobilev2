import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/security/admin_access.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../../../core/theme/uicons.dart';
import '../../cubit/admin_cubit.dart';
import '../../../data/models/admin_models.dart';

class AdminHomeTab extends StatelessWidget {
  final AdminDashboardLoaded state;
  final VoidCallback onRefresh;

  const AdminHomeTab({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSummaryGrid(colorScheme, isDark),
          const SizedBox(height: 20),
          _buildOrdersBreakdown(colorScheme, isDark),
          const SizedBox(height: 20),
          _buildSellersProducts(colorScheme, isDark),
          const SizedBox(height: 20),
          _buildAlertsSection(context, colorScheme, isDark),
          const SizedBox(height: 20),
          _buildQuickActions(context, colorScheme, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(ColorScheme cs, bool isDark) {
    final s = state.summary;
    final metrics = [
      _Metric('Total Orders', s.totalOrders.toString(), Uicons.shoppingBag, const Color(0xFF4CAF50)),
      _Metric('GMV', '${s.currency} ${_fmt(s.gmv)}', Uicons.dollar, const Color(0xFF2196F3)),
      _Metric('Users', s.totalUsers.toString(), Uicons.users, const Color(0xFF9C27B0)),
      _Metric('Sellers', s.totalSellers.toString(), Uicons.storeAlt, const Color(0xFFFF9800)),
      _Metric('Products', s.totalProducts.toString(), Uicons.boxOpen, const Color(0xFF009688)),
      _Metric('Discounts', '${s.currency} ${_fmt(s.totalDiscounts)}', Uicons.tags, const Color(0xFFE53935)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: metrics.map((m) => _metricCard(cs, isDark, m)).toList(),
    );
  }

  Widget _metricCard(ColorScheme cs, bool isDark, _Metric m) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(m.icon, size: 16, color: m.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          Text(
            m.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersBreakdown(ColorScheme cs, bool isDark) {
    final orders = state.orders;
    if (orders == null) return const SizedBox.shrink();

    final entries = orders.byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Icon(Uicons.shoppingBag, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Orders by Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _humanize(e.key),
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      '${e.value}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSellersProducts(ColorScheme cs, bool isDark) {
    final sellers = state.sellers;
    final products = state.products;

    return Row(
      children: [
        if (sellers != null)
          Expanded(
            child: _buildMiniCard(
              cs,
              isDark,
              'Sellers',
              Uicons.storeAlt,
              const Color(0xFFFF9800),
              sellers.total,
              sellers.pending,
              'Pending',
            ),
          ),
        if (sellers != null && products != null) const SizedBox(width: 12),
        if (products != null)
          Expanded(
            child: _buildMiniCard(
              cs,
              isDark,
              'Products',
              Uicons.boxOpen,
              const Color(0xFF009688),
              products.total,
              products.pendingReview,
              'Pending Review',
            ),
          ),
      ],
    );
  }

  Widget _buildMiniCard(
    ColorScheme cs,
    bool isDark,
    String title,
    IconData icon,
    Color color,
    int total,
    int pending,
    String pendingLabel,
  ) {
    return Container(
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
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$total',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          if (pending > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pending $pendingLabel',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, ColorScheme cs, bool isDark) {
    if (state.alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Uicons.bell, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'System Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push(AppConstants.adminAlertsRoute),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.alerts.take(4).map((alert) => _alertTile(cs, alert, context)),
        ],
      ),
    );
  }

  Widget _alertTile(ColorScheme cs, AdminSystemAlertModel alert, BuildContext context) {
    final color = alert.severity == 'critical'
        ? const Color(0xFFE53935)
        : alert.severity == 'warning'
            ? const Color(0xFFFF9800)
            : const Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Uicons.circleExclamation, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  alert.alertType,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (alert.isResolved)
            Icon(Uicons.checkCircle, size: 16, color: const Color(0xFF4CAF50))
          else if (AdminAccess.canAccessItem(
              GetIt.instance<TokenStorage>().currentUser,
              'alerts.resolve'))
            GestureDetector(
              onTap: () => context.read<AdminCubit>().resolveAlert(alert.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resolve',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme cs, bool isDark) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final actions = <_QuickAction>[];

    if (AdminAccess.canAccessSection(user, 'Sellers')) {
      actions.add(_QuickAction('Sellers', Uicons.storeAlt, const Color(0xFFFF9800), AppConstants.adminSellersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Products')) {
      actions.add(_QuickAction('Products', Uicons.boxOpen, const Color(0xFF009688), AppConstants.adminProductsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Orders')) {
      actions.add(_QuickAction('Orders', Uicons.shoppingBag, const Color(0xFF4CAF50), AppConstants.adminOrdersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Users')) {
      actions.add(_QuickAction('Users', Uicons.users, const Color(0xFF9C27B0), AppConstants.adminUsersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Wallets')) {
      actions.add(_QuickAction('Wallets', Uicons.wallet, const Color(0xFF2196F3), AppConstants.adminWalletsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Refunds')) {
      actions.add(_QuickAction('Refunds', Uicons.rotateLeft, const Color(0xFFE53935), AppConstants.adminRefundsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Reviews')) {
      actions.add(_QuickAction('Reviews', Uicons.star, const Color(0xFFFFC107), AppConstants.adminReviewsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Analytics')) {
      actions.add(_QuickAction('Analytics', Uicons.barChart, const Color(0xFF3F51B5), AppConstants.adminAnalyticsRoute));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: actions
                .map((a) => _actionTile(cs, a.label, a.icon, a.color, () => context.push(a.route)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(ColorScheme cs, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'paid':
      case 'confirmed':
        return const Color(0xFF2196F3);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFF9C27B0);
      case 'delivered':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF607D8B);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Metric(this.label, this.value, this.icon, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickAction(this.label, this.icon, this.color, this.route);
}
