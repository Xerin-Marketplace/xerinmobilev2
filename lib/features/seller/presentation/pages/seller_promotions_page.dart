import 'package:flutter/material.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/uicons.dart';
import '../../../customer/data/datasources/promotion_remote_datasource.dart';
import '../../../customer/data/models/promotion_model.dart';
import '../../../customer/data/models/product_model.dart';

class SellerPromotionsPage extends StatefulWidget {
  const SellerPromotionsPage({super.key});

  @override
  State<SellerPromotionsPage> createState() => _SellerPromotionsPageState();
}

class _SellerPromotionsPageState extends State<SellerPromotionsPage> {
  final _searchController = TextEditingController();
  List<PromotionModel> _promotions = [];
  List<PromotionModel> _filtered = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromotions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final ds = sl<PromotionRemoteDataSource>();
      _promotions = await ds.getSellerPromotions();
      _filter();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filter() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _promotions
          : _promotions.where((p) => p.code.toLowerCase().contains(q)).toList();
    });
  }

  int get _activeCount => _promotions.where((p) => p.isActive).length;
  int get _totalUses => _promotions.fold(0, (sum, p) => sum + p.usageCount);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _loadPromotions,
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPromotions,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      Text('Promotions & Promo Codes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      const SizedBox(height: 4),
                      Text('Create seller-funded promotions for your products. Xerin marketplace commission remains separate from the seller-funded discount.',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showForm(context),
                          icon: const Icon(Uicons.plus, size: 18),
                          label: const Text('Create Promotion', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStat(cs, '${_promotions.length}', 'Promotions'),
                          const SizedBox(width: 8),
                          _buildStat(cs, '$_activeCount', 'Active'),
                          const SizedBox(width: 8),
                          _buildStat(cs, '$_totalUses', 'Total uses'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search name or promo code...',
                          hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                          prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Uicons.crossSmall, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                                  onPressed: () { _searchController.clear(); _filter(); },
                                )
                              : null,
                          filled: true,
                          fillColor: cs.onSurface.withValues(alpha: 0.04),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('All promotions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                          const Spacer(),
                          Text('${_filtered.length} items', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Uicons.ticket, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                                const SizedBox(height: 16),
                                Text('No promotions yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                                const SizedBox(height: 8),
                                Text('Create a promo code to attract more customers.',
                                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                                  textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._filtered.map((p) => _buildPromotionCard(context, cs, p)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStat(ColorScheme cs, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionCard(BuildContext context, ColorScheme cs, PromotionModel promo) {
    final isPercentage = promo.promotionType == 'percentage';
    final discountText = isPercentage
        ? '${promo.discountValue.toStringAsFixed(0)}% off'
        : 'TZS ${_fmtMoney(promo.discountValue)} off';
    final statusColor = promo.isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showForm(context, existing: promo),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promo.code,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface, fontFamily: 'monospace'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(discountText, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                      if (promo.usageCount > 0 || promo.usageLimit != null) ...[
                        const SizedBox(height: 2),
                        Text('${promo.usageCount}${promo.usageLimit != null ? '/${promo.usageLimit}' : ''} uses',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(promo.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  padding: EdgeInsets.zero,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Uicons.edit, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 10),
                      Text('Edit', style: TextStyle(fontSize: 14, color: cs.onSurface)),
                    ])),
                    PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Uicons.trash, size: 16, color: const Color(0xFFEF4444)),
                      const SizedBox(width: 10),
                      const Text('Delete', style: TextStyle(fontSize: 14, color: Color(0xFFEF4444))),
                    ])),
                  ],
                  onSelected: (action) {
                    if (action == 'edit') _showForm(context, existing: promo);
                    if (action == 'delete') _confirmDelete(promo);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, {PromotionModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PromotionFormSheet(existing: existing, onSaved: _loadPromotions),
    );
  }

  void _confirmDelete(PromotionModel promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion?'),
        content: Text('Delete "${promo.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final ds = sl<PromotionRemoteDataSource>();
                await ds.deleteSellerPromotion(promo.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion deleted'), backgroundColor: Color(0xFF22C55E)),
                  );
                  _loadPromotions();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
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

  String _fmtMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

// ─── Promotion Form Sheet ───
class _PromotionFormSheet extends StatefulWidget {
  final PromotionModel? existing;
  final VoidCallback onSaved;

  const _PromotionFormSheet({this.existing, required this.onSaved});

  @override
  State<_PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<_PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final TextEditingController _discountController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _usageLimitController;
  late final TextEditingController _usagePerCustomerController;
  late final TextEditingController _productSearchController;

  String _promoType = 'percentage';
  bool _isSaving = false;
  bool _isActive = true;
  bool _isAutomatic = false;
  bool _isStackable = false;
  DateTime? _startsAt;
  DateTime? _endsAt;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  final Set<String> _selectedProductIds = {};
  bool _productsLoading = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: '');
    _codeController = TextEditingController(text: e?.code ?? '');
    _descController = TextEditingController(text: '');
    _discountController = TextEditingController(text: e?.discountValue.toStringAsFixed(0) ?? '');
    _minOrderController = TextEditingController(text: e?.minimumOrderAmount?.toStringAsFixed(0) ?? '');
    _maxDiscountController = TextEditingController(text: e?.maximumDiscountAmount?.toStringAsFixed(0) ?? '');
    _usageLimitController = TextEditingController(text: e?.usageLimit?.toString() ?? '');
    _usagePerCustomerController = TextEditingController(text: '1');
    _productSearchController = TextEditingController();
    _promoType = e?.promotionType ?? 'percentage';
    _isActive = e?.isActive ?? true;
    _productSearchController.addListener(_filterProducts);
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    _usagePerCustomerController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final client = sl<ApiClient>();
      final response = await client.get(ApiConstants.myProducts, queryParameters: {'page_size': 50});
      final data = response.data;
      final List results = data is List ? data : (data['results'] as List? ?? []);
      setState(() {
        _allProducts = results.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
        _filteredProducts = _allProducts;
        _productsLoading = false;
      });
    } catch (_) {
      setState(() => _productsLoading = false);
    }
  }

  void _filterProducts() {
    final q = _productSearchController.text.toLowerCase().trim();
    setState(() {
      _filteredProducts = q.isEmpty
          ? _allProducts
          : _allProducts.where((p) =>
              p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) { _startsAt = dt; } else { _endsAt = dt; }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Not set';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m/$d/${dt.year} $h:$min';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code is required'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'code': _codeController.text.trim().toUpperCase(),
      'promotion_type': _promoType,
      'discount_value': double.tryParse(_discountController.text.trim()) ?? 0,
      'is_active': _isActive,
      'is_automatic': _isAutomatic,
      'is_stackable': _isStackable,
      if (_nameController.text.trim().isNotEmpty) 'name': _nameController.text.trim(),
      if (_descController.text.trim().isNotEmpty) 'description': _descController.text.trim(),
      if (_minOrderController.text.trim().isNotEmpty)
        'minimum_order_amount': double.tryParse(_minOrderController.text.trim()),
      if (_maxDiscountController.text.trim().isNotEmpty)
        'maximum_discount_amount': double.tryParse(_maxDiscountController.text.trim()),
      if (_usageLimitController.text.trim().isNotEmpty)
        'usage_limit': int.tryParse(_usageLimitController.text.trim()),
      if (_usagePerCustomerController.text.trim().isNotEmpty)
        'usage_per_customer': int.tryParse(_usagePerCustomerController.text.trim()),
      if (_startsAt != null) 'starts_at': _startsAt!.toIso8601String(),
      if (_endsAt != null) 'ends_at': _endsAt!.toIso8601String(),
      if (_selectedProductIds.isNotEmpty) 'product_ids': _selectedProductIds.toList(),
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
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: Column(
          children: [
            _buildHeader(cs, isEditing),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailsSection(cs),
                      const SizedBox(height: 28),
                      _buildScheduleSection(cs),
                      const SizedBox(height: 28),
                      _buildProductsSection(cs),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(cs, isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEditing ? 'Edit Promotion' : 'New Promotion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text('Create seller-funded promotion',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Uicons.crossSmall, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Promotion details', 'Define the code, discount and usage limits.'),
        const SizedBox(height: 16),
        _label(cs, 'Promotion name *'),
        _field(_nameController, 'Weekend Soap Discount', cs),
        const SizedBox(height: 14),
        _label(cs, 'Promo code *'),
        _field(_codeController, 'SOAP10', cs, caps: true),
        const SizedBox(height: 4),
        _hint(cs, 'Customers will enter this code during checkout.'),
        const SizedBox(height: 14),
        _label(cs, 'Description'),
        _field(_descController, 'Customer-facing explanation of this promotion.', cs, maxLines: 2),
        const SizedBox(height: 14),
        _label(cs, 'Discount type *'),
        DropdownButtonFormField<String>(
          initialValue: _promoType,
          decoration: _input(cs, 'Select type'),
          items: const [
            DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
            DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
          ],
          onChanged: (v) => setState(() => _promoType = v!),
        ),
        const SizedBox(height: 14),
        _label(cs, _promoType == 'percentage' ? 'Discount % *' : 'Discount amount *'),
        _field(_discountController, _promoType == 'percentage' ? 'e.g. 20' : 'e.g. 5000', cs,
          keyboardType: TextInputType.number,
          suffix: _promoType == 'percentage' ? '%' : 'TZS'),
        const SizedBox(height: 14),
        _label(cs, 'Minimum order amount'),
        _field(_minOrderController, 'Optional', cs, keyboardType: TextInputType.number, suffix: 'TZS'),
        const SizedBox(height: 14),
        _label(cs, 'Maximum discount amount'),
        _field(_maxDiscountController, 'Optional', cs, keyboardType: TextInputType.number, suffix: 'TZS'),
        const SizedBox(height: 14),
        _label(cs, 'Total usage limit'),
        _field(_usageLimitController, 'Unlimited', cs, keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        _label(cs, 'Usage per customer'),
        _field(_usagePerCustomerController, '1', cs, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildScheduleSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Schedule & behaviour', 'Control when and how customers can use the promotion.'),
        const SizedBox(height: 16),
        _label(cs, 'Start date / time'),
        _dateTimeField(cs, _formatDateTime(_startsAt), () => _pickDateTime(true)),
        const SizedBox(height: 14),
        _label(cs, 'End date / time'),
        _dateTimeField(cs, _formatDateTime(_endsAt), () => _pickDateTime(false)),
        const SizedBox(height: 14),
        _toggle(cs, 'Promotion active', 'Inactive promotions cannot be applied at checkout.', _isActive, (v) => setState(() => _isActive = v)),
        const SizedBox(height: 12),
        _toggle(cs, 'Automatic promotion', 'The backend may apply this without requiring a code when checkout integration is completed.', _isAutomatic, (v) => setState(() => _isAutomatic = v)),
        const SizedBox(height: 12),
        _toggle(cs, 'Stackable', 'Marks the promotion as eligible to combine with other promotions. Final checkout combination rules remain backend-controlled.', _isStackable, (v) => setState(() => _isStackable = v)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Seller-funded discount: this promotion reduces the seller-controlled amount. Xerin commission remains governed by the marketplace commission engine.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
        ),
      ],
    );
  }

  Widget _buildProductsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Select products', 'Only your own products can be targeted. The backend verifies ownership again when saving.'),
        const SizedBox(height: 12),
        Text('${_selectedProductIds.length} selected',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        const SizedBox(height: 12),
        TextField(
          controller: _productSearchController,
          decoration: InputDecoration(
            hintText: 'Search your products...',
            hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.4)),
            prefixIcon: Icon(Uicons.search, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        if (_productsLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_filteredProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No products found', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3))),
            ),
          )
        else
          ..._filteredProducts.map((p) => _buildProductItem(cs, p)),
      ],
    );
  }

  Widget _buildProductItem(ColorScheme cs, ProductModel p) {
    final selected = _selectedProductIds.contains(p.id);
    final price = p.customerPrice ?? p.price;
    return InkWell(
      onTap: () => setState(() {
        if (selected) { _selectedProductIds.remove(p.id); } else { _selectedProductIds.add(p.id); }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, size: 20,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${p.sku} \u00b7 Customer price TSh ${_fmtMoney(price)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs, bool isEditing) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                  : Text(isEditing ? 'Save' : 'Create Promotion', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _label(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
    );
  }

  Widget _hint(ColorScheme cs, String text) {
    return Text(text, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)));
  }

  Widget _field(TextEditingController controller, String hint, ColorScheme cs,
      {int maxLines = 1, TextInputType? keyboardType, String? suffix, bool caps = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: _input(cs, hint, suffix: suffix),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _dateTimeField(ColorScheme cs, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)))),
            Icon(Icons.calendar_today, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _toggle(ColorScheme cs, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(ColorScheme cs, String hint, {String? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      suffixText: suffix,
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  String _fmtMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
