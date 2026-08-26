import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Uicons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Uicons.crossSmall),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          // Status filter chips
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
          // Summary
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
                      _buildSummaryChip('Total', '${s.totalOrders}'),
                      _buildSummaryChip('New', '${s.newOrders}'),
                      _buildSummaryChip('Gross', _formatMoney(s.grossSales)),
                      _buildSummaryChip('Units', '${s.unitsSold}'),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          // Orders list
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
                          const Icon(Uicons.box, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No orders found', style: Theme.of(context).textTheme.titleMedium),
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
                        const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
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
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, SellerOrderModel order) {
    final statusColor = _getStatusColor(order.sellerStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await context.push(
            AppConstants.sellerOrderDetailRoute,
            extra: {'orderId': order.id},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatStatus(order.sellerStatus),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Uicons.box, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Uicons.coin, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatMoney(order.sellerSubtotal, order.currency),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              if (order.shippingMethodName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Uicons.truckBox, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(order.shippingMethodName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    context.read<SellerCubit>().loadOrders(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          status: _selectedStatus,
        );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'accepted':
        return Colors.indigo;
      case 'processing':
        return Colors.orange;
      case 'ready_to_ship':
        return Colors.amber.shade700;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancellation_requested':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
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
