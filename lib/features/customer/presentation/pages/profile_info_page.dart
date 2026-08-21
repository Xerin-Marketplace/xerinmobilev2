import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../config/di/service_locator.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../presentation/cubit/home_cubit.dart';
import '../../presentation/cubit/home_state.dart';
import '../../../../core/theme/uicons.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<HomeCubit>().state;
    final user = state is HomeLoaded ? state.user : null;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
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
        context.pop();
      }
    } on ServerException catch (e) {
      if (mounted) {
        NotificationService().error(e.message);
      }
    } catch (e) {
      if (mounted) {
        NotificationService().error('Failed to update: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.read<HomeCubit>().state;
    final user = state is HomeLoaded ? state.user : null;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildAppBar(colorScheme),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatarSection(user, initials, colorScheme),
                      const SizedBox(height: 28),
                      _buildSectionLabel('Personal Information', colorScheme),
                      const SizedBox(height: 14),
                      _buildCard(cs: colorScheme, isDark: isDark, child: Column(
                        children: [
                          _buildField('First Name', _firstNameCtrl, colorScheme, icon: Uicons.user),
                          _buildDivider(colorScheme),
                          _buildField('Last Name', _lastNameCtrl, colorScheme, icon: Uicons.user),
                          _buildDivider(colorScheme),
                          _buildField('Email', _emailCtrl, colorScheme, enabled: false, icon: Uicons.envelope),
                          _buildDivider(colorScheme),
                          _buildField('Phone Number', _phoneCtrl, colorScheme, keyboardType: TextInputType.phone, icon: Uicons.phone),
                        ],
                      )),
                      const SizedBox(height: 24),
                      _buildSectionLabel('Account Status', colorScheme),
                      const SizedBox(height: 14),
                      _buildCard(cs: colorScheme, isDark: isDark, child: Column(
                        children: [
                          _buildStatusRow(Uicons.circleUser, 'Account Type', _capitalize(user?.accountType ?? 'Customer'), colorScheme),
                          _buildDivider(colorScheme),
                          _buildStatusRow(
                            user?.isVerified == true ? Uicons.badgeCheck : Uicons.clock,
                            'Verification',
                            user?.isVerified == true ? 'Verified' : 'Pending',
                            colorScheme,
                            valueColor: user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                          ),
                          _buildDivider(colorScheme),
                          _buildStatusRow(Uicons.shield, 'Status', _capitalize(user?.status ?? 'Active'), colorScheme),
                          if (user?.isSeller == true) ...[
                            _buildDivider(colorScheme),
                            _buildStatusRow(Uicons.shop, 'Seller Account', _capitalize(user?.sellerStatus ?? 'Active'), colorScheme),
                          ],
                        ],
                      )),
                      const SizedBox(height: 32),
                      _buildSaveButton(colorScheme),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          BackIconButton(
            onTap: () => context.pop(),
            color: cs.primary,
          ),
          const SizedBox(width: 16),
          Text('Personal Information',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserModel? user, String initials, ColorScheme cs) {
    final isVerified = user?.isVerified == true;
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                child: Text(initials,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(user?.fullName ?? 'Guest',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          if (user?.email.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(user!.email,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerified ? Uicons.badgeCheck : Uicons.clock,
                  size: 13,
                  color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 5),
                Text(
                  isVerified ? 'Verified Account' : 'Not Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.6)),
    );
  }

  Widget _buildCard({required ColorScheme cs, required bool isDark, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06));
  }

  Widget _buildField(String label, TextEditingController controller, ColorScheme cs, {
    bool enabled = true,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 6),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: enabled ? cs.primary.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  validator: (v) => (v == null || v.trim().isEmpty) && enabled ? 'Required' : null,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 15),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (!enabled)
                Icon(Uicons.lock, size: 14, color: cs.onSurface.withValues(alpha: 0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: (valueColor ?? cs.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: valueColor ?? cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.5))),
          ),
          Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
