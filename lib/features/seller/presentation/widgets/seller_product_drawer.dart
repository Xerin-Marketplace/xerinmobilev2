import 'package:flutter/material.dart';

import '../../../../../config/constants/api_constants.dart';
import '../../../../../config/di/service_locator.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/theme/uicons.dart';
import '../../../customer/data/models/product_model.dart';

class SellerProductDrawer extends StatefulWidget {
  final ProductModel? existing;
  final VoidCallback onSaved;

  const SellerProductDrawer({
    super.key,
    this.existing,
    required this.onSaved,
  });

  @override
  State<SellerProductDrawer> createState() => _SellerProductDrawerState();
}

class _SellerProductDrawerState extends State<SellerProductDrawer> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _skuController;
  late final TextEditingController _descController;
  late final TextEditingController _weightController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _priceController =
        TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _salePriceController =
        TextEditingController(text: e?.salePrice?.toStringAsFixed(0) ?? '');
    _skuController = TextEditingController(text: e?.sku ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _weightController = TextEditingController(text: e?.weight ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _generateSku() {
    final name = _nameController.text.trim();
    String prefix;
    if (name.isNotEmpty) {
      final cleaned = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      prefix = cleaned.substring(0, cleaned.length.clamp(0, 4));
      if (prefix.isEmpty) prefix = 'PRD';
    } else {
      prefix = 'PRD';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = timestamp.substring(timestamp.length - 5);
    final random = (100 + (DateTime.now().microsecond % 900)).toString();
    _skuController.text = '$prefix-$suffix-$random';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final client = sl<ApiClient>();
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        if (_salePriceController.text.trim().isNotEmpty)
          'sale_price': double.tryParse(_salePriceController.text.trim()),
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
        if (_weightController.text.trim().isNotEmpty)
          'weight': _weightController.text.trim(),
      };

      if (widget.existing != null) {
        await client.patch(
          ApiConstants.productById(widget.existing!.id),
          data: data,
        );
      } else {
        await client.post(ApiConstants.products, data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null
                ? 'Product created'
                : 'Product updated'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              color: cs.surface,
              borderRadius: BorderRadius.zero,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(-4, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(cs, isEdit),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              if (widget.existing?.thumbnailUrl != null) ...[
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      widget.existing!.thumbnailUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(Uicons.imageSlash,
                                            size: 36,
                                            color: cs.primary.withValues(alpha: 0.3)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              _buildLabel('Product Name *'),
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration(cs, 'Enter product name'),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Price (TZS) *'),
                                        TextFormField(
                                          controller: _priceController,
                                          decoration:
                                              _inputDecoration(cs, '0'),
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Required'
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Sale Price'),
                                        TextFormField(
                                          controller: _salePriceController,
                                          decoration:
                                              _inputDecoration(cs, 'Optional'),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('SKU'),
                                        TextFormField(
                                          controller: _skuController,
                                          decoration: _inputDecoration(cs, 'SKU code').copyWith(
                                            suffixIcon: widget.existing == null
                                                ? IconButton(
                                                    icon: Icon(Uicons.bolt,
                                                        size: 18,
                                                        color: cs.primary.withValues(alpha: 0.6)),
                                                    tooltip: 'Auto-generate',
                                                    onPressed: _generateSku,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel('Weight'),
                                        TextFormField(
                                          controller: _weightController,
                                          decoration:
                                              _inputDecoration(cs, 'e.g. 1.5kg'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildLabel('Description'),
                              TextFormField(
                                controller: _descController,
                                decoration: _inputDecoration(cs, 'Product description'),
                                maxLines: 4,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(cs),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEdit ? Uicons.edit : Uicons.plus,
              color: cs.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'Edit Product' : 'Add Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Uicons.crossSmall,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text(
                        widget.existing == null ? 'Create' : 'Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
