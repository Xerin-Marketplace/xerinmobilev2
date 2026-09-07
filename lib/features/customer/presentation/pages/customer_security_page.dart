import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';

class CustomerSecurityPage extends StatefulWidget {
  const CustomerSecurityPage({super.key});

  @override
  State<CustomerSecurityPage> createState() => _CustomerSecurityPageState();
}

class _CustomerSecurityPageState extends State<CustomerSecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _newController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    if (p.length >= 12) score++;
    return score;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newController.text != _confirmController.text) {
      NotificationService().error('Passwords do not match');
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await context.read<CustomerCubit>().changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocListener<CustomerCubit, CustomerState>(
          listener: (context, state) {
            if (state is CustomerActionSuccess) {
              NotificationService().success(state.message);
            }
            if (state is CustomerError) {
              NotificationService().error(state.message);
            }
          },
          child: Column(
            children: [
              _buildHeader(cs),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWarningCard(cs, isDark),
                        const SizedBox(height: 20),
                        _buildPasswordFieldsCard(cs, isDark),
                        const SizedBox(height: 20),
                        _buildSecurityStatusCard(cs, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Account Security',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text('Protect your account',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(ColorScheme cs, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, size: 20, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Changing your password invalidates existing refresh sessions. You will need to sign in again.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFieldsCard(ColorScheme cs, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Change password',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _passwordField(
              controller: _currentController,
              label: 'Current password',
              obscure: _obscureCurrent,
              toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              cs: cs,
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _newController,
              label: 'New password',
              obscure: _obscureNew,
              toggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Min 8 characters';
                return null;
              },
              onChanged: (_) => setState(() {}),
              cs: cs,
            ),
            if (_newController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildStrengthIndicator(cs),
            ],
            const SizedBox(height: 16),
            _passwordField(
              controller: _confirmController,
              label: 'Confirm new password',
              obscure: _obscureConfirm,
              toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _newController.text) return 'Passwords do not match';
                return null;
              },
              cs: cs,
            ),
            const SizedBox(height: 12),
            Text(
              'Use at least 8 characters. A combination of letters and numbers is recommended.',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Changing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : const Text('Change password',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(ColorScheme cs) {
    final strength = _passwordStrength;
    final labels = ['Very weak', 'Weak', 'Fair', 'Good', 'Strong', 'Very strong'];
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFF22C55E),
      const Color(0xFF16A34A),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final active = i < strength;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? colors[strength] : cs.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          labels[strength],
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors[strength],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityStatusCard(ColorScheme cs, bool isDark) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Account security status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _securityItem(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF22C55E),
              title: 'Password changes',
              subtitle: 'Supported by the backend',
              cs: cs,
            ),
            const SizedBox(height: 12),
            _securityItem(
              icon: Icons.lock_clock,
              iconColor: cs.onSurface.withValues(alpha: 0.3),
              title: 'Active-session management',
              subtitle: 'Not currently exposed as customer API',
              cs: cs,
            ),
            const SizedBox(height: 12),
            _securityItem(
              icon: Icons.phonelink_lock,
              iconColor: cs.onSurface.withValues(alpha: 0.3),
              title: 'Two-factor authentication',
              subtitle: 'Not currently exposed as customer API',
              cs: cs,
            ),
            const SizedBox(height: 16),
            Text(
              'This page does not show non-functional controls for features that are not yet available.',
              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              Text(subtitle,
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required ColorScheme cs,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
          onPressed: toggle,
        ),
      ),
    );
  }
}
