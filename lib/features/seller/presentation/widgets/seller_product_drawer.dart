import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  int _currentStep = 0;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _slugController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _weightController;
  late final TextEditingController _stockController;

  String? _selectedCategory;
  String? _selectedBrand;
  String _selectedCurrency = 'TZS';
  bool _brokerPromotion = false;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];
  final List<String> _currencies = ['TZS', 'USD', 'KES', 'UGX'];

  final List<XFile> _selectedImages = [];
  List<String> _existingImages = [];

  String? _storeName;
  String? _storeLocation;
  String? _storeType;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _skuController = TextEditingController(text: e?.sku ?? '');
    _slugController = TextEditingController(text: e?.slug ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _priceController = TextEditingController(text: e?.price.toStringAsFixed(0) ?? '');
    _salePriceController = TextEditingController(text: e?.salePrice?.toStringAsFixed(0) ?? '');
    _weightController = TextEditingController(text: e?.weight ?? '');
    _stockController = TextEditingController(text: '');
    _selectedCategory = e?.categoryId;
    _selectedBrand = e?.brandId;
    _selectedCurrency = e?.currency ?? 'TZS';
    _existingImages = e?.images ?? [];

    _loadMetadata();
    _loadStoreInfo();
    _nameController.addListener(_updateSlug);
  }

  void _updateSlug() {
    if (widget.existing == null && _nameController.text.isNotEmpty) {
      final slug = _nameController.text.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'[\s]+'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      _slugController.text = slug;
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final client = sl<ApiClient>();
      final catRes = await client.get(ApiConstants.productCategories);
      final catData = catRes.data;
      final catList = catData is List ? catData : (catData['results'] as List? ?? []);
      setState(() => _categories = catList.cast<Map<String, dynamic>>());
    } catch (_) {}
    try {
      final client = sl<ApiClient>();
      final brandRes = await client.get(ApiConstants.productBrands);
      final brandData = brandRes.data;
      final brandList = brandData is List ? brandData : (brandData['results'] as List? ?? []);
      setState(() => _brands = brandList.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _loadStoreInfo() async {
    try {
      final client = sl<ApiClient>();
      final res = await client.get(ApiConstants.myStore);
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _storeName = data['name'] as String?;
        _storeType = data['type'] as String? ?? 'local';
        final loc = data['location'];
        _storeLocation = loc is Map ? loc['address'] as String? : loc as String?;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _slugController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _weightController.dispose();
    _stockController.dispose();
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
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = ts.substring(ts.length - 5);
    final random = (100 + (DateTime.now().microsecond % 900)).toString();
    _skuController.text = '$prefix-$suffix-$random';
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length + _existingImages.length >= 10) return;
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    final remaining = 10 - _selectedImages.length - _existingImages.length;
    setState(() => _selectedImages.addAll(images.take(remaining)));
  }

  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
               _skuController.text.isNotEmpty &&
               _descController.text.isNotEmpty &&
               _selectedCategory != null;
      case 1:
        return true;
      case 2:
        return _priceController.text.isNotEmpty &&
               double.tryParse(_priceController.text) != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _save({bool submit = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final client = sl<ApiClient>();
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim(),
        'slug': _slugController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'currency': _selectedCurrency,
        if (_salePriceController.text.trim().isNotEmpty)
          'sale_price': double.tryParse(_salePriceController.text.trim()),
        if (_weightController.text.trim().isNotEmpty)
          'weight': _weightController.text.trim(),
        if (_selectedCategory != null) 'category_id': _selectedCategory,
        if (_selectedBrand != null) 'brand_id': _selectedBrand,
        'status': submit ? 'pending_review' : 'draft',
        'allow_broker_promotion': _brokerPromotion,
      };

      String? productId;
      if (widget.existing != null) {
        productId = widget.existing!.id;
        await client.patch(ApiConstants.productById(productId), data: data);
      } else {
        final res = await client.post(ApiConstants.products, data: data);
        productId = res.data['id']?.toString();
      }

      if (productId != null && _selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          try {
            final formData = FormData.fromMap({
              'image': await MultipartFile.fromFile(_selectedImages[i].path),
              if (i == 0 && _existingImages.isEmpty) 'is_primary': true,
            });
            await client.post(
              ApiConstants.productImages(productId),
              data: formData,
              options: Options(headers: {'Content-Type': 'multipart/form-data'}),
            );
          } catch (_) {}
        }
      }

      if (productId != null && _stockController.text.trim().isNotEmpty) {
        final qty = int.tryParse(_stockController.text.trim()) ?? 0;
        if (qty > 0) {
          try {
            await client.post(ApiConstants.inventory, data: {
              'product_id': productId,
              'quantity': qty,
            });
          } catch (_) {}
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(submit
                ? 'Product submitted for review'
                : widget.existing == null ? 'Product saved as draft' : 'Product updated'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
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
              child: Container(
                width: MediaQuery.of(context).size.width * 0.92,
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildHeader(cs, isEdit),
                        _buildStepIndicator(cs),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildCurrentStep(cs),
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
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(isEdit ? 'Edit Product' : 'Add Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Uicons.crossSmall, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs) {
    final steps = ['Identity', 'Media', 'Pricing', 'Stock'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final si = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2, margin: const EdgeInsets.symmetric(horizontal: 4),
                color: si < _currentStep ? cs.primary : cs.onSurface.withValues(alpha: 0.08),
              ),
            );
          }
          final si = i ~/ 2;
          final isActive = si == _currentStep;
          final isDone = si < _currentStep;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isDone ? cs.primary : isActive ? cs.primary.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                      : Text('${si + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.4))),
                ),
              ),
              const SizedBox(width: 6),
              Text(steps[si],
                style: TextStyle(fontSize: 11, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4))),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme cs) {
    switch (_currentStep) {
      case 0: return _buildStepIdentity(cs);
      case 1: return _buildStepMedia(cs);
      case 2: return _buildStepPricing(cs);
      case 3: return _buildStepStock(cs);
      default: return const SizedBox();
    }
  }

  Widget _buildStepTitle(ColorScheme cs, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  // ─── Step 1: Identity ───
  Widget _buildStepIdentity(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(cs, 'Store & catalogue', 'Choose the marketplace category and provide the basic product information.'),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Store *'),
        const SizedBox(height: 6),
        _buildStoreChip(cs),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Product category *'),
        const SizedBox(height: 6),
        _buildDropdown(cs, _selectedCategory, _categories, 'id', 'name', 'Select category',
            (val) => setState(() => _selectedCategory = val)),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Brand'),
        const SizedBox(height: 6),
        _buildDropdown(cs, _selectedBrand, _brands, 'id', 'name', 'Select brand',
            (val) => setState(() => _selectedBrand = val)),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Product name *'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          decoration: _inputDecoration(cs, 'Enter product name'),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'SKU / ownership reference *'),
        const SizedBox(height: 4),
        Text('Your stock-keeping reference. Unique inside your seller catalog.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _skuController,
          decoration: _inputDecoration(cs, 'SKU code').copyWith(
            suffixIcon: widget.existing == null
                ? IconButton(icon: Icon(Uicons.bolt, size: 18, color: cs.primary.withValues(alpha: 0.6)),
                    tooltip: 'Auto-generate', onPressed: _generateSku)
                : null,
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Product slug *'),
        const SizedBox(height: 4),
        Text('Generated from the product name. Xerin makes it unique if needed.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _slugController,
          decoration: _inputDecoration(cs, 'product-slug'),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Product description *'),
        const SizedBox(height: 4),
        Text('Explain exactly what the buyer is purchasing, its condition and important features.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          decoration: _inputDecoration(cs, 'Product description'),
          maxLines: 4, maxLength: 5000,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStoreChip(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Uicons.shop, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_storeName ?? 'Loading store...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text('${_storeLocation ?? 'Location not set'} — ${(_storeType ?? 'local').toUpperCase()}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(ColorScheme cs, String? value, List<Map<String, dynamic>> items,
      String idKey, String nameKey, String hint, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(cs, hint),
      items: items.map((item) => DropdownMenuItem<String>(
        value: item[idKey]?.toString(),
        child: Text(item[nameKey]?.toString() ?? '', style: TextStyle(fontSize: 14, color: cs.onSurface)),
      )).toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentStep--),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Back', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                    ),
                  ),
                )
              else
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Cancel', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              if (!isLastStep)
                Expanded(
                  child: GestureDetector(
                    onTap: _isStepValid() ? () => setState(() => _currentStep++) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isStepValid() ? cs.primary : cs.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Next', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: _isStepValid() ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.3))),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _isSaving ? null : () => _save(submit: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Save Draft', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSaving ? null : () => _save(submit: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isSaving
                          ? SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                          : Text('Submit', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onPrimary)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Media ───
  Widget _buildStepMedia(ColorScheme cs) {
    final total = _selectedImages.length + _existingImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(cs, 'Buyer-ready photos', 'Upload up to 10 real product images. JPEG, PNG or WEBP only, max 5 MB each.'),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(Uicons.image, size: 36, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('Drop product images here or browse',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 4),
                Text('JPEG, PNG, WEBP · max 5 MB each',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('$total / 10 images selected',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Text('The first uploaded image becomes the primary image.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.35))),
        const SizedBox(height: 12),
        ..._existingImages.asMap().entries.map((e) =>
          _buildImageTile(cs, e.value, true, e.key == 0, () => setState(() => _existingImages.removeAt(e.key)))),
        ..._selectedImages.asMap().entries.map((e) =>
          _buildImageTile(cs, e.value.path, false, e.key == 0 && _existingImages.isEmpty,
            () => setState(() => _selectedImages.removeAt(e.key)))),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildImageTile(ColorScheme cs, String path, bool isExisting, bool isPrimary, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isExisting
                ? Image.network(path, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 56, height: 56, color: cs.onSurface.withValues(alpha: 0.06),
                      child: Icon(Uicons.image, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
                    ))
                : Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('Primary', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cs.primary)),
                  )
                else
                  Text(isExisting ? 'Existing image' : 'New image',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Uicons.trash, size: 14, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Pricing ───
  Widget _buildStepPricing(ColorScheme cs) {
    final basePrice = double.tryParse(_priceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    const commissionRate = 0.02;
    final commission = basePrice * commissionRate;
    final customerPrice = basePrice + commission;
    final customerSale = salePrice > 0 ? salePrice + (salePrice * commissionRate) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(cs, 'Price & commission', 'Enter the amount you want to receive. Xerin calculates commission and customer price.'),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Currency *'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCurrency,
          decoration: _inputDecoration(cs, 'Select currency'),
          items: _currencies.map((c) => DropdownMenuItem(value: c,
            child: Text(c, style: TextStyle(fontSize: 14, color: cs.onSurface)))).toList(),
          onChanged: (val) => setState(() => _selectedCurrency = val ?? 'TZS'),
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Your base price *'),
        const SizedBox(height: 4),
        Text('The amount you want for this product before Xerin marketplace commission.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _priceController,
          decoration: _inputDecoration(cs, '0.00'),
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Your promotional base price'),
        const SizedBox(height: 4),
        Text('Optional seller price before commission. Must be lower than your regular base price.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _salePriceController,
          decoration: _inputDecoration(cs, 'Optional'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Weight (kg)'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _weightController,
          decoration: _inputDecoration(cs, 'e.g. 0.75'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        // Pricing preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Uicons.chartSimple, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text('Marketplace pricing preview',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Calculated from the active commission rule. Final amount is recalculated by backend.',
                style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.35))),
              const SizedBox(height: 14),
              _buildPreviewRow(cs, 'Your base price', _formatMoney(basePrice, _selectedCurrency), cs.onSurface),
              _buildPreviewRow(cs, 'Commission', '2% · ${_formatMoney(commission, _selectedCurrency)}', cs.onSurface.withValues(alpha: 0.5)),
              const Divider(height: 20),
              _buildPreviewRow(cs, 'Customer regular price', _formatMoney(customerPrice, _selectedCurrency), cs.primary, bold: true),
              if (customerSale > 0)
                _buildPreviewRow(cs, 'Customer sale price', _formatMoney(customerSale, _selectedCurrency), const Color(0xFF22C55E), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Broker promotion toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Allow Brokers to promote this product?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  ),
                  Switch(value: _brokerPromotion, onChanged: (v) => setState(() => _brokerPromotion = v), activeThumbColor: cs.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text('The opportunity becomes visible only when the product is approved, active and in stock.',
                style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviewRow(ColorScheme cs, String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Step 4: Stock ───
  Widget _buildStepStock(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(cs, 'Opening inventory', 'Set your starting stock quantity for this product.'),
        const SizedBox(height: 16),
        _buildLabel(cs, 'Opening stock quantity'),
        const SizedBox(height: 4),
        Text('Enter the number of units you currently have in stock. You can manage inventory later.',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 6),
        TextFormField(
          controller: _stockController,
          decoration: _inputDecoration(cs, '0'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        // Ownership & review info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Uicons.shieldCheck, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 8),
                  Text('Product ownership & review',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 8),
              Text('This product is automatically owned by your seller account. You can save it as a draft, or submit it for Admin review. Products become visible to customers only after approval.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatMoney(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  Widget _buildLabel(ColorScheme cs, String text) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)));
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
