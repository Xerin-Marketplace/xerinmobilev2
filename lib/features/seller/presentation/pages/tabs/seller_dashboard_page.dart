import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';
import '../../widgets/seller_kpi_widgets.dart';

class SellerDashboardPage extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const SellerDashboardPage({super.key, this.onNavigate});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SellerCubit, SellerState>(
      builder: (context, state) {
        if (state is SellerDashboardLoaded) {
          return _buildContent(state, colorScheme);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(SellerDashboardLoaded state, ColorScheme colorScheme) {
    final kycStatus = state.kycStatus?.sellerStatus ?? 'pending';

    // Revenue chart data from analytics sales
    final salesData = state.analyticsSales;
    final chartValues = <double>[];
    final chartLabels = <String>[];
    for (final s in salesData.take(14)) {
      chartValues.add(_pd(s['amount']));
      chartLabels.add((s['period'] as String?) ?? '');
    }

    // Top products from analytics
    final topProducts = state.analyticsProducts;

    // Order summary data
    final orderSummary = state.orderSummary;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<SellerCubit>().loadDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              _buildHeader(colorScheme),
              const SizedBox(height: 16),
              // KYC Banner
              if (kycStatus != 'approved' && kycStatus != 'under_review')
                _buildKycBanner(kycStatus, colorScheme),
              if (kycStatus != 'approved' && kycStatus != 'under_review')
                const SizedBox(height: 16),
              // Stats Grid (4 cards)
              _buildStatsGrid(state, colorScheme),
              const SizedBox(height: 20),
              // Revenue Chart
              if (chartValues.isNotEmpty)
                RevenueBarChart(
                  data: chartValues,
                  labels: chartLabels,
                  barGradient: const [Color(0xFFF47524), Color(0xFFFB923C)],
                  title: 'Revenue Overview',
                  subtitle: 'Last ${chartValues.length} days',
                ),
              const SizedBox(height: 20),
              // Top Products
              if (topProducts.isNotEmpty) ...[
                _buildTopProducts(topProducts, colorScheme),
                const SizedBox(height: 20),
              ],
              // Orders by Status
              if (orderSummary != null) ...[
                _buildOrderStatusChart(orderSummary, colorScheme),
                const SizedBox(height: 20),
              ],
              // Recent Orders
              _buildRecentOrdersSection(state.orders, colorScheme),
              const SizedBox(height: 20),
              // Earnings Summary
              _buildEarningsSummary(state, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Here's what's happening with your store today.",
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => widget.onNavigate?.call(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(SellerDashboardLoaded state, ColorScheme colorScheme) {
    final stats = [
      _StatData(
        title: 'Total Revenue',
        value: _formatPrice(state.totalRevenue),
        change: '${state.newOrders} new orders',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF22C55E),
      ),
      _StatData(
        title: 'Orders',
        value: '${state.totalOrders}',
        change: '${state.deliveredOrders} delivered',
        icon: Icons.shopping_cart_rounded,
        color: const Color(0xFFF47524),
      ),
      _StatData(
        title: 'Products',
        value: '${state.totalProducts}',
        change: '${state.readyToShipOrders} ready to ship',
        icon: Icons.inventory_2_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _StatData(
        title: 'Units Sold',
        value: '${state.unitsSold}',
        change: _formatPrice(state.avgOrderValue),
        icon: Icons.people_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: stats.map((s) => _buildStatCard(s, colorScheme)).toList(),
    );
  }

  Widget _buildStatCard(_StatData stat, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Icon(stat.icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              stat.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.arrow_upward_rounded, size: 12, color: stat.color),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  stat.change,
                  style: TextStyle(
                    fontSize: 11,
                    color: stat.color,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List<Map<String, dynamic>> products, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Products',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Best performing products (30d)',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          ...products.map((p) {
            final name = (p['name'] as String?) ?? 'Unknown';
            final units = _pi(p['units']);
            final orderCount = _pi(p['order_count']);
            final grossSales = _pd(p['gross_sales']);
            final netEarnings = _pd(p['net_earnings']);
            final idx = products.indexOf(p);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$units sold · $orderCount orders',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPrice(grossSales),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${_formatPrice(netEarnings)} net',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart(Map<String, dynamic> summary, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = [
      ('New', _pi(summary['new_orders'])),
      ('Accepted', _pi(summary['accepted_orders'])),
      ('Processing', _pi(summary['processing_orders'])),
      ('Ready', _pi(summary['ready_to_ship_orders'])),
      ('Shipped', _pi(summary['shipped_orders'])),
      ('Delivered', _pi(summary['delivered_orders'])),
    ];
    final maxCount = data.fold<int>(0, (max, d) => math.max(max, d.$2));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders by Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current order distribution',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          if (maxCount == 0)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'No orders yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) {
                  final isLast = d == data.last;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${d.$2}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: d.$1 == 'Delivered'
                                      ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                                      : d.$1 == 'New'
                                          ? [const Color(0xFFF47524), const Color(0xFFE65100)]
                                          : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.6)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.$1,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(List orders, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Latest orders from your store',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => widget.onNavigate?.call(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            SizedBox(
              height: 60,
              child: Center(
                child: Text(
                  'No orders yet. Orders will appear here once customers start buying.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else
            ...(orders as List).take(5).map((order) {
              final statusColor = _getStatusColor(order.status);
              final productName = order.items.isNotEmpty ? order.items.first.productName : 'Order';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.id.substring(0, 8)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            productName,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.formattedTotal,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.displayStatus,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary(SellerDashboardLoaded state, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      _SummaryData(
        title: 'Net Earnings',
        value: _formatPrice(state.netEarnings),
        subtitle: 'After platform commission',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF22C55E),
      ),
      _SummaryData(
        title: 'Commission Paid',
        value: _formatPrice(state.commissionPaid),
        subtitle: 'Platform commission (30d)',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFF47524),
      ),
      _SummaryData(
        title: 'Wallet Balance',
        value: _formatPrice(state.availableWalletBalance),
        subtitle: '${_formatPrice(state.pendingWalletBalance)} pending',
        icon: Icons.savings_rounded,
        color: const Color(0xFF6366F1),
      ),
    ];

    return Column(
      children: cards.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Icon(c.icon, size: 18, color: c.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.title == 'Net Earnings' ? c.color : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  c.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKycBanner(String kycStatus, ColorScheme colorScheme) {
    final isRejected = kycStatus == 'rejected';
    final isPending = kycStatus == 'pending' || kycStatus == 'pending_review';
    final borderColor = isRejected
        ? const Color(0xFFEF4444)
        : isPending
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);
    final bgColor = isRejected
        ? const Color(0xFFEF4444).withValues(alpha: 0.08)
        : isPending
            ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
            : const Color(0xFFF59E0B).withValues(alpha: 0.08);
    final iconColor = isRejected
        ? const Color(0xFFEF4444)
        : isPending
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () => context.go(AppConstants.sellerKycRoute),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isRejected
                    ? Icons.cancel_rounded
                    : isPending
                        ? Icons.access_time_rounded
                        : Icons.info_outline_rounded,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRejected
                        ? 'KYC Verification Rejected'
                        : isPending
                            ? 'KYC Under Review'
                            : 'Complete KYC Verification',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRejected
                        ? 'Please re-upload corrected documents to continue selling.'
                        : isPending
                            ? 'Your documents are being reviewed. This usually takes 1-2 business days.'
                            : 'Upload your business documents to verify your account.',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return const Color(0xFF22C55E);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'shipped':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatPrice(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'TSh $formatted';
  }
}

class _StatData {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });
}

class _SummaryData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

double _pd(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _pi(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
