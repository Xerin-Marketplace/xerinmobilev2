import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailNode = FocusNode();
  final _passNode = FocusNode();
  bool _obscurePass = true;
  bool _remember = false;

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
    _passCtrl.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthLoginSuccess) {
      NotificationService().success('Signed in successfully!');
      if (state.isAdmin) {
        context.go(AppConstants.adminDashboardRoute);
      } else if (state.isSeller) {
        context.go(AppConstants.sellerDashboardRoute);
      } else {
        context.go(AppConstants.homeRoute);
      }
    } else if (state is AuthGuest) {
      NotificationService().success('Welcome, Guest!');
      context.go(AppConstants.homeRoute);
    } else if (state is AuthNeedsVerification) {
      _showVerifyDialog(context, state.email);
    } else if (state is AuthError) {
      NotificationService().error(state.message);
    }
  }

  void _showVerifyDialog(BuildContext context, String email) {
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Account Not Verified'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your account ($email) is not verified. Enter your phone number to receive an OTP.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+255XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter your phone number';
                    }
                    if (v.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final phone = phoneCtrl.text.trim();
                  Navigator.of(dialogContext).pop();
                  context.read<AuthCubit>().sendOtp(phone: phone);
                  context.go(
                    AppConstants.verifyOtpRoute,
                    extra: {'phone': phone, 'fromLogin': true},
                  );
                }
              },
              child: const Text('Send OTP'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: _onStateChange,
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError ? state.message : null;
        return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.08),
                    colorScheme.primary.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            blurRadius: 30,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const AuthLogo(width: 200, height: 130),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue shopping',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (errorMessage != null) ...[
                      AuthErrorBanner(message: errorMessage),
                      const SizedBox(height: 20),
                    ],
                    AuthTextField(
                      controller: _emailCtrl,
                      focusNode: _emailNode,
                      label: 'Email',
                      hint: 'name@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your email' : null,
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      controller: _passCtrl,
                      focusNode: _passNode,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outlined,
                      obscureText: _obscurePass,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password'
                          : null,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Checkbox(
                                value: _remember,
                                onChanged: (v) =>
                                    setState(() => _remember = v ?? false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                activeColor: colorScheme.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppConstants.forgotPasswordRoute),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AuthPrimaryButton(
                      label: 'Sign In',
                      onPressed: isLoading ? null : _onSignIn,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: isLoading ? null : () => context.read<AuthCubit>().continueAsGuest(),
                        icon: Icon(Icons.person_outline_rounded, color: colorScheme.primary, size: 18),
                        label: const Text('Continue as Guest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.onSurface.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.onSurface.withValues(alpha: 0.08),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.go(AppConstants.registerRoute),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: colorScheme.primary,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
      },
    );
  }

}
