import 'package:flutter/material.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/uicons.dart';
import '../../../customer/data/datasources/promotion_remote_datasource.dart';
import '../../../customer/data/models/promotion_model.dart';

class SellerPromotionsPage extends StatefulWidget {
  const SellerPromotionsPage({super.key});

  @override
  State<SellerPromotionsPage> createState() => _SellerPromotionsPageState();
}

class _SellerPromotionsPageState extends State<SellerPromotionsPage> {
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ds = sl<PromotionRemoteDataSource>();
      final promotions = await ds.getSellerPromotions();
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.plus),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadPromotions, child: const Text('Retry')),
                    ],
                  ),
                )
              : _promotions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Uicons.ticket, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('No promotions yet', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateDialog(context),
                            icon: const Icon(Uicons.plus),
                            label: const Text('Create Promotion'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPromotions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) => _buildPromotionCard(context, _promotions[index]),
                      ),
                    ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, PromotionModel promo) {
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
                Text(promo.code, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (promo.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promo.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(color: promo.isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${promo.promotionType == 'percentage' ? '${promo.discountValue.toStringAsFixed(0)}%' : 'TZS ${promo.discountValue.toStringAsFixed(0)}'} discount'),
            if (promo.minimumOrderAmount != null) Text('Min order: TZS ${promo.minimumOrderAmount!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (promo.usageLimit != null) Text('Usage: ${promo.usageCount}/${promo.usageLimit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (promo.startsAt != null) Text('Starts: ${_formatDate(promo.startsAt!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (promo.endsAt != null) Text('Ends: ${_formatDate(promo.endsAt!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, promo),
                  icon: const Icon(Uicons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(context, promo),
                  icon: const Icon(Uicons.trash, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    _showFormDialog(context, null);
  }

  void _showEditDialog(BuildContext context, PromotionModel promo) {
    _showFormDialog(context, promo);
  }

  void _showFormDialog(BuildContext context, PromotionModel? existing) {
    final codeController = TextEditingController(text: existing?.code ?? '');
    final discountController = TextEditingController(text: existing?.discountValue.toStringAsFixed(0) ?? '');
    final minOrderController = TextEditingController(text: existing?.minimumOrderAmount?.toStringAsFixed(0) ?? '');
    final usageLimitController = TextEditingController(text: existing?.usageLimit?.toString() ?? '');
    String promoType = existing?.promotionType ?? 'percentage';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Create Promotion' : 'Edit Promotion'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: promoType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (v) => promoType = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: discountController,
                  decoration: const InputDecoration(labelText: 'Discount Value *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minOrderController,
                  decoration: const InputDecoration(labelText: 'Min Order Amount', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: usageLimitController,
                  decoration: const InputDecoration(labelText: 'Usage Limit', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final data = <String, dynamic>{
                  'code': codeController.text.trim().toUpperCase(),
                  'promotion_type': promoType,
                  'discount_value': double.tryParse(discountController.text.trim()) ?? 0,
                  if (minOrderController.text.trim().isNotEmpty)
                    'minimum_order_amount': double.tryParse(minOrderController.text.trim()),
                  if (usageLimitController.text.trim().isNotEmpty)
                    'usage_limit': int.tryParse(usageLimitController.text.trim()),
                };
                try {
                  final ds = sl<PromotionRemoteDataSource>();
                  if (existing != null) {
                    await ds.updateSellerPromotion(promotionId: existing.id, data: data);
                  } else {
                    await ds.createSellerPromotion(data);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existing == null ? 'Promotion created' : 'Promotion updated'), backgroundColor: Colors.green),
                    );
                    _loadPromotions();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PromotionModel promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion?'),
        content: Text('Delete promotion "${promo.code}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final ds = sl<PromotionRemoteDataSource>();
                await ds.deleteSellerPromotion(promo.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion deleted'), backgroundColor: Colors.green),
                  );
                  _loadPromotions();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
