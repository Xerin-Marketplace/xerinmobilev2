import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/uicons.dart';

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

  void _showAddEditSheet({AddressModel? address}) {
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
    double? savedLatitude = address?.latitude;
    double? savedLongitude = address?.longitude;
    bool isFetchingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cs = Theme.of(context).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
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
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(address == null ? 'Add Address' : 'Edit Address',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                      const SizedBox(height: 16),
                      // Use Current Location button
                      _buildUseLocationButton(cs, setModalState, () async {
                        setModalState(() => isFetchingLocation = true);
                        try {
                          final location = await GetIt.instance<LocationService>().getCurrentLocation();
                          setModalState(() {
                            if (location.country != null) countryCtrl.text = location.country!;
                            if (location.region != null) regionCtrl.text = location.region!;
                            if (location.city != null) cityCtrl.text = location.city!;
                            if (location.street != null) streetCtrl.text = location.street!;
                            if (location.postalCode != null) postalCtrl.text = location.postalCode!;
                            if (location.landmark != null) landmarkCtrl.text = location.landmark!;
                            savedLatitude = location.latitude;
                            savedLongitude = location.longitude;
                            isFetchingLocation = false;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Location found: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                                backgroundColor: const Color(0xFF22C55E),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isFetchingLocation = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: const Color(0xFFE53935),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      }, isFetchingLocation),
                      const SizedBox(height: 16),
                      _bottomField('Label (e.g. Home, Work)', labelCtrl, cs, required: false),
                      const SizedBox(height: 12),
                      _bottomField('Recipient Name', recipientNameCtrl, cs, required: false),
                      const SizedBox(height: 12),
                      _bottomField('Recipient Phone', recipientPhoneCtrl, cs, required: false),
                      const SizedBox(height: 12),
                      _bottomField('Country', countryCtrl, cs),
                      const SizedBox(height: 12),
                      _bottomField('Region', regionCtrl, cs),
                      const SizedBox(height: 12),
                      _bottomField('City', cityCtrl, cs),
                      const SizedBox(height: 12),
                      _bottomField('Street', streetCtrl, cs),
                      const SizedBox(height: 12),
                      _bottomField('Landmark (optional)', landmarkCtrl, cs, required: false),
                      const SizedBox(height: 12),
                      _bottomField('Postal Code (optional)', postalCtrl, cs, required: false),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx);
                              if (address != null) {
                                context.read<CustomerCubit>().updateAddress(
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
                                  latitude: savedLatitude,
                                  longitude: savedLongitude,
                                  isDefault: address.isDefault,
                                );
                              } else {
                                context.read<CustomerCubit>().addAddress(
                                  country: countryCtrl.text.trim(),
                                  region: regionCtrl.text.trim(),
                                  city: cityCtrl.text.trim(),
                                  street: streetCtrl.text.trim(),
                                  postalCode: postalCtrl.text.trim().isEmpty ? null : postalCtrl.text.trim(),
                                  label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                                  recipientName: recipientNameCtrl.text.trim().isEmpty ? null : recipientNameCtrl.text.trim(),
                                  recipientPhone: recipientPhoneCtrl.text.trim().isEmpty ? null : recipientPhoneCtrl.text.trim(),
                                  landmark: landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
                                  latitude: savedLatitude,
                                  longitude: savedLongitude,
                                  isDefault: false,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(address == null ? 'Add Address' : 'Save Changes',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
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

  Widget _buildUseLocationButton(ColorScheme cs, StateSetter setModalState, Future<void> Function() onTap, bool isFetching) {
    return GestureDetector(
      onTap: isFetching ? null : () => onTap(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFetching)
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                ),
              )
            else
              Icon(Uicons.mapPin, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              isFetching ? 'Detecting location...' : 'Use My Current Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomField(String label, TextEditingController controller, ColorScheme cs, {bool required = true}) {
    return TextFormField(
      controller: controller,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            final addresses = state is CustomerLoaded ? state.addresses : <AddressModel>[];
            final isLoading = state is CustomerLoading;

            return Column(
              children: [
                _buildHeader(colorScheme),
                if (isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (addresses.isEmpty)
                  _buildEmptyState(colorScheme)
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return _buildAddressCard(address, colorScheme, isDark);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: colorScheme.primary,
        child: const Icon(Uicons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Text('Addresses',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Uicons.mapPin, size: 38, color: cs.primary.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 20),
            Text('No addresses yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text('Add a delivery address to get started',
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditSheet(),
              icon: const Icon(Uicons.add, size: 18),
              label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: address.isDefault
              ? cs.primary.withValues(alpha: 0.3)
              : cs.onSurface.withValues(alpha: 0.06),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Uicons.mapPin, color: cs.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (address.label != null && address.label!.isNotEmpty) ...[
                            Text(address.label!,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Default',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF22C55E)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address.fullAddress,
                        style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (address.recipientName != null && address.recipientName!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Row(
                  children: [
                    Icon(Uicons.user, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(width: 4),
                    Text(address.recipientName!,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                    if (address.recipientPhone != null && address.recipientPhone!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(Uicons.phone, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                      Text(address.recipientPhone!,
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAddEditSheet(address: address),
                  icon: Icon(Uicons.edit, size: 15, color: cs.onSurface.withValues(alpha: 0.4)),
                  label: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
                ),
                TextButton.icon(
                  onPressed: () => context.read<CustomerCubit>().deleteAddress(address.id),
                  icon: Icon(Uicons.trash, size: 15, color: const Color(0xFFE53935)),
                  label: Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFE53935))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
