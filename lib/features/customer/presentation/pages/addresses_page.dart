import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../../../core/services/location_service.dart';

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
                        Align(
                          child: TextButton.icon(
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
                            label: const Text('Use current location'),
                          ),
                        ),
                      if (isLocating)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
        title: const Text('Addresses'),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_outlined, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('No addresses yet', style: TextStyle(fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 4),
                  Text('Tap + to add a delivery address', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = addresses[index];
              return ListTile(
                leading: Icon(
                  a.label?.toLowerCase() == 'home' ? Icons.home_outlined : Icons.location_on_outlined,
                  color: cs.primary,
                ),
                title: Row(
                  children: [
                    if (a.label != null && a.label!.isNotEmpty)
                      Text(a.label!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (a.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF22C55E))),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(a.fullAddress, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
                trailing: PopupMenuButton<String>(
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
              );
            },
          );
        },
      ),
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
