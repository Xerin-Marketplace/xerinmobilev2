import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';
import '../../widgets/seller_kpi_widgets.dart';

class SellerAnalyticsPage extends StatefulWidget {
  const SellerAnalyticsPage({super.key});

  @override
  State<SellerAnalyticsPage> createState() => _SellerAnalyticsPageState();
}

class _SellerAnalyticsPageState extends State<SellerAnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<SellerCubit, SellerState>(
      builder: (context, state) {
        if (state is SellerDashboardLoaded) {
          return _buildContent(state, colorScheme);
        }
        if (state is SellerLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SellerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SellerCubit>().loadDashboard(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildContent(SellerDashboardLoaded state, ColorScheme colorScheme) {
    final orders = state.orders;
    final products = state.products;
    final inventory = state.inventory;
    final lowStock = state.lowStockItems;

    final totalRevenue = state.totalRevenue;
    final totalOrders = orders.length;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final pendingCount = state.pendingOrders;
    final completedCount = state.completedOrders;
    final completionRate = totalOrders > 0
        ? (completedCount / totalOrders * 100)
        : 0.0;
    final lowStockRate = inventory.isNotEmpty
        ? (lowStock.length / inventory.length * 100)
        : 0.0;

    // Build daily revenue data (last 14 days)
    final dailyData = _buildDailyRevenueData(orders, 14);

    // Build order status donut segments
    final statusSegments = _buildStatusSegments(orders);

    // Build top products
    final topProducts = _buildTopProducts(orders);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your store performance',
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 24),
            // KPI Row 1 — Gradient cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                GradientKpiCard(
                  label: 'Avg Order Value',
                  value: _formatCompact(avgOrderValue),
                  subValue: 'Per transaction',
                  icon: Icons.trending_up_rounded,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                GradientKpiCard(
                  label: 'Completion Rate',
                  value: '${completionRate.toStringAsFixed(1)}%',
                  subValue: '$completedCount of $totalOrders orders',
                  icon: Icons.check_circle_rounded,
                  gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                ),
                GradientKpiCard(
                  label: 'Pending Orders',
                  value: '$pendingCount',
                  subValue: 'Awaiting processing',
                  icon: Icons.pending_actions_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                GradientKpiCard(
                  label: 'Low Stock Rate',
                  value: '${lowStockRate.toStringAsFixed(1)}%',
                  subValue: '${lowStock.length} of ${inventory.length} items',
                  icon: Icons.warning_amber_rounded,
                  gradientColors: const [Color(0xFFE53935), Color(0xFFDC2626)],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // KPI Row 2 — White cards (business overview)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                WhiteKpiCard(
                  label: 'Total Revenue',
                  value: _formatCompact(totalRevenue),
                  subValue: 'All completed orders',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFF47524),
                  subColor: const Color(0xFFF47524),
                ),
                WhiteKpiCard(
                  label: 'Total Products',
                  value: '${products.length}',
                  subValue: '${inventory.length} in stock',
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFF3B82F6),
                  subColor: const Color(0xFF3B82F6),
                ),
                WhiteKpiCard(
                  label: 'Total Orders',
                  value: '$totalOrders',
                  subValue: '$pendingCount pending',
                  icon: Icons.shopping_cart_rounded,
                  color: const Color(0xFF8B5CF6),
                  subColor: const Color(0xFF8B5CF6),
                ),
                WhiteKpiCard(
                  label: 'Healthy Stock',
                  value: '${inventory.length - lowStock.length}',
                  subValue: '${lowStock.length} need restock',
                  icon: Icons.verified_rounded,
                  color: const Color(0xFF22C55E),
                  subColor: const Color(0xFF22C55E),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Revenue bar chart (14 days)
            RevenueBarChart(
              data: dailyData['values'] as List<double>,
              labels: dailyData['labels'] as List<String>,
              barGradient: const [Color(0xFFF47524), Color(0xFFFB923C)],
              title: 'Revenue Trend',
              subtitle: 'Daily revenue (last 14 days)',
            ),
            const SizedBox(height: 24),
            // Order status donut chart
            SellerDonutChart(
              segments: statusSegments,
              title: 'Order Status Distribution',
              subtitle: 'All orders by status',
            ),
            const SizedBox(height: 24),
            // Top products
            if (topProducts.isNotEmpty) ...[
              TopProductsList(
                items: topProducts,
                title: 'Top Products Sold',
                subtitle: 'By revenue (completed orders)',
              ),
              const SizedBox(height: 24),
            ],
            // Inventory overview
            _buildInventoryOverview(inventory, lowStock, colorScheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _buildDailyRevenueData(orders, int days) {
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      double dayRevenue = 0;
      for (final order in orders) {
        if (order.status == 'delivered' || order.status == 'completed') {
          try {
            final orderDate = DateTime.parse(order.createdAt);
            if (orderDate.isAfter(dayStart) && orderDate.isBefore(dayEnd)) {
              dayRevenue += order.total;
            }
          } catch (_) {}
        }
      }
      values.add(dayRevenue);
      labels.add('${date.day}');
    }

    return {'values': values, 'labels': labels};
  }

  List<DonutSegment> _buildStatusSegments(orders) {
    final statusCounts = <String, int>{};
    for (final order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    return statusCounts.entries.map((entry) {
      return DonutSegment(
        label: entry.key,
        value: entry.value.toDouble(),
        color: _getStatusColor(entry.key),
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<TopProductItem> _buildTopProducts(orders) {
    final productMap = <String, TopProductItem>{};

    for (final order in orders) {
      if (order.status != 'delivered' && order.status != 'completed') continue;
      for (final item in order.items) {
        final name = item.productName;
        final existing = productMap[name];
        if (existing != null) {
          productMap[name] = TopProductItem(
            name: name,
            qty: existing.qty + (item.quantity as int),
            revenue: existing.revenue + (item.unitPrice * item.quantity),
          );
        } else {
          productMap[name] = TopProductItem(
            name: name,
            qty: item.quantity,
            revenue: item.unitPrice * item.quantity,
          );
        }
      }
    }

    final list = productMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list.take(5).toList();
  }

  Widget _buildInventoryOverview(inventory, lowStock, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SellerSectionHeader(
            title: 'Inventory Overview',
            subtitle: 'Stock health summary',
            icon: Icons.warehouse_rounded,
            iconColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Items', '${inventory.length}', colorScheme),
          const SizedBox(height: 10),
          _summaryRow('Low Stock Items', '${lowStock.length}', colorScheme),
          const SizedBox(height: 10),
          _summaryRow(
            'Healthy Stock',
            '${inventory.length - lowStock.length}',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
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
      case 'paid':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'TZS ${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      return 'TZS ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return 'TZS ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
