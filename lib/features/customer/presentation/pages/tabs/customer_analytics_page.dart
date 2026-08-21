import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/customer_cubit.dart';
import '../../cubit/customer_state.dart';
import '../../../data/models/order_model.dart';
import '../../../../common/presentation/widgets/kpi_widgets.dart';
import '../../../../../core/theme/uicons.dart';

class CustomerAnalyticsPage extends StatefulWidget {
  const CustomerAnalyticsPage({super.key});

  @override
  State<CustomerAnalyticsPage> createState() => _CustomerAnalyticsPageState();
}

class _CustomerAnalyticsPageState extends State<CustomerAnalyticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000000) return '${(amount / 1000000000).toStringAsFixed(2)}B';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  List<double> _buildDailySpending(List<OrderModel> orders, int days) {
    final now = DateTime.now();
    final dailyTotals = List<double>.filled(days, 0.0);

    for (final order in orders) {
      final createdAt = order.createdAt;
      if (createdAt == null) continue;
      try {
        final date = DateTime.parse(createdAt);
        final diff = now.difference(date).inDays;
        if (diff >= 0 && diff < days) {
          dailyTotals[days - 1 - diff] += order.total;
        }
      } catch (_) {}
    }

    return dailyTotals;
  }

  List<String> _buildDayLabels(int days) {
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      labels.add(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1]);
    }
    return labels;
  }

  List<TopProductItem> _buildTopProducts(List<OrderModel> orders) {
    final productMap = <String, TopProductAccumulator>{};

    for (final order in orders) {
      for (final item in order.items) {
        final existing = productMap[item.productName];
        if (existing != null) {
          existing.qty += (item.quantity as int);
          existing.revenue += item.unitPrice * item.quantity;
        } else {
          productMap[item.productName] = TopProductAccumulator(
            qty: item.quantity,
            revenue: item.unitPrice * item.quantity,
          );
        }
      }
    }

    final items = productMap.entries.map((e) {
      return TopProductItem(name: e.key, qty: e.value.qty, revenue: e.value.revenue);
    }).toList();

    items.sort((a, b) => b.revenue.compareTo(a.revenue));
    return items.take(5).toList();
  }

  List<DonutSegment> _buildOrderStatusSegments(List<OrderModel> orders) {
    if (orders.isEmpty) return [];

    final statusCounts = <String, int>{};
    for (final order in orders) {
      final status = order.status.toLowerCase();
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final colorMap = <String, Color>{
      'pending': const Color(0xFFF59E0B),
      'processing': const Color(0xFF3B82F6),
      'shipped': const Color(0xFF8B5CF6),
      'delivered': const Color(0xFF22C55E),
      'cancelled': const Color(0xFFE53935),
    };

    return statusCounts.entries.map((e) {
      return DonutSegment(
        label: e.key[0].toUpperCase() + e.key.substring(1),
        value: e.value.toDouble(),
        color: colorMap[e.key] ?? const Color(0xFF9CA3AF),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            if (state is CustomerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CustomerError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Uicons.circleExclamation, size: 48, color: colorScheme.error),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CustomerCubit>().loadAll(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final orders = state is CustomerLoaded ? state.orders : <OrderModel>[];
            final dailySpending = _buildDailySpending(orders, 7);
            final dayLabels = _buildDayLabels(7);
            final topProducts = _buildTopProducts(orders);
            final statusSegments = _buildOrderStatusSegments(orders);

            final totalSpent = state is CustomerLoaded ? state.totalSpent : 0.0;
            final avgOrderValue = state is CustomerLoaded ? state.avgOrderValue : 0.0;
            final totalOrders = state is CustomerLoaded ? state.totalOrders : 0;
            final deliveredCount = state is CustomerLoaded ? state.deliveredOrders : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Analytics',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text('Track your spending and order insights',
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 24),

                  // Gradient KPI row
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      GradientKpiCard(
                        label: 'Total Spent',
                        value: 'TZS ${_formatCompact(totalSpent)}',
                        subValue: 'From delivered orders',
                        icon: Uicons.accountBalanceWallet,
                        gradientColors: [const Color(0xFFF47524), const Color(0xFFFF9A56)],
                      ),
                      GradientKpiCard(
                        label: 'Total Orders',
                        value: '$totalOrders',
                        subValue: '${state is CustomerLoaded ? state.pendingOrders : 0} pending',
                        icon: Uicons.shoppingBag,
                        gradientColors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // White KPI row
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      WhiteKpiCard(
                        label: 'Avg Order Value',
                        value: 'TZS ${_formatCompact(avgOrderValue)}',
                        subValue: 'Per order average',
                        icon: Uicons.arrowTrendUp,
                        color: const Color(0xFF22C55E),
                        subColor: const Color(0xFF22C55E),
                      ),
                      WhiteKpiCard(
                        label: 'Delivered',
                        value: '$deliveredCount',
                        subValue: 'Successfully delivered',
                        icon: Uicons.checkCircle,
                        color: const Color(0xFF8B5CF6),
                        subColor: const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Spending chart
                  SellerSectionHeader(
                    title: 'Spending Trend',
                    subtitle: 'Last 7 days',
                    icon: Uicons.barChart,
                    iconColor: const Color(0xFFF47524),
                  ),
                  const SizedBox(height: 12),
                  RevenueBarChart(
                    data: dailySpending,
                    labels: dayLabels,
                    barGradient: const [Color(0xFFF47524), Color(0xFFFF9A56)],
                    title: 'Daily Spending',
                    subtitle: 'TZS spent per day',
                  ),
                  const SizedBox(height: 24),

                  // Order status donut
                  SellerSectionHeader(
                    title: 'Order Status',
                    subtitle: 'Breakdown of all orders',
                    icon: Uicons.pieChart,
                    iconColor: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  SellerDonutChart(
                    segments: statusSegments,
                    title: 'Orders by Status',
                    subtitle: 'Distribution overview',
                  ),
                  const SizedBox(height: 24),

                  // Top products
                  SellerSectionHeader(
                    title: 'Top Purchased Products',
                    subtitle: 'Most bought items',
                    icon: Uicons.box,
                    iconColor: const Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 12),
                  TopProductsList(
                    items: topProducts,
                    title: 'Most Purchased',
                    subtitle: 'By total spent',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TopProductAccumulator {
  int qty;
  double revenue;
  TopProductAccumulator({required this.qty, required this.revenue});
}
