import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../config/di/service_locator.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/models/user_model.dart';
import '../../presentation/cubit/home_cubit.dart';
import '../../presentation/cubit/home_state.dart';

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.read<HomeCubit>().state;
    final user = state is HomeLoaded ? state.user : null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSimpleHeader(user, colorScheme),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Personal Information', colorScheme),
                    const SizedBox(height: 12),
                    _buildInfoRow('First Name', user?.firstName ?? '—', colorScheme),
                    _buildDivider(colorScheme),
                    _buildInfoRow('Last Name', user?.lastName ?? '—', colorScheme),
                    _buildDivider(colorScheme),
                    _buildInfoRow('Email', user?.email ?? '—', colorScheme),
                    _buildDivider(colorScheme),
                    _buildInfoRow('Phone', user?.phone ?? '—', colorScheme),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Account Status', colorScheme),
                    const SizedBox(height: 12),
                    _buildInfoRow('Account Type', _capitalize(user?.accountType ?? 'Customer'), colorScheme),
                    _buildDivider(colorScheme),
                    _buildInfoRow('Verification', user?.isVerified == true ? 'Verified' : 'Pending', colorScheme,
                        valueColor: user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)),
                    _buildDivider(colorScheme),
                    _buildInfoRow('Status', _capitalize(user?.status ?? 'Active'), colorScheme),
                    if (user?.isSeller == true) ...[
                      _buildDivider(colorScheme),
                      _buildInfoRow('Seller Account', _capitalize(user?.sellerStatus ?? 'Active'), colorScheme),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showEditDrawer(context, user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          Text('Personal Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader(UserModel? user, ColorScheme cs) {
    final isVerified = user?.isVerified == true;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: cs.primary.withValues(alpha: 0.08),
          backgroundImage: const AssetImage('assets/images/avatar.png'),
          child: initials.isNotEmpty
              ? Text(initials, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.primary))
              : null,
        ),
        const SizedBox(height: 12),
        Text(user?.fullName ?? 'Guest',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        if (user?.email.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(user!.email, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
        ],
        const SizedBox(height: 8),
        Text(isVerified ? 'Verified' : 'Pending',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)));
  }

  Widget _buildInfoRow(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06));
  }

  Widget _buildStatusRow(IconData icon, String label, String value, ColorScheme cs, {Color? valueColor}) {
    return _buildInfoRow(label, value, cs, valueColor: valueColor);
  }

  void _showEditDrawer(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _EditProfileSheet(user: user),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel? user;

  const _EditProfileSheet({this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final ds = sl<AuthRemoteDataSource>();
      await ds.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (mounted) {
        context.read<HomeCubit>().loadHome();
        NotificationService().success('Profile updated successfully');
        Navigator.of(context).pop();
      }
    } on ServerException catch (e) {
      if (mounted) NotificationService().error(e.message);
    } catch (e) {
      if (mounted) NotificationService().error('Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text('Update your personal information',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 24),
                _buildField('First Name', _firstNameCtrl, cs),
                const SizedBox(height: 16),
                _buildField('Last Name', _lastNameCtrl, cs),
                const SizedBox(height: 16),
                _buildField('Email', null, cs, initialValue: widget.user?.email, enabled: false),
                const SizedBox(height: 16),
                _buildField('Phone Number', _phoneCtrl, cs, keyboardType: TextInputType.phone),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController? controller, ColorScheme cs, {
    bool enabled = true,
    TextInputType? keyboardType,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: (v) => (v == null || v.trim().isEmpty) && enabled ? 'Required' : null,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4)),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
