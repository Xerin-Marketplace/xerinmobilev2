import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/seller_cubit.dart';
import '../cubit/seller_state.dart';
import '../widgets/seller_kpi_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SellerCubit, SellerState>(
          builder: (context, state) {
            if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SellerDashboardLoaded) {
              return _buildContent(state, colorScheme);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildContent(SellerDashboardLoaded state, ColorScheme colorScheme) {
    final orders = state.orders;
    final products = state.products;
    final inventory = state.inventory;

    final totalRevenue = state.totalRevenue;
    final totalOrders = orders.length;
    final completedOrders = state.completedOrders;
    final pendingOrders = state.pendingOrders;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final completionRate = totalOrders > 0
        ? (completedOrders / totalOrders * 100)
        : 0.0;

    // Build order status donut segments
    final statusSegments = _buildStatusSegments(orders);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackIconButton(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppConstants.sellerDashboardRoute);
                        }
                      },
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // KPI Row 1 — Gradient cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    GradientKpiCard(
                      label: 'Total Revenue',
                      value: _formatCompact(totalRevenue),
                      subValue: '$completedOrders completed',
                      icon: Icons.show_chart_rounded,
                      gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                    ),
                    GradientKpiCard(
                      label: 'Total Orders',
                      value: '$totalOrders',
                      subValue: '$pendingOrders pending',
                      icon: Icons.shopping_cart_checkout_rounded,
                      gradientColors: const [Color(0xFFF47524), Color(0xFFE65100)],
                    ),
                    GradientKpiCard(
                      label: 'Avg Order Value',
                      value: _formatCompact(avgOrderValue),
                      subValue: 'Per transaction',
                      icon: Icons.trending_up_rounded,
                      gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    GradientKpiCard(
                      label: 'Completion',
                      value: '${completionRate.toStringAsFixed(1)}%',
                      subValue: '$completedOrders of $totalOrders',
                      icon: Icons.check_circle_rounded,
                      gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Order status donut chart
                SellerDonutChart(
                  segments: statusSegments,
                  title: 'Order Status Distribution',
                  subtitle: 'All orders by status',
                ),
                const SizedBox(height: 24),
                // Product & inventory summary
                _buildProductsSection(products, inventory, state.lowStockItems.length, colorScheme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
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

  Widget _buildProductsSection(products, inventory, lowStockCount, ColorScheme colorScheme) {
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
            title: 'Product & Inventory Summary',
            subtitle: 'Stock and product overview',
            icon: Icons.inventory_2_rounded,
            iconColor: const Color(0xFFF47524),
          ),
          const SizedBox(height: 16),
          _summaryRow('Total Products', '${products.length}', colorScheme),
          const SizedBox(height: 10),
          _summaryRow('Inventory Items', '${inventory.length}', colorScheme),
          const SizedBox(height: 10),
          _summaryRow('Low Stock Items', '$lowStockCount', colorScheme),
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
