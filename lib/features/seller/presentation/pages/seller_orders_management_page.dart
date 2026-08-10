import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/seller_orders_inventory_cubit.dart';
import '../../data/models/seller_order_detail_model.dart';

class SellerOrdersManagementPage extends StatefulWidget {
  const SellerOrdersManagementPage({super.key});

  @override
  State<SellerOrdersManagementPage> createState() => _SellerOrdersManagementPageState();
}

class _SellerOrdersManagementPageState extends State<SellerOrdersManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SellerOrdersInventoryCubit>().loadOrderSummary();
    context.read<SellerOrdersInventoryCubit>().listOrders(status: _statusFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Orders'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _statusFilter = value == 'all' ? null : value);
              context.read<SellerOrdersInventoryCubit>().listOrders(status: _statusFilter);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'new', child: Text('New')),
              PopupMenuItem(value: 'accepted', child: Text('Accepted')),
              PopupMenuItem(value: 'processing', child: Text('Processing')),
              PopupMenuItem(value: 'ready_to_ship', child: Text('Ready to Ship')),
              PopupMenuItem(value: 'shipped', child: Text('Shipped')),
              PopupMenuItem(value: 'delivered', child: Text('Delivered')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SummaryTab(),
          _OrdersListTab(),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerOrdersInventoryCubit, SellerOrdersInventoryState>(
      builder: (context, state) {
        if (state is SellerOrdersSummaryLoaded) {
          final s = state.summary;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            children: [
              _StatCard('Total Orders', s.totalOrders.toString(), Icons.shopping_bag),
              _StatCard('New', s.newOrders.toString(), Icons.new_releases, Colors.blue),
              _StatCard('Processing', s.processingOrders.toString(), Icons.settings, Colors.orange),
              _StatCard('Ready to Ship', s.readyToShipOrders.toString(), Icons.local_shipping, Colors.purple),
              _StatCard('Shipped', s.shippedOrders.toString(), Icons.flight_takeoff, Colors.indigo),
              _StatCard('Delivered', s.deliveredOrders.toString(), Icons.check_circle, Colors.green),
              _StatCard('Cancellations', s.cancellationRequests.toString(), Icons.cancel, Colors.red),
              _StatCard('Gross Sales', s.grossSales.toStringAsFixed(0), Icons.attach_money, Colors.teal),
            ],
          );
        }
        if (state is SellerOrdersInventoryError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _OrdersListTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerOrdersInventoryCubit, SellerOrdersInventoryState>(
      builder: (context, state) {
        if (state is SellerOrdersListLoaded) {
          if (state.orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.orders.length,
            itemBuilder: (context, index) {
              return _OrderCard(order: state.orders[index]);
            },
          );
        }
        if (state is SellerOrdersInventoryError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard(this.label, this.value, this.icon, [this.color]);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SellerOrderDetail order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.orderRef,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: order.sellerStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text('${order.itemCount} items - ${order.currency} ${order.sellerSubtotal.toStringAsFixed(0)}'),
            if (order.shippingAddress != null) ...[
              const SizedBox(height: 4),
              Text(
                '${order.shippingAddress!.city ?? ''}, ${order.shippingAddress!.region ?? ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _buildActionButtons(context, order),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, SellerOrderDetail order) {
    final cubit = context.read<SellerOrdersInventoryCubit>();
    final status = order.sellerStatus;

    final buttons = <Widget>[];

    if (status == 'new') {
      buttons.add(FilledButton.tonal(
        onPressed: () => cubit.acceptOrder(order.id),
        child: const Text('Accept'),
      ));
    }
    if (status == 'accepted') {
      buttons.add(FilledButton.tonal(
        onPressed: () => cubit.startProcessing(order.id),
        child: const Text('Start Processing'),
      ));
    }
    if (status == 'accepted' || status == 'processing') {
      buttons.add(FilledButton.tonal(
        onPressed: () => cubit.markReadyToShip(order.id),
        child: const Text('Ready to Ship'),
      ));
    }
    if (status == 'ready_to_ship') {
      buttons.add(FilledButton(
        onPressed: () => _showDispatchDialog(context, order.id),
        child: const Text('Dispatch'),
      ));
    }
    if (status != 'shipped' && status != 'delivered' && status != 'cancelled') {
      buttons.add(OutlinedButton(
        onPressed: () => _showCancelDialog(context, order.id),
        child: const Text('Cancel'),
      ));
    }

    return buttons;
  }

  void _showDispatchDialog(BuildContext context, String orderId) {
    final carrierController = TextEditingController();
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispatch Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(labelText: 'Carrier Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(labelText: 'Tracking Number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (carrierController.text.trim().isNotEmpty &&
                  trackingController.text.trim().isNotEmpty) {
                context.read<SellerOrdersInventoryCubit>().dispatchOrder(
                      orderId: orderId,
                      carrierName: carrierController.text.trim(),
                      trackingNumber: trackingController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Cancellation'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                context.read<SellerOrdersInventoryCubit>().requestCancellation(
                      orderId: orderId,
                      reason: reasonController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'new': Colors.blue,
      'accepted': Colors.teal,
      'processing': Colors.orange,
      'ready_to_ship': Colors.purple,
      'shipped': Colors.indigo,
      'delivered': Colors.green,
      'cancelled': Colors.red,
      'cancellation_requested': Colors.deepOrange,
    };

    final color = colors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
