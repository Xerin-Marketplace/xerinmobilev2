import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminMarketplaceSettingsPage extends StatefulWidget {
  const AdminMarketplaceSettingsPage({super.key});

  @override
  State<AdminMarketplaceSettingsPage> createState() =>
      _AdminMarketplaceSettingsPageState();
}

class _AdminMarketplaceSettingsPageState
    extends State<AdminMarketplaceSettingsPage> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadMarketplaceSettings();
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
        title: const Text('Marketplace Settings'),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is AdminError) {
              NotificationService().error(state.message);
            }
            if (state is AdminActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminMarketplaceSettingsLoaded) {
              return _SettingsForm(settings: state.settings);
            }
            if (!_isReloading) {
              _isReloading = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AdminCubit>().loadMarketplaceSettings();
                _isReloading = false;
              });
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final Map<String, dynamic> settings;

  const _SettingsForm({required this.settings});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController _platformNameCtrl;
  late final TextEditingController _supportEmailCtrl;
  late final TextEditingController _supportPhoneCtrl;
  late final TextEditingController _minOrderCtrl;
  late final TextEditingController _maxOrderCtrl;
  late bool _maintenanceMode;
  late bool _newRegistrations;
  late bool _newSellerRegistrations;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _platformNameCtrl =
        TextEditingController(text: s['platform_name']?.toString() ?? 'XerinMarket');
    _supportEmailCtrl =
        TextEditingController(text: s['support_email']?.toString() ?? '');
    _supportPhoneCtrl =
        TextEditingController(text: s['support_phone']?.toString() ?? '');
    _minOrderCtrl = TextEditingController(
        text: s['min_order_value']?.toString() ?? '0');
    _maxOrderCtrl = TextEditingController(
        text: s['max_order_value']?.toString() ?? '10000000');
    _maintenanceMode = s['maintenance_mode'] as bool? ?? false;
    _newRegistrations = s['allow_new_registrations'] as bool? ?? true;
    _newSellerRegistrations =
        s['allow_new_seller_registrations'] as bool? ?? true;
  }

  @override
  void dispose() {
    _platformNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    _supportPhoneCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxOrderCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AdminCubit>().updateMarketplaceSettings({
      'platform_name': _platformNameCtrl.text.trim(),
      'support_email': _supportEmailCtrl.text.trim(),
      'support_phone': _supportPhoneCtrl.text.trim(),
      'min_order_value': double.tryParse(_minOrderCtrl.text) ?? 0,
      'max_order_value': double.tryParse(_maxOrderCtrl.text) ?? 10000000,
      'maintenance_mode': _maintenanceMode,
      'allow_new_registrations': _newRegistrations,
      'allow_new_seller_registrations': _newSellerRegistrations,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(cs, 'General'),
          const SizedBox(height: 12),
          _field(cs, 'Platform Name', _platformNameCtrl),
          const SizedBox(height: 12),
          _field(cs, 'Support Email', _supportEmailCtrl),
          const SizedBox(height: 12),
          _field(cs, 'Support Phone', _supportPhoneCtrl),
          const SizedBox(height: 24),
          _sectionTitle(cs, 'Order Limits'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _field(cs, 'Min Order Value', _minOrderCtrl,
                      numeric: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(cs, 'Max Order Value', _maxOrderCtrl,
                      numeric: true)),
            ],
          ),
          const SizedBox(height: 24),
          _sectionTitle(cs, 'Platform Controls'),
          const SizedBox(height: 12),
          _switchTile(
            cs,
            'Maintenance Mode',
            'Take the platform offline for updates',
            _maintenanceMode,
            (v) => setState(() => _maintenanceMode = v),
          ),
          _switchTile(
            cs,
            'Allow New Registrations',
            'New customers can sign up',
            _newRegistrations,
            (v) => setState(() => _newRegistrations = v),
          ),
          _switchTile(
            cs,
            'Allow New Seller Registrations',
            'New sellers can apply',
            _newSellerRegistrations,
            (v) => setState(() => _newSellerRegistrations = v),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Text(title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface));
  }

  Widget _field(ColorScheme cs, String label, TextEditingController ctrl,
      {bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              numeric ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _switchTile(ColorScheme cs, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: SwitchListTile(
          title: Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
