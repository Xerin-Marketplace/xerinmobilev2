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
import '../widgets/auth_background.dart';
import '../widgets/theme_toggle_button.dart';
import '../../../../core/theme/uicons.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _emailNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().forgotPassword(
            email: _emailCtrl.text.trim(),
          );
    }
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthForgotPasswordSent) {
      NotificationService().success('OTP sent to ${state.email}');
      context.go(
        AppConstants.resetPasswordRoute,
        extra: {'email': state.email},
      );
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
        body: AuthBackground(
          child: SafeArea(
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
                          const SizedBox(height: 8),
                          BackIconButton(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppConstants.signInRoute);
                              }
                            },
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ThemeToggleButton(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "No worries. Enter your email and we'll send you a code to reset it.",
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AuthTextField(
                            controller: _emailCtrl,
                            focusNode: _emailNode,
                            label: 'Email',
                            hint: 'you@email.com',
                            icon: Uicons.envelope,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          AuthPrimaryButton(
                            label: 'Send Reset Code',
                            onPressed: isLoading ? null : _onSubmit,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 16),
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
      ),
    );
  }
}
