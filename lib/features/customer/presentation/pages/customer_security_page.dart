import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
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

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isStrong {
    final p = _newController.text;
    return p.length >= 8 &&
        p.contains(RegExp(r'[A-Z]')) &&
        p.contains(RegExp(r'[0-9]'));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_newController.text != _confirmController.text) {
      NotificationService().error('Passwords do not match');
      return;
    }
    context.read<CustomerCubit>().changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
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
        title: const Text('Account Security'),
      ),
      body: SafeArea(
        child: BlocListener<CustomerCubit, CustomerState>(
          listener: (context, state) {
            if (state is CustomerActionSuccess) {
              NotificationService().success(state.message);
              _currentController.clear();
              _newController.clear();
              _confirmController.clear();
            }
            if (state is CustomerError) {
              NotificationService().error(state.message);
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Uicons.lock,
                                    size: 18, color: cs.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Change password',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Changing your password invalidates existing sessions. You will need to sign in again.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _passwordField(
                            controller: _currentController,
                            label: 'Current password',
                            obscure: _obscureCurrent,
                            toggle: () => setState(() =>
                                _obscureCurrent = !_obscureCurrent),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _passwordField(
                            controller: _newController,
                            label: 'New password',
                            obscure: _obscureNew,
                            toggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 8) return 'Min 8 characters';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_newController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _isStrong
                                      ? Uicons.checkCircle
                                      : Uicons.circleExclamation,
                                  size: 14,
                                  color: _isStrong
                                      ? Colors.green
                                      : Colors.amber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isStrong
                                      ? 'Good password format'
                                      : 'Password can be stronger',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isStrong
                                        ? Colors.green
                                        : Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _passwordField(
                            controller: _confirmController,
                            label: 'Confirm new password',
                            obscure: _obscureConfirm,
                            toggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _submit,
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Change password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.08)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account security status',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Text(
                            'Password changes are supported. Active-session management and two-factor authentication are not currently available.',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Uicons.eye : Uicons.eyeCrossed, size: 18),
          onPressed: toggle,
        ),
      ),
    );
  }
}
