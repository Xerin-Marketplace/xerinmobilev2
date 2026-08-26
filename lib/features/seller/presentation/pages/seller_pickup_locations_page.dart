import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../data/models/pickup_location_model.dart';
import '../../presentation/cubit/seller_cubit.dart';

class SellerPickupLocationsPage extends StatefulWidget {
  const SellerPickupLocationsPage({super.key});

  @override
  State<SellerPickupLocationsPage> createState() =>
      _SellerPickupLocationsPageState();
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
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pickup Locations'),
      ),
      body: SafeArea(
        child: BlocConsumer<SellerCubit, SellerState>(
          listener: (context, state) {
            if (state is SellerError) {
              NotificationService().error(state.message);
            }
            if (state is SellerActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is SellerLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SellerPickupLocationsLoaded) {
              if (state.locations.isEmpty) {
                return _buildEmpty(cs);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<SellerCubit>().loadPickupLocations(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.locations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _LocationCard(
                    location: state.locations[index],
                    onSetDefault: (id) => context
                        .read<SellerCubit>()
                        .setDefaultPickupLocation(id),
                    onDelete: (id) =>
                        _confirmDelete(context, id),
                  ),
                ),
              );
            }
            return _buildEmpty(cs);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Uicons.plus),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.mapMarker,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Pickup Locations',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Add pickup locations so logistics partners know where to collect orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddEditDialog(context),
              icon: const Icon(Uicons.plus),
              label: const Text('Add Location'),
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
        content: const Text(
            'Are you sure you want to delete this pickup location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerCubit>().deletePickupLocation(locationId);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {PickupLocationModel? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickupLocationForm(edit: edit),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final PickupLocationModel location;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onDelete;

  const _LocationCard({
    required this.location,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Uicons.mapMarker, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (location.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                if (!location.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.formattedAddress,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              '${location.city}, ${location.region}, ${location.country}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Uicons.user, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  location.pickupContactName,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 12),
                Icon(Uicons.phone, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  location.pickupPhone,
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!location.isDefault)
                  TextButton.icon(
                    onPressed: () => onSetDefault(location.id),
                    icon: const Icon(Uicons.star, size: 16),
                    label: const Text('Set Default'),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Uicons.edit, size: 18),
                  onPressed: () => _showEditDialog(context),
                ),
                IconButton(
                  icon: const Icon(Uicons.trash, size: 18),
                  color: Colors.red,
                  onPressed: () => onDelete(location.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PickupLocationForm(edit: location),
    );
  }
}

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
  late final TextEditingController _regionCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  String _country = 'Tanzania';

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _addressCtrl = TextEditingController(text: e?.formattedAddress ?? '');
    _regionCtrl = TextEditingController(text: e?.region ?? '');
    _cityCtrl = TextEditingController(text: e?.city ?? '');
    _contactCtrl = TextEditingController(text: e?.pickupContactName ?? '');
    _phoneCtrl = TextEditingController(text: e?.pickupPhone ?? '');
    _instructionsCtrl = TextEditingController(text: e?.pickupInstructions ?? '');
    _latCtrl = TextEditingController(text: e?.latitude ?? '');
    _lngCtrl = TextEditingController(text: e?.longitude ?? '');
    if (e != null) _country = e.country;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _regionCtrl.dispose();
    _cityCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _instructionsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'label': _labelCtrl.text.trim(),
      'formatted_address': _addressCtrl.text.trim(),
      'country': _country,
      'region': _regionCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
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
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Pickup Location' : 'Add Pickup Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _field(cs, 'Label', _labelCtrl, 'e.g. Main warehouse'),
              const SizedBox(height: 12),
              _field(cs, 'Formatted Address *', _addressCtrl,
                  'Full street address'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(cs, 'Region *', _regionCtrl, 'Dar es Salaam')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(cs, 'City *', _cityCtrl, 'Kinondoni')),
                ],
              ),
              const SizedBox(height: 12),
              _field(cs, 'Contact Name *', _contactCtrl, 'John Doe'),
              const SizedBox(height: 12),
              _field(cs, 'Contact Phone *', _phoneCtrl, '+2557XXXXXXXX'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(cs, 'Latitude *', _latCtrl, '-6.8235')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(cs, 'Longitude *', _lngCtrl, '39.2695')),
                ],
              ),
              const SizedBox(height: 12),
              _field(cs, 'Pickup Instructions', _instructionsCtrl,
                  'Any special instructions', multiline: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(isEdit ? 'Update Location' : 'Add Location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(ColorScheme cs, String label, TextEditingController ctrl,
      String hint, {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
          maxLines: multiline ? 3 : 1,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }
}
