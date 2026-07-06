import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../config/di/service_locator.dart';
import '../../../auth/data/datasources/auth_remote_datasource.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../presentation/cubit/home_cubit.dart';
import '../../presentation/cubit/home_state.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF22C55E)),
        );
        context.pop();
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.read<HomeCubit>().state;
    final user = state is HomeLoaded ? state.user : null;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackIconButton(
                      onTap: () => context.pop(),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text('Profile Information',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(initials,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: colorScheme.primary, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_rounded, color: colorScheme.primary, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(user?.fullName ?? 'Guest',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (user?.email.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(user!.email,
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user?.isVerified == true ? Icons.verified_rounded : Icons.pending_outlined,
                              size: 14,
                              color: user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user?.isVerified == true ? 'Verified' : 'Not verified',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: user?.isVerified == true ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Account Details', colorScheme),
                const SizedBox(height: 12),
                _buildInfoCard(colorScheme,
                  child: Column(
                    children: [
                      _buildField('First Name', _firstNameCtrl, colorScheme, icon: Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      _buildField('Last Name', _lastNameCtrl, colorScheme, icon: Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      _buildField('Email', _emailCtrl, colorScheme, enabled: false, icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildField('Phone Number', _phoneCtrl, colorScheme, keyboardType: TextInputType.phone, icon: Icons.phone_outlined),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Account Status', colorScheme),
                const SizedBox(height: 12),
                _buildInfoCard(colorScheme,
                  child: Column(
                    children: [
                      _buildStatusRow(Icons.badge_outlined, 'Account ID', user?.id ?? '—', colorScheme),
                      _buildStatusRow(Icons.shield_outlined, 'Status', _capitalize(user?.status ?? '—'), colorScheme),
                      _buildStatusRow(Icons.verified_user_outlined, 'Verification', user?.isVerified == true ? 'Verified' : 'Pending', colorScheme),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _buildField(String label, TextEditingController controller, ColorScheme colorScheme, {
    bool enabled = true,
    TextInputType? keyboardType,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? colorScheme.onSurface.withValues(alpha: 0.03) : colorScheme.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(icon, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  validator: (v) => (v == null || v.trim().isEmpty) && enabled ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
