import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/seller_cubit.dart';
import '../../cubit/seller_state.dart';

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

    final stats = [
      _StatCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Total Revenue',
        value: _formatCurrency(totalRevenue),
        color: const Color(0xFF22C55E),
      ),
      _StatCard(
        icon: Icons.shopping_bag_outlined,
        label: 'Orders',
        value: '${state.totalOrders}',
        subValue: '$pendingOrders pending',
        color: const Color(0xFFF47524),
      ),
      _StatCard(
        icon: Icons.inventory_2_outlined,
        label: 'Products',
        value: '${state.totalProducts}',
        subValue: '${lowStock.length} low stock',
        color: const Color(0xFF3B82F6),
      ),
      _StatCard(
        icon: Icons.check_circle_outline,
        label: 'Completed',
        value: '$completedOrders',
        color: const Color(0xFF8B5CF6),
      ),
    ];

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
              _buildStatsGrid(stats, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('Recent Orders', colorScheme),
              const SizedBox(height: 14),
              _buildRecentOrders(orders, colorScheme),
              const SizedBox(height: 24),
              _buildSectionTitle('Low Stock Alerts', colorScheme),
              const SizedBox(height: 14),
              _buildLowStock(lowStock, colorScheme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
            Column(
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
                ),
              ],
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

  Widget _buildStatsGrid(List<_StatCard> stats, ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stat.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (stat.subValue != null)
                      Text(
                        stat.subValue!,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
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
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
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

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return 'TZS $formatted';
  }
}

class _StatCard {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
  });
}
