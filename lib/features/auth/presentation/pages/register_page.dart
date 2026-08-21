import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/theme/uicons.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _Country {
  final String name;
  final String flag;
  final String dialCode;
  final String regex;

  const _Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.regex,
  });
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _firstNameNode = FocusNode();
  final _lastNameNode = FocusNode();
  final _emailNode = FocusNode();
  final _phoneNode = FocusNode();
  final _passNode = FocusNode();
  final _confirmNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agree = false;

  static const List<_Country> _countries = [
    _Country(
        name: 'Tanzania',
        flag: '🇹🇿',
        dialCode: '+255',
        regex: r'^[67]\d{8}$'),
    _Country(
        name: 'Kenya', flag: '🇰🇪', dialCode: '+254', regex: r'^[71]\d{8}$'),
    _Country(
        name: 'Uganda', flag: '🇺🇬', dialCode: '+256', regex: r'^[7]\d{8}$'),
  ];
  _Country _selectedCountry = _countries[0];

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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _firstNameNode.dispose();
    _lastNameNode.dispose();
    _emailNode.dispose();
    _phoneNode.dispose();
    _passNode.dispose();
    _confirmNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '${_selectedCountry.dialCode}${_phoneCtrl.text.trim()}';

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      NotificationService().warning(
        'Please accept the Terms of Service & Privacy Policy',
      );
      return;
    }

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final phone = _fullPhone;

    context.read<AuthCubit>().register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          phone: phone,
        );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthRegisterSuccess) {
      NotificationService().success(
        'Welcome ${state.user.firstName}! Please verify your phone.',
      );
      context.go(
        AppConstants.verifyOtpRoute,
        extra: {'phone': state.phone},
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
                          const SizedBox(height: 4),
                          const AuthLogo(width: 140, height: 80),
                          const SizedBox(height: 12),
                          Text(
                            'Create your account',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join XerinMarket and start shopping',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _firstNameCtrl,
                                  focusNode: _firstNameNode,
                                  label: 'First Name',
                                  hint: 'Your first name',
                                  icon: Uicons.user,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _lastNameCtrl,
                                  focusNode: _lastNameNode,
                                  label: 'Last Name',
                                  hint: 'Your last name',
                                  icon: Uicons.user,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                  .hasMatch(v)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _phoneCtrl,
                            focusNode: _phoneNode,
                            label: 'Phone Number',
                            hint: 'e.g. 712345678',
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            prefix: Container(
                              margin: const EdgeInsets.only(left: 4, right: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<_Country>(
                                initialValue: _selectedCountry,
                                onSelected: (country) =>
                                    setState(() => _selectedCountry = country),
                                itemBuilder: (context) {
                                  return _countries.map((country) {
                                    return PopupMenuItem<_Country>(
                                      value: country,
                                      child: Row(
                                        children: [
                                          Text(country.flag,
                                              style: const TextStyle(
                                                  fontSize: 20)),
                                          const SizedBox(width: 10),
                                          Text(
                                            country.dialCode,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            country.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_selectedCountry.flag,
                                        style:
                                            const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedCountry.dialCode,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Uicons.angleDown,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 120,
                              minHeight: 40,
                              maxWidth: 120,
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 130,
                              right: 14,
                              top: 12,
                              bottom: 12,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your phone number';
                              }
                              if (v.length != 9) {
                                return 'Phone number must be 9 digits';
                              }
                              if (!RegExp(_selectedCountry.regex).hasMatch(v)) {
                                return 'Enter a valid ${_selectedCountry.name} number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _passCtrl,
                            focusNode: _passNode,
                            label: 'Password',
                            hint: 'Create a password',
                            icon: Uicons.lock,
                            obscureText: _obscurePass,
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Uicons.eyeCrossed
                                    : Uicons.eye,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _confirmPassCtrl,
                            focusNode: _confirmNode,
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            icon: Uicons.lock,
                            obscureText: _obscureConfirm,
                            validator: (v) => v != _passCtrl.text
                                ? 'Passwords do not match'
                                : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Uicons.eyeCrossed
                                    : Uicons.eye,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: Checkbox(
                                  value: _agree,
                                  onChanged: (v) =>
                                      setState(() => _agree = v ?? false),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  activeColor: colorScheme.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => context.push(AppConstants.termsRoute),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => context.push(AppConstants.privacyRoute),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AuthPrimaryButton(
                            label: 'Sign Up',
                            onPressed: isLoading ? null : _onRegister,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.go(AppConstants.signInRoute),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
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
