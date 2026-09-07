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

  void _onSearch() {
    context.read<SellerCubit>().loadInventory(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          lowStock: _lowStockOnly ? true : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Control')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFEF4444)),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF22C55E)),
            );
            context.read<SellerCubit>().loadInventory();
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
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
                  FilledButton.tonal(
                    onPressed: _onSearch,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          if (state is SellerInventoryLoaded) {
            final s = state.summary;
            return RefreshIndicator(
              onRefresh: () async => _onSearch(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Header
                  Text('Inventory Workspace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Control real physical stock, monitor reservations and protect your catalogue from overselling.',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 20),

                  // Availability rule
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Physical − Reserved = Available',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                  ),
                  const SizedBox(height: 16),

                  // Stats grid
                  if (s != null) ...[
                    Row(
                      children: [
                        _buildStat(cs, '${s.totalStockUnits}', 'Stock units'),
                        const SizedBox(width: 8),
                        _buildStat(cs, '${s.reservedUnits}', 'Reserved'),
                        const SizedBox(width: 8),
                        _buildStat(cs, '${s.availableUnits}', 'Available'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStat(cs, '${s.lowStockVariants}', 'Low stock', color: const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _buildStat(cs, '${s.outOfStockVariants}', 'Out of stock', color: const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _buildStat(cs, '${s.totalVariants}', 'Variants'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stock health
                    _buildSectionTitle(cs, 'Stock health', 'A quick view of units available to customers versus reserved stock.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildHealthCard(cs, '${s.availableUnits}', 'Available to sell', const Color(0xFF22C55E))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildHealthCard(cs, '${s.reservedUnits}', 'Reserved by orders', const Color(0xFFF59E0B))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Inventory attention
                    _buildSectionTitle(cs, 'Inventory attention', 'Variants need restocking attention now.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildAttentionCard(cs, '${s.lowStockVariants}', 'low', const Color(0xFFF59E0B))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildAttentionCard(cs, '${s.outOfStockVariants}', 'out', const Color(0xFFEF4444))),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product, SKU or variant...',
                      hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Uicons.crossSmall, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                              onPressed: () { _searchController.clear(); _onSearch(); },
                            )
                          : null,
                      filled: true,
                      fillColor: cs.onSurface.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                  const SizedBox(height: 10),

                  // Filter
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('Low stock only', style: TextStyle(fontSize: 12)),
                        selected: _lowStockOnly,
                        onSelected: (v) { setState(() => _lowStockOnly = v); _onSearch(); },
                        visualDensity: VisualDensity.compact,
                      ),
                      const Spacer(),
                      Text('${state.inventory.results.length} items',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Inventory list
                  if (state.inventory.results.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Uicons.warehouse, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('No inventory found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.inventory.results.map((item) => _buildInventoryRow(context, cs, item)),

                  if (state.loadingMore)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStat(ColorScheme cs, String value, String label, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildHealthCard(ColorScheme cs, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(ColorScheme cs, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildInventoryRow(BuildContext context, ColorScheme cs, SellerInventoryItemModel item) {
    final statusColor = item.isOutOfStock
        ? const Color(0xFFEF4444)
        : item.isLowStock
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAdjustSheet(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // Status dot
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.productSku,
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item.variantName != null) ...[
                        const SizedBox(height: 2),
                        Text(item.variantName!,
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                // Numbers
                _buildNum(cs, '${item.quantity}', 'Physical'),
                const SizedBox(width: 12),
                _buildNum(cs, '${item.reservedQuantity}', 'Reserved'),
                const SizedBox(width: 12),
                _buildNum(cs, '${item.availableQuantity}', 'Available', highlight: true),
                const SizedBox(width: 8),
                // Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  padding: EdgeInsets.zero,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'adjust', child: Row(children: [
                      Icon(Uicons.edit, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Text('Adjust', style: TextStyle(fontSize: 14, color: cs.onSurface)),
                    ])),
                    PopupMenuItem(value: 'restock', child: Row(children: [
                      Icon(Uicons.plus, size: 16, color: cs.primary),
                      const SizedBox(width: 10),
                      Text('Restock', style: TextStyle(fontSize: 14, color: cs.primary)),
                    ])),
                  ],
                  onSelected: (action) {
                    if (action == 'adjust') _showAdjustSheet(context, item);
                    if (action == 'restock') _showRestockSheet(context, item);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNum(ColorScheme cs, String value, String label, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold,
          color: highlight ? cs.primary : cs.onSurface,
        )),
        Text(label, style: TextStyle(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.3))),
      ],
    );
  }

  void _showAdjustSheet(BuildContext context, SellerInventoryItemModel item) {
    final adjustController = TextEditingController();
    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adjust Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(item.productName, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 8),
              Text('Current: ${item.quantity}  |  Available: ${item.availableQuantity}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 20),
              _sheetLabel(cs, 'Adjustment (+/-) *'),
              TextField(
                controller: adjustController,
                keyboardType: TextInputType.number,
                decoration: _sheetInput(cs, 'e.g. -5 or 10'),
              ),
              const SizedBox(height: 14),
              _sheetLabel(cs, 'Reason *'),
              TextField(
                controller: reasonController,
                decoration: _sheetInput(cs, 'e.g. damage, correction, theft'),
              ),
              const SizedBox(height: 14),
              _sheetLabel(cs, 'Note'),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: _sheetInput(cs, 'Optional note'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (adjustController.text.trim().isEmpty || reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fill required fields'), backgroundColor: Color(0xFFEF4444)),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    context.read<SellerCubit>().adjustInventory(
                      item.inventoryId,
                      adjustment: int.tryParse(adjustController.text.trim()) ?? 0,
                      reason: reasonController.text.trim(),
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Adjust', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestockSheet(BuildContext context, SellerInventoryItemModel item) {
    final qtyController = TextEditingController();
    final locationController = TextEditingController(text: item.warehouseLocation ?? '');
    final noteController = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(item.productName, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
              const SizedBox(height: 8),
              Text('Current: ${item.quantity}  |  Available: ${item.availableQuantity}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: 20),
              _sheetLabel(cs, 'Quantity to add *'),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: _sheetInput(cs, 'e.g. 50'),
              ),
              const SizedBox(height: 14),
              _sheetLabel(cs, 'Warehouse location'),
              TextField(
                controller: locationController,
                decoration: _sheetInput(cs, 'Warehouse or shop location'),
              ),
              const SizedBox(height: 14),
              _sheetLabel(cs, 'Note'),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: _sheetInput(cs, 'Optional note'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (qtyController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter quantity'), backgroundColor: Color(0xFFEF4444)),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    context.read<SellerCubit>().restockInventory(
                      item.inventoryId,
                      quantity: int.tryParse(qtyController.text.trim()) ?? 0,
                      warehouseLocation: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Restock', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
    );
  }

  InputDecoration _sheetInput(ColorScheme cs, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
