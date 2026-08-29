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
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBannerWithAvatar(user, colorScheme, isDark),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Personal Information', colorScheme),
                          const SizedBox(height: 12),
                          _buildCard(colorScheme, isDark, child: Column(
                            children: [
                              _buildInfoTile(Uicons.user, 'First Name', user?.firstName ?? '—', colorScheme),
                              _buildDivider(colorScheme),
                              _buildInfoTile(Uicons.user, 'Last Name', user?.lastName ?? '—', colorScheme),
                              _buildDivider(colorScheme),
                              _buildInfoTile(Uicons.envelope, 'Email', user?.email ?? '—', colorScheme),
                              _buildDivider(colorScheme),
                              _buildInfoTile(Uicons.phone, 'Phone', user?.phone ?? '—', colorScheme),
                            ],
                          )),
                          const SizedBox(height: 24),
                          _buildSectionLabel('Account Status', colorScheme),
                          const SizedBox(height: 12),
                          _buildCard(colorScheme, isDark, child: Column(
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
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _showEditDrawer(context, user),
                              icon: const Icon(Uicons.userPen, size: 18),
                              label: const Text('Edit Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildBannerWithAvatar(UserModel? user, ColorScheme cs, bool isDark) {
    final isVerified = user?.isVerified == true;
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient banner header
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle pattern overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              // Verified badge top right
              Positioned(
                top: 12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isVerified ? const Color(0xFF22C55E) : const Color(0xFFF59E0B)).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Uicons.badgeCheck : Uicons.clock,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Verified' : 'Pending',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Avatar overlapping the banner
        Positioned(
          top: 110,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withValues(alpha: 0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: cs.primary.withValues(alpha: 0.08),
                  backgroundImage: const AssetImage('assets/images/avatar.png'),
                  child: initials.isNotEmpty
                      ? Text(initials,
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: cs.primary))
                      : null,
                ),
              ),
            ),
          ),
        ),
        // Name and email below avatar
        Positioned(
          top: 218,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Text(user?.fullName ?? 'Guest',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                if (user?.email.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(user!.email,
                    style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme cs) {
    return Text(label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.4)),
    );
  }

  Widget _buildCard(ColorScheme cs, bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 3),
                Text(value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme cs) {
    return Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06), indent: 62);
  }

  Widget _buildStatusRow(IconData icon, String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _showEditDrawer(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Uicons.userPen, color: cs.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text('Update your personal information',
                            style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Uicons.xmark, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildField('First Name', _firstNameCtrl, cs, icon: Uicons.user),
                const SizedBox(height: 16),
                _buildField('Last Name', _lastNameCtrl, cs, icon: Uicons.user),
                const SizedBox(height: 16),
                _buildField('Email', null, cs, icon: Uicons.envelope, initialValue: widget.user?.email, enabled: false),
                const SizedBox(height: 16),
                _buildField('Phone Number', _phoneCtrl, cs, icon: Uicons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cancel',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
    IconData? icon,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? (cs.onSurface.withValues(alpha: 0.03)) : cs.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withValues(alpha: enabled ? 0.08 : 0.04)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Icon(icon, size: 18, color: enabled ? cs.primary.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.2)),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  initialValue: initialValue,
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              if (!enabled)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(Uicons.lock, size: 14, color: cs.onSurface.withValues(alpha: 0.2)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
