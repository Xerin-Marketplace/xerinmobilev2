import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';

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
  bool _isSeller = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service & Privacy Policy'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final phone = _fullPhone;

    if (_isSeller) {
      context.read<AuthCubit>().storeRegistrationData(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phone: phone,
          );
      context.go(AppConstants.sellerDetailsRoute);
    } else {
      context.read<AuthCubit>().register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            phone: phone,
          );
    }
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthRegisterSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Welcome ${state.user.firstName}! Please verify your phone.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(
        AppConstants.verifyOtpRoute,
        extra: {'phone': state.phone},
      );
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
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
                              const SizedBox(width: 12),
                              Expanded(child: _buildSellerToggle(colorScheme)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const AuthLogo(width: 180, height: 110),
                          const SizedBox(height: 20),
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSeller
                                ? 'Register your shop and start selling'
                                : 'Join us and start shopping today',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _firstNameCtrl,
                                  focusNode: _firstNameNode,
                                  label: 'First Name',
                                  hint: 'John',
                                  icon: Icons.person_outlined,
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
                                  hint: 'Doe',
                                  icon: Icons.person_outlined,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _emailCtrl,
                            focusNode: _emailNode,
                            label: 'Email',
                            hint: 'example@email.com',
                            icon: Icons.email_outlined,
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
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _phoneCtrl,
                            focusNode: _phoneNode,
                            label: 'Phone Number',
                            hint: '7XXXXXXXX',
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
                                      Icons.keyboard_arrow_down_rounded,
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
                              right: 16,
                              top: 16,
                              bottom: 16,
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
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _passCtrl,
                            focusNode: _passNode,
                            label: 'Password',
                            hint: 'Enter your password',
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
                            hint: 'Re-enter your password',
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
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 28),
                          AuthPrimaryButton(
                            label: _isSeller ? 'Next' : 'Create Account',
                            onPressed: isLoading ? null : _onRegister,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: 24),
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
                          const SizedBox(height: 24),
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

  Widget _buildSellerToggle(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Become a Seller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _isSeller ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Start selling your products',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: _isSeller,
          onChanged: (v) => setState(() => _isSeller = v),
          activeTrackColor: colorScheme.primary,
          activeThumbColor: colorScheme.onPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
