import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/order_model.dart';
import '../../../common/presentation/widgets/kpi_widgets.dart';
import '../../../../core/theme/uicons.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'processing': return const Color(0xFF3B82F6);
      case 'shipped': return const Color(0xFF8B5CF6);
      case 'delivered': return const Color(0xFF22C55E);
      case 'cancelled': return const Color(0xFFE53935);
      default: return const Color(0xFF9CA3AF);
    }
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000000) return 'TZS ${(amount / 1000000000).toStringAsFixed(2)}B';
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(2)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(1)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  String _formatDate(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
            if (state is CustomerLoaded) {
              final orders = state.orders;
              final filtered = _selectedFilter == 'All'
                  ? orders
                  : orders.where((o) => o.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        BackIconButton(
                          onTap: () => context.pop(),
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text('Order History',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _filters.map((filter) {
                        final isSelected = filter == _selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedFilter = filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(filter,
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (orders.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: [
                          WhiteKpiCard(
                            label: 'Total Orders',
                            value: '${state.totalOrders}',
                            subValue: '${state.pendingOrders} pending',
                            icon: Uicons.shoppingBag,
                            color: const Color(0xFFF47524),
                            subColor: const Color(0xFFF47524),
                          ),
                          WhiteKpiCard(
                            label: 'Total Spent',
                            value: _formatCompact(state.totalSpent),
                            subValue: 'Delivered orders',
                            icon: Uicons.accountBalanceWallet,
                            color: const Color(0xFF22C55E),
                            subColor: const Color(0xFF22C55E),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (filtered.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Uicons.receipt, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('No orders yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 8),
                            Text('Your orders will appear here',
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(order, colorScheme, isDark);
                        },
                      ),
                    ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ColorScheme colorScheme, bool isDark) {
    final statusColor = _statusColor(order.status);

    return GestureDetector(
      onTap: () => context.push(AppConstants.orderDetailRoute, extra: {'order': order}),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ${order.orderRef}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(order.displayStatus,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: item.productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(item.productImage!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(Uicons.box, color: colorScheme.primary.withValues(alpha: 0.4), size: 22)),
                        )
                      : Icon(Uicons.box, color: colorScheme.primary.withValues(alpha: 0.4), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      Text('Qty: ${item.quantity}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ),
                ),
                Text(item.formattedPrice,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ],
            ),
          )),
          if (order.items.length > 2)
            Text('+${order.items.length - 2} more items',
              style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          Divider(height: 16, color: colorScheme.onSurface.withValues(alpha: 0.06)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${order.formattedTotal}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              Text(_formatDate(order.createdAt),
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
