import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _otpNode = FocusNode();
  final _passNode = FocusNode();
  final _confirmNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _otpNode.dispose();
    _passNode.dispose();
    _confirmNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().resetPassword(
          email: widget.email,
          otpCode: _otpCtrl.text.trim(),
          newPassword: _passCtrl.text,
        );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthResetPasswordSuccess) {
      NotificationService().success('Password reset successfully!');
      context.go(AppConstants.signInRoute);
    } else if (state is AuthError) {
      NotificationService().error(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: _onStateChange,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          BackIconButton(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppConstants.forgotPasswordRoute);
                              }
                            },
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 32),
                          const Center(
                            child: AuthLogo(width: 180, height: 110),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Enter the OTP sent to ${widget.email} and your new password.',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          AuthTextField(
                            controller: _otpCtrl,
                            focusNode: _otpNode,
                            label: 'OTP Code',
                            hint: '6-digit code',
                            icon: Icons.password_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter the OTP code';
                              }
                              if (v.length != 6) {
                                return 'OTP must be 6 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passCtrl,
                            focusNode: _passNode,
                            label: 'New Password',
                            hint: 'Enter new password',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePass,
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _confirmPassCtrl,
                            focusNode: _confirmNode,
                            label: 'Confirm Password',
                            hint: 'Re-enter new password',
                            icon: Icons.lock_outlined,
                            obscureText: _obscureConfirm,
                            validator: (v) => v != _passCtrl.text
                                ? 'Passwords do not match'
                                : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 32),
                          AuthPrimaryButton(
                            label: 'Reset Password',
                            onPressed: isLoading ? null : _onSubmit,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
