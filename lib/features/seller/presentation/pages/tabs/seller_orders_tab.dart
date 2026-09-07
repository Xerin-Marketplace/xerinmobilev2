import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/constants/app_constants.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../data/models/seller_models.dart';
import '../../cubit/seller_cubit.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  static const _statusOptions = [
    ('all', 'All'),
    ('new', 'New'),
    ('accepted', 'Accepted'),
    ('processing', 'Processing'),
    ('ready_to_ship', 'Ready to Ship'),
    ('shipped', 'Shipped'),
    ('delivered', 'Delivered'),
    ('cancellation_requested', 'Cancellation'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<SellerCubit>().loadOrders(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          status: _selectedStatus,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
              prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Uicons.crossSmall, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _statusOptions.length,
            itemBuilder: (context, index) {
              final (value, label) = _statusOptions[index];
              final isSelected = (_selectedStatus ?? 'all') == value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = value == 'all' ? null : value;
                    });
                    _onSearch();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<SellerCubit, SellerState>(
          builder: (context, state) {
            if (state is SellerOrdersLoaded && state.summary != null) {
              final s = state.summary!;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryChip(cs, 'Total', '${s.totalOrders}'),
                    _buildSummaryChip(cs, 'New', '${s.newOrders}'),
                    _buildSummaryChip(cs, 'Gross', _formatMoney(s.grossSales)),
                    _buildSummaryChip(cs, 'Units', '${s.unitsSold}'),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BlocConsumer<SellerCubit, SellerState>(
            listener: (context, state) {
              if (state is SellerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state is SellerLoading || state is SellerInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SellerOrdersLoaded) {
                if (state.orders.results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Uicons.box, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text('No orders found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
                        state.hasMore &&
                        !state.loadingMore) {
                      context.read<SellerCubit>().loadMoreOrders(
                            search: _searchController.text.isNotEmpty ? _searchController.text : null,
                            status: _selectedStatus,
                          );
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.orders.results.length + (state.loadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.orders.results.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final order = state.orders.results[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
                );
              }
              if (state is SellerError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<SellerCubit>().loadOrders(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(ColorScheme cs, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface)),
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, SellerOrderModel order) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(order.sellerStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await context.push(AppConstants.sellerOrderDetailRoute, extra: {'orderId': order.id});
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatStatus(order.sellerStatus),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Uicons.box, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(width: 16),
                    Icon(Uicons.coin, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 4),
                    Text(_formatMoney(order.sellerSubtotal, order.currency), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
                if (order.shippingMethodName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Uicons.truckBox, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(order.shippingMethodName!, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(_formatDate(order.createdAt), style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return const Color(0xFF3B82F6);
      case 'accepted':
        return const Color(0xFF6366F1);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'ready_to_ship':
        return const Color(0xFFEAB308);
      case 'shipped':
        return const Color(0xFF14B8A6);
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'cancellation_requested':
        return const Color(0xFFEF4444);
      case 'cancelled':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'ready_to_ship':
        return 'Ready to Ship';
      case 'cancellation_requested':
        return 'Cancellation';
      default:
        return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
  }

  String _formatMoney(double amount, [String currency = 'TZS']) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
