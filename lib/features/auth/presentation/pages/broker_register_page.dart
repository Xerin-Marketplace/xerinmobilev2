import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';

class BrokerRegisterPage extends StatefulWidget {
  const BrokerRegisterPage({super.key});

  @override
  State<BrokerRegisterPage> createState() => _BrokerRegisterPageState();
}

class _BrokerRegisterPageState extends State<BrokerRegisterPage>
    with SingleTickerProviderStateMixin {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Tanzania');
  final _regionCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const List<Map<String, String>> _countries = [
    {'name': 'Tanzania', 'flag': '🇹🇿', 'dialCode': '+255', 'regex': r'^[67]\d{8}$'},
    {'name': 'Kenya', 'flag': '🇰🇪', 'dialCode': '+254', 'regex': r'^[71]\d{8}$'},
    {'name': 'Uganda', 'flag': '🇺🇬', 'dialCode': '+256', 'regex': r'^[7]\d{8}$'},
  ];
  int _selectedCountryIdx = 0;

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
    _countryCtrl.dispose();
    _regionCtrl.dispose();
    _cityCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '${_countries[_selectedCountryIdx]['dialCode']}${_phoneCtrl.text.trim()}';

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().registerBroker(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _fullPhone,
          password: _passCtrl.text,
          country: _countryCtrl.text.trim(),
          region: _regionCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
        );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is BrokerRegisterSuccess) {
      NotificationService().success(state.message);
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Uicons.angleLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Broker Registration'),
        ),
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
                    buildWhen: (prev, curr) =>
                        curr is AuthLoading || curr is AuthError,
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          const Center(child: AuthLogo(width: 140, height: 80)),
                          const SizedBox(height: 12),
                          _sectionTitle(context, 'Become a Broker',
                              'Promote products and earn commissions'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _firstNameCtrl,
                                  label: 'First Name',
                                  hint: 'Your first name',
                                  icon: Uicons.user,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _lastNameCtrl,
                                  label: 'Last Name',
                                  hint: 'Your last name',
                                  icon: Uicons.user,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _emailCtrl,
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
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number',
                            hint: 'e.g. 712345678',
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            prefix: _countryPicker(colorScheme),
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
                              final regex = _countries[_selectedCountryIdx]['regex']!;
                              if (!RegExp(regex).hasMatch(v)) {
                                return 'Enter a valid ${_countries[_selectedCountryIdx]['name']} number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: 'Create a password',
                            icon: Uicons.lock,
                            obscureText: _obscurePass,
                            validator: (v) =>
                                v == null || v.length < 8 ? 'Min 8 characters' : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass ? Uicons.eyeCrossed : Uicons.eye,
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _confirmPassCtrl,
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            icon: Uicons.lock,
                            obscureText: _obscureConfirm,
                            validator: (v) =>
                                v != _passCtrl.text ? 'Passwords do not match' : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Uicons.eyeCrossed : Uicons.eye,
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'Location',
                              'Where you will operate as a broker'),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _countryCtrl,
                            label: 'Country',
                            hint: 'e.g. Tanzania',
                            icon: Uicons.globe,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _regionCtrl,
                                  label: 'Region',
                                  hint: 'e.g. Dar es Salaam',
                                  icon: Uicons.location,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _cityCtrl,
                                  label: 'City',
                                  hint: 'e.g. Dar es Salaam',
                                  icon: Uicons.location,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AuthPrimaryButton(
                            label: 'Register as Broker',
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
                                  onTap: () => context.go(AppConstants.signInRoute),
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

  Widget _sectionTitle(BuildContext context, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }

  Widget _countryPicker(ColorScheme colorScheme) {
    final country = _countries[_selectedCountryIdx];
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<int>(
        initialValue: _selectedCountryIdx,
        onSelected: (idx) => setState(() {
          _selectedCountryIdx = idx;
          _countryCtrl.text = _countries[idx]['name']!;
        }),
        itemBuilder: (context) {
          return _countries.asMap().entries.map((entry) {
            final c = entry.value;
            return PopupMenuItem<int>(
              value: entry.key,
              child: Row(
                children: [
                  Text(c['flag']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(
                    c['dialCode']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c['name']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
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
            Text(country['flag']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text(
              country['dialCode']!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Uicons.angleDown, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
