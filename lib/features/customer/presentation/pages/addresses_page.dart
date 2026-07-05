import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_icon.dart';
import '../../data/models/address_model.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _addresses.addAll(_sampleAddresses);
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove ${address.summary}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _addresses.remove(address));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  BackIconButton(
                    onTap: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Text('Addresses',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_addresses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EmptyStateIcon(icon: Icons.location_off_rounded),
                      const SizedBox(height: 16),
                      Text('No addresses yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text('Add a delivery address',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditSheet(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Address'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return _buildAddressCard(address, colorScheme);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _addresses.isNotEmpty && !_isLoading
          ? FloatingActionButton(
              onPressed: () => _showAddEditSheet(),
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAddressCard(AddressModel address, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconContainer(
                icon: Icons.location_on_rounded,
                color: colorScheme.primary,
                size: 40,
                iconSize: AppIconSize.md,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(address.street,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Default',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(address.fullAddress,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                    if (address.postalCode != null) ...[
                      const SizedBox(height: 2),
                      Text('Postal: ${address.postalCode}',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (int i = 0; i < _addresses.length; i++) {
                        _addresses[i] = AddressModel(
                          id: _addresses[i].id,
                          country: _addresses[i].country,
                          region: _addresses[i].region,
                          city: _addresses[i].city,
                          street: _addresses[i].street,
                          postalCode: _addresses[i].postalCode,
                          isDefault: _addresses[i].id == address.id,
                        );
                      }
                    });
                  },
                  icon: Icon(Icons.star_border_rounded, size: 16, color: colorScheme.primary),
                  label: Text('Set Default', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                ),
              TextButton.icon(
                onPressed: () => _showAddEditSheet(address: address),
                icon: Icon(Icons.edit_outlined, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                label: Text('Edit', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
              TextButton.icon(
                onPressed: () => _deleteAddress(address),
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: const Color(0xFFE53935)),
                label: Text('Delete', style: TextStyle(fontSize: 12, color: const Color(0xFFE53935))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditSheet({AddressModel? address}) {
    final countryCtrl = TextEditingController(text: address?.country ?? '');
    final regionCtrl = TextEditingController(text: address?.region ?? '');
    final cityCtrl = TextEditingController(text: address?.city ?? '');
    final streetCtrl = TextEditingController(text: address?.street ?? '');
    final postalCtrl = TextEditingController(text: address?.postalCode ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Form(
            key: formKey,
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
                const SizedBox(height: 20),
                _bottomField('Country', countryCtrl, cs),
                const SizedBox(height: 12),
                _bottomField('Region', regionCtrl, cs),
                const SizedBox(height: 12),
                _bottomField('City', cityCtrl, cs),
                const SizedBox(height: 12),
                _bottomField('Street', streetCtrl, cs),
                const SizedBox(height: 12),
                _bottomField('Postal Code (optional)', postalCtrl, cs),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final addr = AddressModel(
                          id: address?.id ?? DateTime.now().toString(),
                          country: countryCtrl.text.trim(),
                          region: regionCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          street: streetCtrl.text.trim(),
                          postalCode: postalCtrl.text.trim().isEmpty ? null : postalCtrl.text.trim(),
                          isDefault: address?.isDefault ?? _addresses.isEmpty,
                        );
                        setState(() {
                          if (address != null) {
                            final idx = _addresses.indexWhere((a) => a.id == address.id);
                            if (idx >= 0) _addresses[idx] = addr;
                          } else {
                            _addresses.add(addr);
                          }
                        });
                        Navigator.pop(ctx);
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
        );
      },
    );
  }

  Widget _bottomField(String label, TextEditingController controller, ColorScheme cs) {
    return TextFormField(
      controller: controller,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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

  static const List<AddressModel> _sampleAddresses = [
    AddressModel(id: '1', country: 'Tanzania', region: 'Dar es Salaam', city: 'Kinondoni', street: '123 Mwai Kibaki Rd', postalCode: '14111', isDefault: true),
    AddressModel(id: '2', country: 'Tanzania', region: 'Arusha', city: 'Njiro', street: '45 Old Moshi Rd', postalCode: '23100'),
    AddressModel(id: '3', country: 'Tanzania', region: 'Mwanza', city: 'Nyamagana', street: '78 Kenyatta Rd', postalCode: '33100'),
  ];
}
