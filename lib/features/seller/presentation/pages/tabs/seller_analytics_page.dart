import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';

class SellerAnalyticsPage extends StatefulWidget {
  const SellerAnalyticsPage({super.key});

  @override
  State<SellerAnalyticsPage> createState() => _SellerAnalyticsPageState();
}

class _SellerAnalyticsPageState extends State<SellerAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().loadDashboard();
    });
  }

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

    final metrics = [
      _Metric(
        label: 'Avg Order Value',
        value: _formatCurrency(avgOrderValue),
        icon: Icons.shopping_basket_rounded,
        color: const Color(0xFF3B82F6),
      ),
      _Metric(
        label: 'Completion Rate',
        value: '${completionRate.toStringAsFixed(1)}%',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF22C55E),
      ),
      _Metric(
        label: 'Pending Orders',
        value: '$pendingCount',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _Metric(
        label: 'Low Stock Rate',
        value: '${lowStockRate.toStringAsFixed(1)}%',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE53935),
      ),
    ];

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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: metric.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(metric.icon, color: metric.color, size: 18),
                      ),
                      Text(
                        metric.value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        metric.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildRevenueSummary(totalRevenue, totalOrders, products.length, colorScheme),
            const SizedBox(height: 24),
            _buildOrderStatusBreakdown(orders, colorScheme),
            const SizedBox(height: 24),
            _buildInventoryOverview(inventory, lowStock, colorScheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSummary(double revenue, int orders, int products, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Revenue', _formatCurrency(revenue), colorScheme),
          const SizedBox(height: 10),
          _summaryRow('Total Orders', '$orders', colorScheme),
          const SizedBox(height: 10),
          _summaryRow('Total Products', '$products', colorScheme),
        ],
      ),
    );
  }

  Widget _buildOrderStatusBreakdown(orders, ColorScheme colorScheme) {
    final statusCounts = <String, int>{};
    for (final order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }

    if (statusCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sortedEntries.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedEntries.map((entry) {
            final percentage = maxCount > 0 ? entry.value / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildStatusBar(entry.key, entry.value, percentage, colorScheme),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInventoryOverview(inventory, lowStock, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
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

  Widget _buildStatusBar(String label, int count, double value, ColorScheme colorScheme) {
    final statusColor = _getStatusColor(label);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'TZS $formatted';
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
