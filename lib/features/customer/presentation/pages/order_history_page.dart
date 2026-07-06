import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/order_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  final List<OrderModel> _orders = [];
  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((o) => o.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  @override
  void initState() {
    super.initState();
    _orders.addAll(_sampleOrders);
  }

  Color _statusColor(String status, ColorScheme cs) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'processing': return const Color(0xFF3B82F6);
      case 'shipped': return const Color(0xFF8B5CF6);
      case 'delivered': return const Color(0xFF22C55E);
      case 'cancelled': return const Color(0xFFE53935);
      default: return cs.onSurface.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
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
                          borderRadius: BorderRadius.circular(20),
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
            if (_orders.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 72, color: colorScheme.onSurface.withValues(alpha: 0.2)),
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
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order, colorScheme);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ColorScheme colorScheme) {
    final statusColor = _statusColor(order.status, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order #${order.orderNumber.length > 8 ? order.orderNumber.substring(0, 8).toUpperCase() : order.orderNumber}',
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
                          child: Image.network(item.productImage!, fit: BoxFit.cover),
                        )
                      : Icon(Icons.inventory_2_outlined, color: colorScheme.primary.withValues(alpha: 0.4), size: 22),
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
              Text(order.createdAt ?? '',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final List<OrderModel> _sampleOrders = [
    OrderModel(id: 'ord_001', orderNumber: 'XERIN-2024-001', total: 45000, status: 'delivered', statusLabel: 'Delivered', itemCount: 3, createdAt: '2024-12-15',
      items: [
        OrderItemModel(id: 'item1', productName: 'Premium Leather Bag', quantity: 1, price: 25000),
        OrderItemModel(id: 'item2', productName: 'Wireless Earbuds', quantity: 2, price: 20000),
      ]),
    OrderModel(id: 'ord_002', orderNumber: 'XERIN-2024-002', total: 128500, status: 'shipped', statusLabel: 'Shipped', itemCount: 2, createdAt: '2024-12-20',
      items: [
        OrderItemModel(id: 'item3', productName: 'Smart Watch Pro', quantity: 1, price: 85000),
        OrderItemModel(id: 'item4', productName: 'USB-C Hub', quantity: 1, price: 43500),
      ]),
    OrderModel(id: 'ord_003', orderNumber: 'XERIN-2024-003', total: 32000, status: 'processing', statusLabel: 'Processing', itemCount: 1, createdAt: '2024-12-22',
      items: [
        OrderItemModel(id: 'item5', productName: 'Cotton T-Shirt Pack', quantity: 2, price: 32000),
      ]),
    OrderModel(id: 'ord_004', orderNumber: 'XERIN-2024-004', total: 89500, status: 'pending', statusLabel: 'Pending Payment', itemCount: 4, createdAt: '2024-12-24',
      items: [
        OrderItemModel(id: 'item6', productName: 'Bluetooth Speaker', quantity: 1, price: 35000),
        OrderItemModel(id: 'item7', productName: 'Phone Case', quantity: 3, price: 54500),
      ]),
    OrderModel(id: 'ord_005', orderNumber: 'XERIN-2024-005', total: 15000, status: 'cancelled', statusLabel: 'Cancelled', itemCount: 1, createdAt: '2024-12-18',
      items: [
        OrderItemModel(id: 'item8', productName: 'Running Shoes', quantity: 1, price: 15000),
      ]),
  ];
}
