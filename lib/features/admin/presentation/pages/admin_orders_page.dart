import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String? _statusFilter;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadOrders();
  }

  static const _statuses = [
    ('all', 'All'),
    ('pending', 'Pending'),
    ('processing', 'Processing'),
    ('shipped', 'Shipped'),
    ('delivered', 'Delivered'),
    ('cancelled', 'Cancelled'),
    ('refunded', 'Refunded'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statuses.map((s) {
            final isSelected = (_statusFilter ?? 'all') == s.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.$2),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _statusFilter = s.$1 == 'all' ? null : s.$1;
                  });
                  context.read<AdminCubit>().loadOrders(status: _statusFilter);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminOrdersLoaded) {
          if (state.orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                context.read<AdminCubit>().loadMoreOrders();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orders.length + (state.loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.orders.length) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ));
                }
                return _orderCard(context, state.orders[index]);
              },
            ),
          );
        }
        if (state is AdminError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Uicons.triangleWarning, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AdminCubit>().loadOrders(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!_isReloading) {
          _isReloading = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AdminCubit>().loadOrders(status: _statusFilter);
            _isReloading = false;
          });
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _orderCard(BuildContext context, Map<String, dynamic> order) {
    final orderNumber = order['order_number']?.toString() ?? 'N/A';
    final status = order['status']?.toString() ?? 'pending';
    final total = order['total']?.toString() ?? '0';
    final currency = order['currency']?.toString() ?? 'TZS';
    final createdAt = order['created_at']?.toString() ?? '';
    final userName = order['user']?['first_name']?.toString() ??
        order['customer_name']?.toString() ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Customer: $userName', style: const TextStyle(fontSize: 12)),
            Text('Total: $currency $total', style: const TextStyle(fontSize: 12)),
            if (createdAt.isNotEmpty)
              Text('Date: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor(status).withValues(alpha: 0.2)),
              ),
              child: Text(_humanize(status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status))),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
