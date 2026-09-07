import 'dart:math';

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

const _xerinPrimary = Color(0xFF6D28D9);

class AdminHomeTab extends StatelessWidget {
  final AdminDashboardLoaded state;
  final VoidCallback onRefresh;
  final ValueChanged<String> onPeriodChange;

  const AdminHomeTab({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onPeriodChange,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _periodSelector(cs, isDark),
          const SizedBox(height: 16),
          _grossSalesCard(cs, isDark),
          const SizedBox(height: 12),
          _statsGrid(cs, isDark),
          const SizedBox(height: 20),
          _salesChartSection(cs, isDark),
          const SizedBox(height: 20),
          _orderStatusSection(cs, isDark),
          const SizedBox(height: 20),
          _recentOrdersSection(context, cs, isDark),
          const SizedBox(height: 20),
          _topSellersSection(cs, isDark),
          const SizedBox(height: 20),
          _financeSection(cs, isDark),
          const SizedBox(height: 20),
          _alertsSection(context, cs, isDark),
          const SizedBox(height: 20),
          _quickActions(context, cs, isDark),
        ],
      ),
    );
  }

  Widget _periodSelector(ColorScheme cs, bool isDark) {
    final periods = [
      ('7d', '7 days'),
      ('30d', '30 days'),
      ('90d', '90 days'),
    ];

    return Row(children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: periods.map((p) {
              final isSelected = state.period == p.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPeriodChange(p.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _xerinPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _xerinPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Uicons.refresh, color: _xerinPrimary, size: 18),
        ),
      ),
    ]);
  }

  Widget _card(ColorScheme cs, bool isDark, {required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _grossSalesCard(ColorScheme cs, bool isDark) {
    final s = state.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_xerinPrimary, _xerinPrimary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gross sales',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        Text('TSh ${_fmt(s.gmv)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text('${_periodLabel(state.period)} marketplace GMV',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _statsGrid(ColorScheme cs, bool isDark) {
    final s = state.summary;
    final sellers = state.sellers;
    final products = state.products;
    final customers = state.customers;
    final payments = state.payments;

    final stats = <_StatData>[
      _StatData('Orders', s.totalOrders.toString(),
          payments != null ? '${payments.successful} paid' : null,
          Uicons.shoppingBag, const Color(0xFF22C55E)),
      _StatData('Active sellers', sellers != null ? sellers.approved.toString() : s.totalSellers.toString(),
          sellers != null ? '${sellers.pending} awaiting review' : null,
          Uicons.storeAlt, const Color(0xFFF59E0B)),
      _StatData('Brokers', '—', 'Registered Broker accounts',
          Uicons.userShield, _xerinPrimary),
      _StatData('Registered users', customers != null ? customers.total.toString() : s.totalUsers.toString(),
          'Marketplace accounts',
          Uicons.users, const Color(0xFF3B82F6)),
      _StatData('Active products', products != null ? products.approved.toString() : s.totalProducts.toString(),
          products != null ? '${products.pendingReview} awaiting moderation' : null,
          Uicons.boxOpen, const Color(0xFF009688)),
    ];

    return Column(
      children: stats.map((st) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _card(cs, isDark, child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: st.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(st.icon, color: st.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(st.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 2),
            Text(st.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
            if (st.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(st.subtitle!, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ])),
        ])),
      )).toList(),
    );
  }

  Widget _sectionTitle(String title, String subtitle, ColorScheme cs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 2),
      Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
    ]);
  }

  Widget _salesChartSection(ColorScheme cs, bool isDark) {
    final trend = state.salesTrend;
    final overview = state.analyticsOverview;

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Sales overview', 'Marketplace sales trend — Gross seller-item value recorded by the commission ledger.', cs),
      const SizedBox(height: 16),
      if (overview != null) ...[
        Row(children: [
          Expanded(child: _miniStat(cs, 'Average order value', 'TSh ${_fmt(overview.avgOrderValue)}')),
        ]),
        const SizedBox(height: 16),
      ],
      if (trend.isNotEmpty)
        _salesChart(cs, trend)
      else
        Container(
          height: 120,
          alignment: Alignment.center,
          child: Text('No sales data for this period',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
        ),
    ]));
  }

  Widget _miniStat(ColorScheme cs, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4))),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _xerinPrimary)),
    ]);
  }

  Widget _salesChart(ColorScheme cs, List<AdminAnalyticsSalesPointModel> trend) {
    final maxRevenue = trend.isEmpty ? 1.0 : trend.map((e) => e.revenue).reduce(max);
    final safeMax = maxRevenue == 0 ? 1.0 : maxRevenue;

    return SizedBox(
      height: 160,
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: trend.map((point) {
            final barHeight = (point.revenue / safeMax) * 120;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: barHeight.clamp(2.0, 120.0),
                    decoration: BoxDecoration(
                      color: _xerinPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _xerinPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shortDate(point.date),
                    style: TextStyle(fontSize: 8, color: cs.onSurface.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _orderStatusSection(ColorScheme cs, bool isDark) {
    final orders = state.orders;
    if (orders == null) return const SizedBox.shrink();

    final entries = orders.byStatus.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0, (sum, e) => sum + e.value);

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Order status', 'Current order pipeline — Live totals by marketplace order status.', cs),
      const SizedBox(height: 8),
      Row(children: [
        Text('$total', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cs.onSurface)),
        const SizedBox(width: 8),
        Text('Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
      ]),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: entries.map((e) {
          final color = _statusColor(e.key);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(_humanize(e.key), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(width: 6),
              Text('${e.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ]),
          );
        }).toList(),
      ),
    ]));
  }

  Widget _recentOrdersSection(BuildContext context, ColorScheme cs, bool isDark) {
    final orders = state.recentOrders;
    if (orders.isEmpty) return const SizedBox.shrink();

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sectionTitle('Recent orders', 'Latest customer orders across Xerin.', cs),
          TextButton(
            onPressed: () => context.push(AppConstants.adminOrdersRoute),
            child: Text('View all', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _xerinPrimary)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...orders.map((o) => _recentOrderTile(cs, o)),
    ]));
  }

  Widget _recentOrderTile(ColorScheme cs, Map<String, dynamic> order) {
    final orderId = order['order_number']?.toString() ?? order['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? '#${orderId.substring(0, 8)}' : '#$orderId';
    final customerName = order['customer_name']?.toString() ?? order['user_name']?.toString() ?? 'Unknown';
    final amount = order['total']?.toString() ?? order['amount']?.toString() ?? '0';
    final paymentStatus = order['payment_status']?.toString() ?? '';
    final orderStatus = order['status']?.toString() ?? '';
    final createdAt = order['created_at']?.toString() ?? '';
    final itemCount = order['item_count']?.toString() ?? order['items']?.toString() ?? '1';

    final statusColor = _statusColor(orderStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shortId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface)),
            Text('$itemCount item(s)', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
          ]),
        ),
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (createdAt.isNotEmpty)
              Text(_shortDate(createdAt), style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Text('TSh ${_fmtStr(amount)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _xerinPrimary)),
        ),
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (paymentStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _statusColor(paymentStatus).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(paymentStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor(paymentStatus))),
              ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(orderStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor))),
          ]),
        ),
      ]),
    );
  }

  Widget _topSellersSection(ColorScheme cs, bool isDark) {
    final sellers = state.topSellers;
    if (sellers.isEmpty) return const SizedBox.shrink();

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Top sellers', 'Ranked by gross sales.', cs),
      const SizedBox(height: 16),
      ...sellers.asMap().entries.map((entry) {
        final idx = entry.key;
        final seller = entry.value;
        final rank = idx + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: rank == 1
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                    : rank == 2
                        ? const Color(0xFF9CA3AF).withValues(alpha: 0.15)
                        : rank == 3
                            ? const Color(0xFFCD7F32).withValues(alpha: 0.15)
                            : cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('$rank',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                      color: rank == 1 ? const Color(0xFFF59E0B) : rank == 2 ? const Color(0xFF9CA3AF) : rank == 3 ? const Color(0xFFCD7F32) : cs.onSurface.withValues(alpha: 0.4)))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(seller.sellerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${seller.orders} orders · ${seller.products} units', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
            ])),
            Text('TSh ${_fmt(seller.revenue)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _xerinPrimary)),
          ]),
        );
      }),
    ]));
  }

  Widget _financeSection(ColorScheme cs, bool isDark) {
    final s = state.summary;
    final refunds = state.refunds;
    final items = <_FinanceItem>[
      _FinanceItem('Xerin commission', 'TSh ${_fmt(s.totalDiscounts)}', Uicons.dollar, const Color(0xFF22C55E)),
      _FinanceItem('Marketplace revenue', 'TSh ${_fmt(s.gmv * 0.02)}', Uicons.barChart, _xerinPrimary),
      _FinanceItem('Seller net earnings', 'TSh ${_fmt(s.gmv - s.totalDiscounts)}', Uicons.wallet, const Color(0xFF3B82F6)),
      _FinanceItem('Pending seller payouts', 'TSh ${_fmt(refunds?.pending.toDouble() ?? 0)}', Uicons.clock, const Color(0xFFF59E0B)),
      _FinanceItem('Completed refunds', 'TSh ${_fmt(refunds?.total.toDouble() ?? 0)}', Uicons.rotateLeft, const Color(0xFFEF4444)),
    ];

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Finance', 'Marketplace financial summary.', cs),
      const SizedBox(height: 16),
      ...items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)))),
          Text(item.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface)),
        ]),
      )),
      if (refunds != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Uicons.circleInfo, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(width: 8),
            Text('${(refunds.total == 0 ? 0.0 : (refunds.total / (s.totalOrders == 0 ? 1 : s.totalOrders)) * 100).toStringAsFixed(2)}% refund rate',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
          ]),
        ),
      ],
    ]));
  }

  Widget _alertsSection(BuildContext context, ColorScheme cs, bool isDark) {
    if (state.alerts.isEmpty) return const SizedBox.shrink();

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('System Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          TextButton(
            onPressed: () => context.push(AppConstants.adminAlertsRoute),
            child: Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _xerinPrimary)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...state.alerts.take(4).map((alert) => _alertTile(cs, alert, context)),
    ]));
  }

  Widget _alertTile(ColorScheme cs, AdminSystemAlertModel alert, BuildContext context) {
    final color = alert.severity == 'critical'
        ? const Color(0xFFE53935)
        : alert.severity == 'warning'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(Uicons.circleExclamation, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(alert.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
          Text(alert.alertType, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        ])),
        if (alert.isResolved)
          Icon(Uicons.checkCircle, size: 16, color: const Color(0xFF22C55E))
        else if (AdminAccess.canAccessItem(
            GetIt.instance<TokenStorage>().currentUser,
            'alerts.resolve'))
          GestureDetector(
            onTap: () => context.read<AdminCubit>().resolveAlert(alert.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _xerinPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _xerinPrimary)),
            ),
          ),
      ]),
    );
  }

  Widget _quickActions(BuildContext context, ColorScheme cs, bool isDark) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final actions = <_QuickAction>[];

    if (AdminAccess.canAccessSection(user, 'Sellers')) {
      actions.add(_QuickAction('Sellers', Uicons.storeAlt, const Color(0xFFF59E0B), AppConstants.adminSellersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Products')) {
      actions.add(_QuickAction('Products', Uicons.boxOpen, const Color(0xFF009688), AppConstants.adminProductsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Orders')) {
      actions.add(_QuickAction('Orders', Uicons.shoppingBag, const Color(0xFF22C55E), AppConstants.adminOrdersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Users')) {
      actions.add(_QuickAction('Users', Uicons.users, const Color(0xFF3B82F6), AppConstants.adminUsersRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Wallets')) {
      actions.add(_QuickAction('Wallets', Uicons.wallet, const Color(0xFF3B82F6), AppConstants.adminWalletsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Refunds')) {
      actions.add(_QuickAction('Refunds', Uicons.rotateLeft, const Color(0xFFEF4444), AppConstants.adminRefundsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Reviews')) {
      actions.add(_QuickAction('Reviews', Uicons.star, const Color(0xFFFFC107), AppConstants.adminReviewsRoute));
    }
    if (AdminAccess.canAccessSection(user, 'Analytics')) {
      actions.add(_QuickAction('Analytics', Uicons.barChart, _xerinPrimary, AppConstants.adminAnalyticsRoute));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return _card(cs, isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
      const SizedBox(height: 16),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: actions.map((a) => _actionTile(cs, a.label, a.icon, a.color, () => context.push(a.route))).toList(),
      ),
    ]));
  }

  Widget _actionTile(ColorScheme cs, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'paid':
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'processing':
        return const Color(0xFF9C27B0);
      case 'shipped':
      case 'in_transit':
      case 'out_for_delivery':
      case 'transit':
        return const Color(0xFF9C27B0);
      case 'delivered':
      case 'completed':
        return const Color(0xFF22C55E);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _fmtStr(String v) {
    final d = double.tryParse(v) ?? 0;
    return _fmt(d);
  }

  String _shortDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return iso.length > 6 ? iso.substring(0, 6) : iso;
    }
  }

  String _periodLabel(String period) {
    switch (period) {
      case '7d':
        return '7-day';
      case '90d':
        return '90-day';
      default:
        return '30-day';
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _StatData {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.subtitle, this.icon, this.color);
}

class _FinanceItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _FinanceItem(this.label, this.value, this.icon, this.color);
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _QuickAction(this.label, this.icon, this.color, this.route);
}
