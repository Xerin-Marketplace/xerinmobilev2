import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerInventoryPage extends StatefulWidget {
  const SellerInventoryPage({super.key});

  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  final _searchController = TextEditingController();
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inventory...',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Low Stock Only'),
                  selected: _lowStockOnly,
                  onSelected: (v) {
                    setState(() => _lowStockOnly = v);
                    _onSearch();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Summary
          BlocBuilder<SellerCubit, SellerState>(
            builder: (context, state) {
              if (state is SellerInventoryLoaded && state.summary != null) {
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
                      _buildSummaryChip('Products', '${s.totalProducts}'),
                      _buildSummaryChip('Units', '${s.totalStockUnits}'),
                      _buildSummaryChip('Low', '${s.lowStockVariants}'),
                      _buildSummaryChip('Value', _formatMoney(s.inventoryValue)),
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
                if (state is SellerActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                  );
                  context.read<SellerCubit>().loadInventory();
                }
              },
              builder: (context, state) {
                if (state is SellerLoading || state is SellerInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SellerInventoryLoaded) {
                  if (state.inventory.results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Uicons.warehouse, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No inventory found', style: Theme.of(context).textTheme.titleMedium),
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
                        context.read<SellerCubit>().loadMoreInventory(
                              search: _searchController.text.isNotEmpty ? _searchController.text : null,
                              lowStock: _lowStockOnly ? true : null,
                            );
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.inventory.results.length + (state.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.inventory.results.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildInventoryCard(context, state.inventory.results[index]);
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
                          onPressed: () => context.read<SellerCubit>().loadInventory(),
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

  Widget _buildInventoryCard(BuildContext context, SellerInventoryItemModel item) {
    final statusColor = item.isOutOfStock
        ? Colors.red
        : item.isLowStock
            ? Colors.amber.shade700
            : Colors.green;

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
                  child: Text(
                    item.productName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
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
                    item.isOutOfStock ? 'OUT OF STOCK' : item.isLowStock ? 'LOW STOCK' : 'IN STOCK',
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (item.variantName != null) ...[
              const SizedBox(height: 4),
              Text(item.variantName!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStockInfo('Available', '${item.availableQuantity}'),
                const SizedBox(width: 24),
                _buildStockInfo('Reserved', '${item.reservedQuantity}'),
                const SizedBox(width: 24),
                _buildStockInfo('Total', '${item.quantity}'),
              ],
            ),
            if (item.warehouseLocation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Uicons.location, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(item.warehouseLocation!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAdjustDialog(context, item),
                    icon: const Icon(Uicons.edit, size: 16),
                    label: const Text('Adjust'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRestockDialog(context, item),
                    icon: const Icon(Uicons.plus, size: 16),
                    label: const Text('Restock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showAdjustDialog(BuildContext context, SellerInventoryItemModel item) {
    final adjustController = TextEditingController();
    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust: ${item.productName}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current: ${item.quantity} | Available: ${item.availableQuantity}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: adjustController,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment (+/-) *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. -5 or 10',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. damage, correction, theft',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                context.read<SellerCubit>().adjustInventory(
                      item.inventoryId,
                      adjustment: int.tryParse(adjustController.text.trim()) ?? 0,
                      reason: reasonController.text.trim(),
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(BuildContext context, SellerInventoryItemModel item) {
    final qtyController = TextEditingController();
    final locationController = TextEditingController(text: item.warehouseLocation ?? '');
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock: ${item.productName}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current: ${item.quantity} | Available: ${item.availableQuantity}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Add *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Warehouse Location', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                context.read<SellerCubit>().restockInventory(
                      item.inventoryId,
                      quantity: int.tryParse(qtyController.text.trim()) ?? 0,
                      warehouseLocation: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _onSearch() {
    context.read<SellerCubit>().loadInventory(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          lowStock: _lowStockOnly ? true : null,
        );
  }

  String _formatMoney(double amount, [String currency = 'TZS']) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }
}
