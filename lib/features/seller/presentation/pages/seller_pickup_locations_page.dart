import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/uicons.dart';
import '../../data/models/pickup_location_model.dart';
import '../cubit/seller_cubit.dart';

class SellerPickupLocationsPage extends StatefulWidget {
  const SellerPickupLocationsPage({super.key});

  @override
  State<SellerPickupLocationsPage> createState() => _SellerPickupLocationsPageState();
}

class _SellerPickupLocationsPageState extends State<SellerPickupLocationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadPickupLocations();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Uicons.angleLeft), onPressed: () => context.pop()),
        title: const Text('Pickup Locations'),
      ),
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
          }
        },
        builder: (context, state) {
          if (state is SellerLoading) {
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
                    onPressed: () => context.read<SellerCubit>().loadPickupLocations(),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          if (state is SellerPickupLocationsLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadPickupLocations(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Header
                  Text('Pickup Locations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text('Logistics distance and readiness checks use your active default pickup location, exact GPS pin, contact name and phone.',
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 20),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showForm(context),
                      icon: const Icon(Uicons.plus, size: 18),
                      label: const Text('Add pickup location', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List
                  if (state.locations.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(Uicons.mapMarker, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                            const SizedBox(height: 16),
                            Text('No pickup locations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                            const SizedBox(height: 8),
                            Text('Add a pickup location so logistics partners know where to collect orders.',
                              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                              textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  else
                    ...state.locations.map((loc) => _buildLocationCard(context, cs, loc)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, ColorScheme cs, PickupLocationModel loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: label + badges
            Row(
              children: [
                Icon(Uicons.mapMarker, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ),
                if (loc.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('DEFAULT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary)),
                  ),
                if (!loc.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF9CA3AF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Text('INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Address
            Text(loc.formattedAddress, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text('${loc.city}, ${loc.region}, ${loc.country}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 10),
            // Contact
            Row(
              children: [
                Icon(Uicons.user, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(loc.pickupContactName, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(width: 12),
                Icon(Uicons.phone, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text(loc.pickupPhone, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
            const SizedBox(height: 6),
            // GPS
            Row(
              children: [
                Icon(Uicons.location, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                Text('${loc.latitude}, ${loc.longitude}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
            const SizedBox(height: 14),
            // Actions
            Row(
              children: [
                if (!loc.isDefault)
                  TextButton.icon(
                    onPressed: () => context.read<SellerCubit>().setDefaultPickupLocation(loc.id),
                    icon: Icon(Uicons.star, size: 16, color: cs.primary),
                    label: Text('Set default', style: TextStyle(fontSize: 13, color: cs.primary)),
                  ),
                const Spacer(),
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
                    if (action == 'edit') _showForm(context, edit: loc);
                    if (action == 'delete') _confirmDelete(context, loc.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String locationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: const Text('Are you sure you want to delete this pickup location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerCubit>().deletePickupLocation(locationId);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {PickupLocationModel? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PickupLocationForm(edit: edit),
    );
  }
}

// ─── Pickup Location Form ───
class _PickupLocationForm extends StatefulWidget {
  final PickupLocationModel? edit;

  const _PickupLocationForm({this.edit});

  @override
  State<_PickupLocationForm> createState() => _PickupLocationFormState();
}

class _PickupLocationFormState extends State<_PickupLocationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  String _country = 'Tanzania';
  bool _isSaving = false;
  bool _gpsLoading = false;
  bool _gpsConfirmed = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _addressCtrl = TextEditingController(text: e?.formattedAddress ?? '');
    _contactCtrl = TextEditingController(text: e?.pickupContactName ?? '');
    _phoneCtrl = TextEditingController(text: e?.pickupPhone ?? '');
    _instructionsCtrl = TextEditingController(text: e?.pickupInstructions ?? '');
    _latCtrl = TextEditingController(text: e?.latitude ?? '');
    _lngCtrl = TextEditingController(text: e?.longitude ?? '');
    if (e != null) _country = e.country;
    _gpsConfirmed = _latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty && _latCtrl.text != '0' && _lngCtrl.text != '0';
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _instructionsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
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
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
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
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    final url = lat != null && lng != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        : 'https://www.google.com/maps';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_gpsConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm GPS coordinates first'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      'label': _labelCtrl.text.trim(),
      'formatted_address': _addressCtrl.text.trim(),
      'country': _country,
      'region': '',
      'city': '',
      'pickup_contact_name': _contactCtrl.text.trim(),
      'pickup_phone': _phoneCtrl.text.trim(),
      'latitude': _latCtrl.text.trim(),
      'longitude': _lngCtrl.text.trim(),
    };
    if (_instructionsCtrl.text.trim().isNotEmpty) {
      data['pickup_instructions'] = _instructionsCtrl.text.trim();
    }

    final cubit = context.read<SellerCubit>();
    if (widget.edit != null) {
      cubit.updatePickupLocation(widget.edit!.id, data);
    } else {
      cubit.createPickupLocation(data);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.edit != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header
            Container(
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
                        Text(isEdit ? 'Edit pickup location' : 'Add pickup location',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 2),
                        Text('Confirm the exact origin used by logistics.',
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
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location label
                      _label(cs, 'Location label'),
                      _field(_labelCtrl, 'Main pickup', cs),
                      const SizedBox(height: 16),

                      // Search exact pickup point
                      _label(cs, 'Search exact pickup point'),
                      _field(_addressCtrl, 'Building, street or landmark', cs),
                      const SizedBox(height: 16),

                      // GPS section
                      _label(cs, 'Pickup GPS pin *'),
                      Row(
                        children: [
                          Expanded(child: _field(_latCtrl, 'Latitude', cs, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                          const SizedBox(width: 10),
                          Expanded(child: _field(_lngCtrl, 'Longitude', cs, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                                side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
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
                                side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_gpsConfirmed) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Uicons.circleCheck, size: 14, color: const Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            Text('GPS pin confirmed', style: TextStyle(fontSize: 12, color: const Color(0xFF22C55E).withValues(alpha: 0.8))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Contact
                      _label(cs, 'Pickup contact name'),
                      _field(_contactCtrl, 'Contact person', cs),
                      const SizedBox(height: 16),

                      // Phone
                      _label(cs, 'Pickup phone'),
                      _field(_phoneCtrl, '+255...', cs, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),

                      // Instructions
                      _label(cs, 'Pickup instructions (optional)'),
                      _field(_instructionsCtrl, 'Any special instructions for logistics', cs, maxLines: 3),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
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
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEdit ? 'Save pickup location' : 'Save pickup location', style: const TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _label(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
    );
  }

  Widget _field(TextEditingController controller, String hint, ColorScheme cs,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }
}
