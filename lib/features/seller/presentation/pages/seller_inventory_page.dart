import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/seller_orders_inventory_cubit.dart';
import '../../data/models/seller_inventory_model.dart';

class SellerInventoryPage extends StatefulWidget {
  const SellerInventoryPage({super.key});

  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<SellerOrdersInventoryCubit>().loadInventorySummary();
    context.read<SellerOrdersInventoryCubit>().listInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Items'),
            Tab(text: 'Low Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(),
          _ItemsTab(searchController: _searchController),
          _LowStockTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerOrdersInventoryCubit, SellerOrdersInventoryState>(
      builder: (context, state) {
        if (state is SellerInventorySummaryLoaded) {
          final s = state.summary;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            children: [
              _StatCard('Total Products', s.totalProducts.toString(), Icons.inventory_2),
              _StatCard('Total Variants', s.totalVariants.toString(), Icons.category),
              _StatCard('Stock Units', s.totalStockUnits.toString(), Icons.widgets),
              _StatCard('Available', s.availableUnits.toString(), Icons.check_circle, Colors.green),
              _StatCard('Reserved', s.reservedUnits.toString(), Icons.lock, Colors.orange),
              _StatCard('Low Stock', s.lowStockVariants.toString(), Icons.warning, Colors.amber),
              _StatCard('Out of Stock', s.outOfStockVariants.toString(), Icons.error, Colors.red),
              _StatCard('Inventory Value', s.inventoryValue.toStringAsFixed(0), Icons.attach_money, Colors.teal),
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

class _ItemsTab extends StatelessWidget {
  final TextEditingController searchController;

  const _ItemsTab({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  context.read<SellerOrdersInventoryCubit>().listInventory();
                },
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              context.read<SellerOrdersInventoryCubit>().listInventory(search: value.trim());
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<SellerOrdersInventoryCubit, SellerOrdersInventoryState>(
            builder: (context, state) {
              if (state is SellerInventoryListLoaded) {
                if (state.items.isEmpty) {
                  return const Center(child: Text('No inventory items'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    return _InventoryItemCard(item: state.items[index]);
                  },
                );
              }
              if (state is SellerOrdersInventoryError) {
                return Center(child: Text(state.message));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }
}

class _LowStockTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerOrdersInventoryCubit, SellerOrdersInventoryState>(
      builder: (context, state) {
        if (state is SellerInventoryLowStockLoaded) {
          if (state.items.isEmpty) {
            return const Center(child: Text('No low stock items'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              return _InventoryItemCard(item: state.items[index], isLowStock: true);
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

class _InventoryItemCard extends StatelessWidget {
  final SellerInventoryItemModel item;
  final bool isLowStock;

  const _InventoryItemCard({required this.item, this.isLowStock = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.variantName != null)
                    Text(
                      item.variantName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StockBadge(
                        label: 'Qty',
                        value: item.quantity.toString(),
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _StockBadge(
                        label: 'Available',
                        value: item.availableQuantity.toString(),
                        color: item.isOutOfStock
                            ? Colors.red
                            : item.isLowStock
                                ? Colors.amber
                                : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _StockBadge(
                        label: 'Reserved',
                        value: item.reservedQuantity.toString(),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  tooltip: 'Restock',
                  onPressed: () => _showRestockDialog(context, item),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, color: Colors.blue),
                  tooltip: 'Adjust',
                  onPressed: () => _showAdjustDialog(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, SellerInventoryItemModel item) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock - ${item.productName}'),
        content: TextField(
          controller: qtyController,
          decoration: const InputDecoration(labelText: 'Quantity to add'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim());
              if (qty != null && qty > 0) {
                context.read<SellerOrdersInventoryCubit>().restockInventory(
                      inventoryId: item.inventoryId,
                      quantity: qty,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(BuildContext context, SellerInventoryItemModel item) {
    final adjController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust - ${item.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adjController,
              decoration: const InputDecoration(
                labelText: 'Adjustment (+/-)',
                hintText: 'e.g. -5 or +10',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final adj = int.tryParse(adjController.text.trim());
              if (adj != null) {
                context.read<SellerOrdersInventoryCubit>().adjustInventory(
                      inventoryId: item.inventoryId,
                      adjustment: adj,
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StockBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
