import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';
import '../../widgets/seller_kpi_widgets.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
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
        if (state is SellerLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SellerDashboardLoaded) {
          return _buildContent(state, colorScheme);
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
    final profile = state.profile;
    final store = state.store;
    final orders = state.orders;
    final lowStock = state.lowStockItems;

    final totalRevenue = state.totalRevenue;
    final pendingOrders = state.pendingOrders;
    final completedOrders = state.completedOrders;

    // Build daily revenue data from orders (last 7 days)
    final dailyData = _buildDailyRevenueData(orders);

    // Build top products from orders
    final topProducts = _buildTopProducts(orders);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<SellerCubit>().loadDashboard(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(profile, store, colorScheme),
              const SizedBox(height: 20),
              // KPI Row 1 — Gradient cards (SalamaPay style)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  GradientKpiCard(
                    label: 'Total Revenue',
                    value: _formatCompact(totalRevenue),
                    subValue: '$completedOrders completed orders',
                    icon: Icons.account_balance_wallet_rounded,
                    gradientColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                  ),
                  GradientKpiCard(
                    label: 'Total Orders',
                    value: '${state.totalOrders}',
                    subValue: '$pendingOrders pending',
                    icon: Icons.shopping_cart_rounded,
                    gradientColors: const [Color(0xFFF47524), Color(0xFFE65100)],
                  ),
                  GradientKpiCard(
                    label: 'Products',
                    value: '${state.totalProducts}',
                    subValue: '${lowStock.length} low stock',
                    icon: Icons.inventory_2_rounded,
                    gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  GradientKpiCard(
                    label: 'Completed',
                    value: '$completedOrders',
                    subValue: '${state.totalOrders > 0 ? ((completedOrders / state.totalOrders) * 100).toStringAsFixed(0) : 0}% rate',
                    icon: Icons.check_circle_rounded,
                    gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Revenue bar chart
              RevenueBarChart(
                data: dailyData['values'] as List<double>,
                labels: dailyData['labels'] as List<String>,
                barGradient: const [Color(0xFFF47524), Color(0xFFFB923C)],
                title: 'Revenue Overview',
                subtitle: 'Last 7 days',
              ),
              const SizedBox(height: 24),
              // Section: Recent Orders
              SellerSectionHeader(
                title: 'Recent Orders',
                subtitle: 'Latest transactions',
                icon: Icons.receipt_long_rounded,
                iconColor: const Color(0xFFF47524),
              ),
              const SizedBox(height: 14),
              _buildRecentOrders(orders, colorScheme),
              const SizedBox(height: 24),
              // Section: Top Products
              if (topProducts.isNotEmpty) ...[
                TopProductsList(
                  items: topProducts,
                  title: 'Top Products',
                  subtitle: 'By revenue',
                ),
                const SizedBox(height: 24),
              ],
              // Section: Low Stock Alerts
              SellerSectionHeader(
                title: 'Low Stock Alerts',
                subtitle: '${lowStock.length} items need restocking',
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 14),
              _buildLowStock(lowStock, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildDailyRevenueData(orders) {
    final now = DateTime.now();
    final values = <double>[];
    final labels = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      double dayRevenue = 0;
      for (final order in orders) {
        if (order.status == 'delivered' || order.status == 'completed') {
          // Try to parse order date if available
          try {
            final orderDate = DateTime.parse(order.createdAt);
            if (orderDate.isAfter(dayStart) && orderDate.isBefore(dayEnd)) {
              dayRevenue += order.total;
            }
          } catch (_) {
            // If no date, skip
          }
        }
      }
      values.add(dayRevenue);
      labels.add(_dayLabel(date));
    }

    return {'values': values, 'labels': labels};
  }

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
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

  Widget _buildHeader(profile, store, ColorScheme colorScheme) {
    final storeName = store?.storeName ?? profile?.businessName ?? 'Seller Dashboard';
    final storeLogo = store?.logoUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: storeLogo != null && storeLogo.isNotEmpty
                    ? Image.network(
                        storeLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.store_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Dashboard',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    storeName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            _iconBtn(Icons.notifications_outlined, colorScheme),
            const SizedBox(width: 8),
            _iconBtn(Icons.refresh_rounded, colorScheme, () {
              context.read<SellerCubit>().loadDashboard();
            }),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, ColorScheme colorScheme, [VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                icon,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                size: 26,
              ),
            ),
            if (icon == Icons.notifications_outlined)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.surface, width: 1.5),
                  ),
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(orders, ColorScheme colorScheme) {
    if (orders.isEmpty) {
      return _buildEmptyState('No orders yet', Icons.shopping_bag_outlined, colorScheme);
    }

    final recent = orders.take(5).toList();

    return Column(
      children: recent.map((order) {
        final statusColor = _getStatusColor(order.status);
        final productName = order.items.isNotEmpty ? order.items.first.productName : 'Order';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_rounded, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${order.id.substring(0, 8)}',
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
                    order.formattedTotal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.displayStatus,
                      style: TextStyle(
                        fontSize: 10,
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
      }).toList(),
    );
  }

  Widget _buildLowStock(lowStock, ColorScheme colorScheme) {
    if (lowStock.isEmpty) {
      return _buildEmptyState('No low stock alerts', Icons.check_circle_outline, colorScheme);
    }

    return Column(
      children: lowStock.take(5).map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product: ${item.productId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Available: ${item.availableQuantity} / ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Low',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
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
