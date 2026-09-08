import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/notifications/notification_service.dart';
import 'map_picker_page.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().refreshAddresses();
    });
  }

  void _showForm({AddressModel? address}) {
    final isEdit = address != null;
    final countryCtrl = TextEditingController(text: address?.country ?? 'Tanzania');
    final regionCtrl = TextEditingController(text: address?.region ?? '');
    final cityCtrl = TextEditingController(text: address?.city ?? '');
    final streetCtrl = TextEditingController(text: address?.street ?? '');
    final postalCtrl = TextEditingController(text: address?.postalCode ?? '');
    final labelCtrl = TextEditingController(text: address?.label ?? '');
    final recipientNameCtrl = TextEditingController(text: address?.recipientName ?? '');
    final recipientPhoneCtrl = TextEditingController(text: address?.recipientPhone ?? '');
    final landmarkCtrl = TextEditingController(text: address?.landmark ?? '');
    final formKey = GlobalKey<FormState>();
    double? savedLat = address?.latitude;
    double? savedLng = address?.longitude;
    bool isLocating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cs = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isEdit ? 'Edit Address' : 'Add Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isLocating)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                setModalState(() => isLocating = true);
                                try {
                                  final loc = await GetIt.instance<LocationService>().getCurrentLocation();
                                  setModalState(() {
                                    if (loc.country != null) countryCtrl.text = loc.country!;
                                    if (loc.region != null) regionCtrl.text = loc.region!;
                                    if (loc.city != null) cityCtrl.text = loc.city!;
                                    if (loc.street != null) streetCtrl.text = loc.street!;
                                    if (loc.postalCode != null) postalCtrl.text = loc.postalCode!;
                                    if (loc.landmark != null) landmarkCtrl.text = loc.landmark!;
                                    savedLat = loc.latitude;
                                    savedLng = loc.longitude;
                                    isLocating = false;
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Location detected'),
                                        backgroundColor: const Color(0xFF22C55E),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isLocating = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                                        backgroundColor: const Color(0xFFE53935),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text('Use GPS'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(ctx).push<MapPickerResult>(
                                  MaterialPageRoute(
                                    builder: (_) => MapPickerPage(
                                      initialLatitude: savedLat,
                                      initialLongitude: savedLng,
                                      initialAddress: streetCtrl.text.isNotEmpty
                                          ? '${streetCtrl.text}, ${cityCtrl.text}, ${regionCtrl.text}'
                                          : null,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setModalState(() {
                                    savedLat = result.latitude;
                                    savedLng = result.longitude;
                                    if (result.country != null) countryCtrl.text = result.country!;
                                    if (result.region != null) regionCtrl.text = result.region!;
                                    if (result.city != null) cityCtrl.text = result.city!;
                                    if (result.street != null) streetCtrl.text = result.street!;
                                    if (result.postalCode != null) postalCtrl.text = result.postalCode!;
                                    if (result.district != null) {}
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text('Location selected from map'),
                                        backgroundColor: Color(0xFF22C55E),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text('Select on Map'),
                            ),
                          ],
                        ),
                      if (isLocating)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      if (savedLat != null && savedLng != null && !isLocating)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 16, color: const Color(0xFF22C55E)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${savedLat!.toStringAsFixed(6)}, ${savedLng!.toStringAsFixed(6)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6), fontFamily: 'monospace'),
                                ),
                              ),
                              const Text('GPS Set',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      _field('Label (e.g. Home, Work)', labelCtrl, cs, required: false),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field('Recipient Name', recipientNameCtrl, cs, required: false)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Recipient Phone', recipientPhoneCtrl, cs, required: false)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Country', countryCtrl, cs),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field('Region', regionCtrl, cs)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('City', cityCtrl, cs)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field('Street', streetCtrl, cs),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _field('Landmark', landmarkCtrl, cs, required: false)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Postal Code', postalCtrl, cs, required: false)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(ctx);
                                  final cubit = context.read<CustomerCubit>();
                                  if (isEdit) {
                                    cubit.updateAddress(
                                      addressId: address.id,
                                      country: countryCtrl.text.trim(),
                                      region: regionCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      street: streetCtrl.text.trim(),
                                      postalCode: postalCtrl.text.trim().isEmpty ? null : postalCtrl.text.trim(),
                                      label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                                      recipientName: recipientNameCtrl.text.trim().isEmpty ? null : recipientNameCtrl.text.trim(),
                                      recipientPhone: recipientPhoneCtrl.text.trim().isEmpty ? null : recipientPhoneCtrl.text.trim(),
                                      landmark: landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
                                      latitude: savedLat,
                                      longitude: savedLng,
                                      isDefault: address.isDefault,
                                    );
                                  } else {
                                    cubit.addAddress(
                                      country: countryCtrl.text.trim(),
                                      region: regionCtrl.text.trim(),
                                      city: cityCtrl.text.trim(),
                                      street: streetCtrl.text.trim(),
                                      postalCode: postalCtrl.text.trim().isEmpty ? null : postalCtrl.text.trim(),
                                      label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                                      recipientName: recipientNameCtrl.text.trim().isEmpty ? null : recipientNameCtrl.text.trim(),
                                      recipientPhone: recipientPhoneCtrl.text.trim().isEmpty ? null : recipientPhoneCtrl.text.trim(),
                                      landmark: landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
                                      latitude: savedLat,
                                      longitude: savedLng,
                                      isDefault: false,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(isEdit ? 'Save' : 'Add'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(String label, TextEditingController controller, ColorScheme cs, {bool required = true}) {
    return TextFormField(
      controller: controller,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        actions: [
          IconButton(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final addresses = state is CustomerLoaded ? state.addresses : <AddressModel>[];

          if (addresses.isEmpty) {
            return _buildEmptyState(cs);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: addresses.length,
            itemBuilder: (context, index) => _buildAddressCard(addresses[index], cs),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off_outlined, size: 36, color: cs.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 16),
            Text('No delivery addresses yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 6),
            Text('Add an address with GPS coordinates so\nlogistics knows exactly where to deliver',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4), height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel a, ColorScheme cs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasGps = a.hasGps;
    final isVerified = a.isVerified;
    final isReady = a.deliveryReady;

    IconData labelIcon;
    Color labelColor;
    switch (a.label?.toLowerCase()) {
      case 'home':
        labelIcon = Icons.home_outlined;
        labelColor = const Color(0xFF6366F1);
        break;
      case 'work':
        labelIcon = Icons.work_outline;
        labelColor = const Color(0xFF0EA5E9);
        break;
      default:
        labelIcon = Icons.location_on_outlined;
        labelColor = cs.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : cs.onSurface.withValues(alpha: 0.08),
          width: isReady ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: labelColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(labelIcon, size: 22, color: labelColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (a.label != null && a.label!.isNotEmpty)
                            Text(a.label!,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                            ),
                          if (a.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text('Default',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E)),
                              ),
                            ),
                          ],
                          const Spacer(),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showForm(address: a);
                              } else if (value == 'delete') {
                                _confirmDelete(a);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFE53935)))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(a.fullAddress,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55), height: 1.4),
                      ),
                      if (a.recipientName != null && a.recipientName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 13, color: cs.onSurface.withValues(alpha: 0.35)),
                            const SizedBox(width: 4),
                            Text(a.recipientName!,
                              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                            ),
                            if (a.recipientPhone != null && a.recipientPhone!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.phone_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.35)),
                              const SizedBox(width: 4),
                              Text(a.recipientPhone!,
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _buildStatusChip(
                  icon: hasGps ? Icons.gps_fixed : Icons.gps_off,
                  label: hasGps ? 'GPS Set' : 'No GPS',
                  color: hasGps ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  cs: cs,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  icon: isVerified ? Icons.verified : Icons.pending,
                  label: isVerified ? 'Verified' : 'Unverified',
                  color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  cs: cs,
                ),
                const Spacer(),
                if (!isVerified && hasGps)
                  GestureDetector(
                    onTap: () => _confirmMapPin(a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop, size: 13, color: cs.primary),
                          const SizedBox(width: 4),
                          Text('Confirm Pin',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!hasGps)
                  GestureDetector(
                    onTap: () => _showForm(address: a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location, size: 13, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text('Add GPS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasGps)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  Text(a.coordinates,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  if (isReady)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 13, color: const Color(0xFF22C55E).withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text('Delivery Ready',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF22C55E).withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
    required ColorScheme cs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _confirmMapPin(AddressModel address) {
    bool isConfirming = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cs = Theme.of(ctx).colorScheme;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.pin_drop, size: 20, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Confirm Delivery Pin',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface),
                              ),
                              Text('Verify your exact delivery location',
                                style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(address.fullAddress,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                          if (address.hasGps) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.my_location, size: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                                const SizedBox(width: 6),
                                Text(address.coordinates,
                                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5), fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Confirm your exact delivery point. You can use your current GPS or manually select on the map. Xerin will reverse-geocode the coordinates server-side to verify the address.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    if (!isConfirming) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                setModalState(() => isConfirming = true);
                                try {
                                  final loc = await GetIt.instance<LocationService>().getCurrentLocation();
                                  if (!ctx.mounted) return;
                                  final cubit = ctx.read<CustomerCubit>();
                                  final success = await cubit.confirmMapPin(
                                    addressId: address.id,
                                    latitude: loc.latitude,
                                    longitude: loc.longitude,
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (success) {
                                    NotificationService().success('Delivery pin confirmed! Address is now verified.');
                                  }
                                } catch (e) {
                                  setModalState(() => isConfirming = false);
                                  if (ctx.mounted) {
                                    NotificationService().error(e.toString().replaceFirst('Exception: ', ''));
                                  }
                                }
                              },
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text('Use GPS', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.of(ctx).push<MapPickerResult>(
                              MaterialPageRoute(
                                builder: (_) => MapPickerPage(
                                  initialLatitude: address.latitude,
                                  initialLongitude: address.longitude,
                                  initialAddress: address.fullAddress,
                                ),
                              ),
                            );
                            if (result == null) return;
                            setModalState(() => isConfirming = true);
                            try {
                              if (!ctx.mounted) return;
                              final cubit = ctx.read<CustomerCubit>();
                              final success = await cubit.confirmMapPin(
                                addressId: address.id,
                                latitude: result.latitude,
                                longitude: result.longitude,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (success) {
                                NotificationService().success('Delivery pin confirmed! Address is now verified.');
                              }
                            } catch (e) {
                              setModalState(() => isConfirming = false);
                              if (ctx.mounted) {
                                NotificationService().error(e.toString().replaceFirst('Exception: ', ''));
                              }
                            }
                          },
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Select on Map', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircularProgressIndicator(strokeWidth: 2.5),
                              SizedBox(height: 12),
                              Text('Confirming delivery location...', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(AddressModel address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CustomerCubit>().deleteAddress(address.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
