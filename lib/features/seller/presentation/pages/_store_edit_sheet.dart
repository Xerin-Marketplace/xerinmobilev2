import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';

class StoreEditSheet extends StatefulWidget {
  final Map<String, dynamic>? store;
  final VoidCallback onSaved;

  const StoreEditSheet({super.key, this.store, required this.onSaved});

  @override
  State<StoreEditSheet> createState() => _StoreEditSheetState();
}

class _StoreEditSheetState extends State<StoreEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _websiteController;
  late final TextEditingController _descController;
  late final TextEditingController _countryController;
  late final TextEditingController _streetController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  String? _selectedRegion;
  String? _selectedDistrict;
  String? _selectedWard;
  bool _gpsLoading = false;
  bool _gpsConfirmed = false;
  XFile? _pickedLogo;
  String? _logoUrl;
  bool _isSaving = false;
  late bool _isEdit;

  static const _tzRegions = [
    'Dar es Salaam', 'Dodoma', 'Arusha', 'Mwanza', 'Mbeya', 'Zanzibar',
    'Tanga', 'Morogoro', 'Kilimanjaro', 'Tabora', 'Kigoma', 'Ruvuma',
    'Lindi', 'Mtwara', 'Pwani', 'Kagera', 'Geita', 'Simiyu', 'Shinyanga',
    'Singida', 'Iringa', 'Njombe', 'Rukwa', 'Katavi', 'Songwe', 'Manyara',
  ];

  static const _tzDistricts = [
    'Ilala', 'Kinondoni', 'Ubungo', 'Temeke', 'Kigamboni', 'Bagamoyo',
    'Kibaha', 'Chalinze', 'Arusha City', 'Arusha DC', 'Meru', 'Karatu',
    'Mwanza City', 'Nyamagana', 'Ilemela', 'Mbeya City', 'Mbeya DC',
    'Zanzibar Urban', 'Zanzibar West', 'Tanga City', 'Muheza', 'Korogwe',
  ];

  static const _tzWards = [
    'Mchikichini', 'Kariakoo', 'Gerezani', 'Kisutu', 'Upanga', 'Magomeni',
    'Manzese', 'Tandale', 'Makumbusho', 'Mikocheni', 'Msasani', 'Oysterbay',
    'Sinza', 'Mabibo', 'Hananasif', 'Makurumla', 'Ndugumi', 'Kimara',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.store ?? {};
    _isEdit = widget.store != null;
    _nameController = TextEditingController(text: s['store_name']?.toString() ?? s['name']?.toString() ?? '');
    _slugController = TextEditingController(text: s['slug']?.toString() ?? '');
    _emailController = TextEditingController(text: s['contact_email']?.toString() ?? s['email']?.toString() ?? '');
    _phoneController = TextEditingController(text: s['contact_phone']?.toString() ?? s['phone']?.toString() ?? '');
    _whatsappController = TextEditingController(text: s['whatsapp_phone']?.toString() ?? '');
    _websiteController = TextEditingController(text: s['website_url']?.toString() ?? '');
    _descController = TextEditingController(text: s['description']?.toString() ?? '');
    _countryController = TextEditingController(text: s['country']?.toString() ?? 'Tanzania');
    _selectedRegion = s['region']?.toString();
    _selectedDistrict = s['district']?.toString();
    _selectedWard = s['ward']?.toString();
    _streetController = TextEditingController(text: s['street']?.toString() ?? '');
    _latController = TextEditingController(text: s['pickup_latitude']?.toString() ?? s['latitude']?.toString() ?? '');
    _lngController = TextEditingController(text: s['pickup_longitude']?.toString() ?? s['longitude']?.toString() ?? '');
    _gpsConfirmed = _latController.text.isNotEmpty && _lngController.text.isNotEmpty;
    _logoUrl = s['logo_url']?.toString();
    _nameController.addListener(_generateSlug);
  }

  void _generateSlug() {
    if (!_isEdit && _nameController.text.isNotEmpty) {
      _slugController.text = _nameController.text.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
          .replaceAll(RegExp(r'[\s]+'), '-')
          .replaceAll(RegExp(r'-+'), '-');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    _descController.dispose();
    _countryController.dispose();
    _streetController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enable location services first'), backgroundColor: Color(0xFFEF4444)),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied'), backgroundColor: Color(0xFFEF4444)),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
        _gpsConfirmed = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final url = lat != null && lng != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        : 'https://www.google.com/maps';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _confirmCoordinates() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    setState(() => _gpsConfirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates confirmed'), backgroundColor: Color(0xFF22C55E)),
    );
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _pickedLogo = image);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store name is required'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    if (!_gpsConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm pickup GPS coordinates first'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'store_name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'contact_email': _emailController.text.trim(),
        'contact_phone': _phoneController.text.trim(),
        'whatsapp_phone': _whatsappController.text.trim(),
        'website_url': _websiteController.text.trim(),
        'country': _countryController.text.trim(),
        if (_selectedRegion != null) 'region': _selectedRegion,
        if (_selectedDistrict != null) 'district': _selectedDistrict,
        if (_selectedWard != null) 'ward': _selectedWard,
        'street': _streetController.text.trim(),
        'pickup_latitude': double.tryParse(_latController.text),
        'pickup_longitude': double.tryParse(_lngController.text),
      };

      if (_isEdit) {
        await context.read<SellerCubit>().updateStore(data);
      } else {
        await context.read<SellerCubit>().createStore(data);
      }
      if (_pickedLogo != null && mounted) {
        await context.read<SellerCubit>().uploadStoreLogo(_pickedLogo!.path);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
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
    final resolvedLogo = _pickedLogo != null ? null : ApiConstants.resolveImageUrl(_logoUrl);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreInfoSection(cs),
                    const SizedBox(height: 28),
                    _buildLocationSection(cs),
                    const SizedBox(height: 28),
                    _buildGpsSection(cs),
                    const SizedBox(height: 28),
                    _buildLogoSection(cs, resolvedLogo),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildFooter(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(_isEdit ? 'Manage Store' : 'Add Store',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface))),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Uicons.crossSmall, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Store Information', 'The public identity and support contacts for this store.'),
        const SizedBox(height: 14),
        _label(cs, 'Store name *'),
        _field(_nameController, 'Enter store name', cs),
        const SizedBox(height: 12),
        _label(cs, 'Store slug'),
        _field(_slugController, 'Generated after store creation', cs, enabled: false),
        const SizedBox(height: 12),
        _label(cs, 'Support email'),
        _field(_emailController, 'support@store.com', cs, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _label(cs, 'Support phone'),
        _field(_phoneController, '+255...', cs, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _label(cs, 'WhatsApp phone'),
        _field(_whatsappController, '+255...', cs, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        _label(cs, 'Website'),
        _field(_websiteController, 'https://example.com', cs, keyboardType: TextInputType.url),
        const SizedBox(height: 12),
        _label(cs, 'Store description'),
        _field(_descController, 'Tell customers about this store...', cs, maxLines: 3),
      ],
    );
  }

  Widget _buildLocationSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Store Location', 'The physical origin of products sold from this store.'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Uicons.info, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Tanzania is LOCAL. Any country outside Tanzania is GLOBAL. The backend verifies this automatically.',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('LOCAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
        ),
        const SizedBox(height: 14),
        _label(cs, 'Country *'),
        _field(_countryController, 'Tanzania', cs),
        const SizedBox(height: 12),
        _label(cs, 'Region'),
        _dropdown(cs, _selectedRegion, _tzRegions, 'Select official region',
            (v) => setState(() => _selectedRegion = v)),
        const SizedBox(height: 12),
        _label(cs, 'District / Municipality'),
        _dropdown(cs, _selectedDistrict, _tzDistricts, 'Select district / municipality',
            (v) => setState(() => _selectedDistrict = v)),
        const SizedBox(height: 12),
        _label(cs, 'Ward'),
        _dropdown(cs, _selectedWard, _tzWards, 'Select ward',
            (v) => setState(() => _selectedWard = v)),
        const SizedBox(height: 12),
        _label(cs, 'Street / physical address'),
        _field(_streetController, 'Building, road, block, shop number...', cs),
      ],
    );
  }

  Widget _buildGpsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Store shipping origin / pickup map point *',
          'Logistics distance starts from this exact store. Set the warehouse/shop where products are collected.'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _gpsLoading ? null : _useCurrentLocation,
                icon: _gpsLoading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                    : Icon(Uicons.location, size: 16, color: cs.primary),
                label: const Text('Use current location', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openGoogleMaps,
                icon: Icon(Uicons.map, size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                label: const Text('Google Maps', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label(cs, 'Manual coordinates'),
        Row(
          children: [
            Expanded(child: _field(_latController, 'Latitude e.g. -6.8235', cs, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            const SizedBox(width: 10),
            Expanded(child: _field(_lngController, 'Longitude e.g. 39.2695', cs, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _confirmCoordinates,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: _gpsConfirmed ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.2)),
            ),
            child: Text(_gpsConfirmed ? 'Coordinates confirmed' : 'Confirm coordinates',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: _gpsConfirmed ? const Color(0xFF22C55E) : cs.onSurface.withValues(alpha: 0.6))),
          ),
        ),
        if (!_gpsConfirmed) ...[
          const SizedBox(height: 8),
          Text('Checkout will block logistics pricing until you confirm a pickup point.',
            style: TextStyle(fontSize: 11, color: const Color(0xFFF59E0B).withValues(alpha: 0.8))),
        ],
      ],
    );
  }

  Widget _buildLogoSection(ColorScheme cs, String? resolvedLogo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(cs, 'Store Logo', 'Choose a logo for this store. It uploads after the store is created.'),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pickedLogo != null
                      ? Image.file(File(_pickedLogo!.path), width: 64, height: 64, fit: BoxFit.cover)
                      : resolvedLogo != null
                          ? Image.network(resolvedLogo, width: 64, height: 64, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(Uicons.shop, size: 32, color: cs.onSurface.withValues(alpha: 0.3)))
                          : Icon(Uicons.shop, size: 32, color: cs.onSurface.withValues(alpha: 0.3)),
                ),
                const SizedBox(height: 10),
                Text('Choose logo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                const SizedBox(height: 2),
                Text('JPG, PNG or WebP', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme cs) {
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
                  : Text(_isEdit ? 'Save Changes' : 'Create Store', style: const TextStyle(fontWeight: FontWeight.w600)),
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
        const SizedBox(height: 4),
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

  Widget _dropdown(ColorScheme cs, String? value, List<String> items, String hint, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDeco(cs, hint),
      items: items.map((e) => DropdownMenuItem(value: e,
        child: Text(e, style: TextStyle(fontSize: 14, color: cs.onSurface)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _field(TextEditingController controller, String hint, ColorScheme cs,
      {int maxLines = 1, TextInputType? keyboardType, bool enabled = true}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: _inputDeco(cs, hint),
    );
  }

  InputDecoration _inputDeco(ColorScheme cs, String hint) {
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
