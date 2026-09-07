import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../../../config/constants/api_constants.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

class BrokerProductsPage extends StatefulWidget {
  const BrokerProductsPage({super.key});

  @override
  State<BrokerProductsPage> createState() => _BrokerProductsPageState();
}

class _BrokerProductsPageState extends State<BrokerProductsPage> {
  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('B2 · Sell Your Own Product'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh, size: 20),
            onPressed: () => context.read<BrokerCubit>().loadProducts(),
          ),
        ],
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerActionSuccess) {
            NotificationService().success(state.message);
          } else if (state is BrokerError) {
            NotificationService().error(state.message);
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerProductsLoaded) {
            return _buildContent(context, state.products, cs);
          }
          if (state is BrokerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadProducts(),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<BrokerProductModel> products, ColorScheme cs) {
    final allCount = products.length;
    final liveCount = products.where((p) => p.status == 'active' || p.status == 'live').length;
    final expiredCount = products.where((p) => p.status == 'expired').length;

    return RefreshIndicator(
      onRefresh: () => context.read<BrokerCubit>().loadProducts(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _infoBanner(cs),
          const SizedBox(height: 16),
          _statsRow(cs, allCount, liveCount, expiredCount),
          const SizedBox(height: 20),
          _sectionTitle('Create Broker product', cs),
          const SizedBox(height: 12),
          _createProductForm(context, cs),
          const SizedBox(height: 24),
          _sectionTitle('Your Broker products', cs),
          const SizedBox(height: 12),
          if (products.isEmpty)
            _emptyState(cs)
          else
            ...products.map((p) => _productCard(context, p, cs)),
        ],
      ),
    );
  }

  Widget _infoBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mawingaPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mawingaPrimary.withValues(alpha: 0.12)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Uicons.circleInfo, size: 18, color: _mawingaPrimary),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'Create products you own. Once approved and public, each listing stays live for exactly 24 hours, then Xerin archives it automatically without deleting its history.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.6), height: 1.4),
        )),
      ]),
    );
  }

  Widget _statsRow(ColorScheme cs, int all, int live, int expired) {
    return Row(children: [
      Expanded(child: _statCard(cs, 'All', all.toString(), cs.onSurface)),
      const SizedBox(width: 10),
      Expanded(child: _statCard(cs, 'Live', live.toString(), const Color(0xFF22C55E))),
      const SizedBox(width: 10),
      Expanded(child: _statCard(cs, 'Expired', expired.toString(), const Color(0xFFEF4444))),
    ]);
  }

  Widget _statCard(ColorScheme cs, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _createProductForm(BuildContext context, ColorScheme cs) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final salePriceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1');
    final weightCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final currencyCtrl = ValueNotifier('TZS');

    return StatefulBuilder(builder: (context, setState) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadCategories(),
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];
          String? selectedCategoryId;
          if (categories.isNotEmpty) {
            selectedCategoryId = categories.first['id']?.toString();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _fieldLabel(cs, 'Product name'),
              const SizedBox(height: 6),
              _textField(cs, nameCtrl, 'Enter product name'),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Category'),
              const SizedBox(height: 6),
              _dropdownField(cs,
                catSnapshot.connectionState != ConnectionState.done
                    ? null
                    : (categories.isEmpty
                        ? null
                        : DropdownButton<String>(
                            value: selectedCategoryId,
                            isExpanded: true,
                            underline: const SizedBox(),
                            hint: const Text('Select category'),
                            items: categories.map((c) => DropdownMenuItem(
                              value: c['id']?.toString(),
                              child: Text(c['name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (v) => setState(() => selectedCategoryId = v),
                          )),
              ),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Brand (optional)'),
              const SizedBox(height: 6),
              _textField(cs, TextEditingController(), 'No brand'),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Currency'),
              const SizedBox(height: 6),
              ValueListenableBuilder<String>(
                valueListenable: currencyCtrl,
                builder: (context, currency, _) => _dropdownField(cs,
                  DropdownButton<String>(
                    value: currency,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const ['TZS', 'USD', 'KES'].map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13)),
                    )).toList(),
                    onChanged: (v) => currencyCtrl.value = v ?? 'TZS',
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Price'),
              const SizedBox(height: 6),
              _textField(cs, priceCtrl, '0.00', keyboardType: TextInputType.number),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Sale price (optional)'),
              const SizedBox(height: 6),
              _textField(cs, salePriceCtrl, '0.00', keyboardType: TextInputType.number),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Stock quantity'),
              const SizedBox(height: 6),
              _textField(cs, stockCtrl, '1', keyboardType: TextInputType.number),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Weight kg (optional)'),
              const SizedBox(height: 6),
              _textField(cs, weightCtrl, '0.0', keyboardType: TextInputType.number),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Pickup / fulfillment location'),
              const SizedBox(height: 6),
              _textField(cs, locationCtrl, 'e.g. Mikocheni, Dar es Salaam'),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Product images'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(children: [
                  Icon(Uicons.upload, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('No file chosen',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)))),
                  TextButton(
                    onPressed: () => NotificationService().info('Image upload coming soon'),
                    child: Text('Browse', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _mawingaPrimary)),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              _fieldLabel(cs, 'Description'),
              const SizedBox(height: 6),
              _textField(cs, descCtrl, 'Describe your product...', maxLines: 3),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) {
                      NotificationService().warning('Product name is required');
                      return;
                    }
                    if (priceCtrl.text.isEmpty) {
                      NotificationService().warning('Price is required');
                      return;
                    }
                    if (selectedCategoryId == null) {
                      NotificationService().warning('Please select a category');
                      return;
                    }
                    context.read<BrokerCubit>().createProduct({
                      'name': nameCtrl.text.trim(),
                      'category_id': selectedCategoryId,
                      'price': priceCtrl.text.trim(),
                      'currency': currencyCtrl.value,
                      'quantity': int.tryParse(stockCtrl.text) ?? 1,
                      if (salePriceCtrl.text.isNotEmpty) 'sale_price': salePriceCtrl.text.trim(),
                      if (weightCtrl.text.isNotEmpty) 'weight': weightCtrl.text.trim(),
                      if (locationCtrl.text.isNotEmpty) 'fulfillment_location': locationCtrl.text.trim(),
                      if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _mawingaPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create & Publish', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          );
        },
      );
    });
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    try {
      final client = context.read<ApiClient>();
      final res = await client.get(ApiConstants.productCategories);
      final data = res.data;
      final list = data is List ? data : (data['results'] as List? ?? []);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Widget _fieldLabel(ColorScheme cs, String label) {
    return Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)));
  }

  Widget _textField(ColorScheme cs, TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _dropdownField(ColorScheme cs, Widget? dropdown) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: dropdown ??
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading categories...',
                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Icon(Uicons.box, size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        Text('No Broker-owned products yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 4),
        Text('Create your first 24-hour listing using the form above.',
            style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _productCard(BuildContext context, BrokerProductModel product, ColorScheme cs) {
    final statusColors = {
      'active': const Color(0xFF22C55E),
      'live': const Color(0xFF22C55E),
      'draft': const Color(0xFF9CA3AF),
      'expired': const Color(0xFFEF4444),
      'rejected': const Color(0xFFEF4444),
      'pending': const Color(0xFFF59E0B),
    };
    final statusColor = statusColors[product.status] ?? const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _mawingaPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: product.primaryImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(product.primaryImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(Uicons.image, color: _mawingaPrimary, size: 22)),
                )
              : Icon(Uicons.image, color: _mawingaPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${product.currency} ${product.price}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _mawingaPrimary)),
          const SizedBox(height: 6),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(product.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
            const SizedBox(width: 8),
            Text('Qty: ${product.availableQuantity}',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ]),
        ])),
        if (product.status == 'draft')
          IconButton(
            icon: Icon(Uicons.upload, color: _mawingaPrimary, size: 20),
            onPressed: () => context.read<BrokerCubit>().publishProduct(product.id),
            tooltip: 'Publish',
          ),
      ]),
    );
  }
}
