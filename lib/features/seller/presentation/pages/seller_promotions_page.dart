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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<PromotionModel> _promotions = [];
  bool _isLoading = true;
  String? _error;
  PromotionModel? _editingPromo;

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

  void _openCreateDrawer() {
    setState(() => _editingPromo = null);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _openEditDrawer(PromotionModel promo) {
    setState(() => _editingPromo = promo);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.surface,
      endDrawer: _PromotionFormDrawer(
        existing: _editingPromo,
        onSaved: () {
          Navigator.of(context).pop();
          _loadPromotions();
        },
      ),
      drawerScrimColor: Colors.black54,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('Promotions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openCreateDrawer,
                    icon: const Icon(Uicons.plus, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary.withValues(alpha: 0.08),
                      foregroundColor: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadPromotions, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _promotions.isEmpty
                          ? Center(
                              child: Text('No promotions yet',
                                style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPromotions,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
                                itemCount: _promotions.length,
                                itemBuilder: (context, index) => _buildPromotionCard(_promotions[index], cs),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(PromotionModel promo, ColorScheme cs) {
    final isPercentage = promo.promotionType == 'percentage';
    final discountText = isPercentage
        ? '${promo.discountValue.toStringAsFixed(0)}%'
        : 'TZS ${_formatMoney(promo.discountValue)}';
    final statusColor = promo.isActive ? const Color(0xFF22C55E) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(promo.code,
          style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$discountText off',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                promo.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _openEditDrawer(promo),
              icon: const Icon(Uicons.edit, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            IconButton(
              onPressed: () => _confirmDelete(promo),
              icon: const Icon(Uicons.trash, size: 16),
              style: IconButton.styleFrom(
                foregroundColor: Colors.red.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(PromotionModel promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion?'),
        content: Text('Delete "${promo.code}"?'),
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

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _PromotionFormDrawer extends StatefulWidget {
  final PromotionModel? existing;
  final VoidCallback onSaved;

  const _PromotionFormDrawer({this.existing, required this.onSaved});

  @override
  State<_PromotionFormDrawer> createState() => _PromotionFormDrawerState();
}

class _PromotionFormDrawerState extends State<_PromotionFormDrawer> {
  late final TextEditingController _codeController;
  late final TextEditingController _discountController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _maxDiscountController;
  String _promoType = 'percentage';
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _codeController = TextEditingController(text: e?.code ?? '');
    _discountController = TextEditingController(text: e?.discountValue.toStringAsFixed(0) ?? '');
    _minOrderController = TextEditingController(text: e?.minimumOrderAmount?.toStringAsFixed(0) ?? '');
    _usageLimitController = TextEditingController(text: e?.usageLimit?.toString() ?? '');
    _maxDiscountController = TextEditingController(text: e?.maximumDiscountAmount?.toStringAsFixed(0) ?? '');
    _promoType = e?.promotionType ?? 'percentage';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _usageLimitController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'code': _codeController.text.trim().toUpperCase(),
      'promotion_type': _promoType,
      'discount_value': double.tryParse(_discountController.text.trim()) ?? 0,
      if (_minOrderController.text.trim().isNotEmpty)
        'minimum_order_amount': double.tryParse(_minOrderController.text.trim()),
      if (_usageLimitController.text.trim().isNotEmpty)
        'usage_limit': int.tryParse(_usageLimitController.text.trim()),
      if (_maxDiscountController.text.trim().isNotEmpty)
        'maximum_discount_amount': double.tryParse(_maxDiscountController.text.trim()),
    };

    try {
      final ds = sl<PromotionRemoteDataSource>();
      if (widget.existing != null) {
        await ds.updateSellerPromotion(promotionId: widget.existing!.id, data: data);
      } else {
        await ds.createSellerPromotion(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null ? 'Promotion created' : 'Promotion updated'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _fieldDecoration(String label, String hint, ColorScheme cs, {String? suffixText, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      suffixText: suffixText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Drawer(
      width: 360,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Uicons.ticket, size: 20, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(isEditing ? 'Edit Promotion' : 'New Promotion',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Uicons.xmark, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: _fieldDecoration(
                        'Promo Code',
                        'e.g. SUMMER20',
                        cs,
                        helper: 'Customers enter this code at checkout',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _promoType,
                      decoration: _fieldDecoration('Discount Type', 'Select type', cs),
                      items: const [
                        DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                      ],
                      onChanged: (v) => setState(() => _promoType = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountController,
                      decoration: _fieldDecoration(
                        _promoType == 'percentage' ? 'Discount Percentage' : 'Discount Amount',
                        _promoType == 'percentage' ? 'e.g. 20' : 'e.g. 5000',
                        cs,
                        suffixText: _promoType == 'percentage' ? '%' : 'TZS',
                        helper: _promoType == 'percentage' ? 'Percentage off the order total' : 'Fixed amount off the order',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _minOrderController,
                      decoration: _fieldDecoration(
                        'Minimum Order Amount',
                        'e.g. 10000',
                        cs,
                        suffixText: 'TZS',
                        helper: 'Leave empty for no minimum',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usageLimitController,
                      decoration: _fieldDecoration(
                        'Usage Limit',
                        'e.g. 100',
                        cs,
                        helper: 'Max times this code can be used',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? 'Save' : 'Create'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
