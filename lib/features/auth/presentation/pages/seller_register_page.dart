import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/country_data.dart';
import '../../../../core/theme/uicons.dart';
import '../../../../core/widgets/country_picker_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_background.dart';
import '../widgets/theme_toggle_button.dart';

class SellerRegisterPage extends StatefulWidget {
  const SellerRegisterPage({super.key});

  @override
  State<SellerRegisterPage> createState() => _SellerRegisterPageState();
}

class _SellerRegisterPageState extends State<SellerRegisterPage>
    with SingleTickerProviderStateMixin {
  // Account fields
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Business fields
  final _businessNameCtrl = TextEditingController();
  final _businessDescCtrl = TextEditingController();
  final _businessCountryCtrl = TextEditingController();
  final _businessRegionCtrl = TextEditingController();
  final _businessCityCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();
  final _productDescCtrl = TextEditingController();
  final _yearsInBusinessCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agree = false;

  List<Map<String, dynamic>> _categories = [];
  Set<String> _selectedCategoryIds = {};

  Country _selectedCountry = CountryData.defaultCountry;

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

    context.read<AuthCubit>().loadBusinessCategories();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessDescCtrl.dispose();
    _businessCountryCtrl.dispose();
    _businessRegionCtrl.dispose();
    _businessCityCtrl.dispose();
    _businessAddressCtrl.dispose();
    _productDescCtrl.dispose();
    _yearsInBusinessCtrl.dispose();
    _websiteCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone =>
      '${_selectedCountry.dialCode}${_phoneCtrl.text.trim()}';

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      NotificationService().warning('Please select at least one business category');
      return;
    }
    if (!_agree) {
      NotificationService().warning(
        'Please accept the Seller Agreement to continue',
      );
      return;
    }

    context.read<AuthCubit>().registerSeller(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _fullPhone,
          password: _passCtrl.text,
          businessName: _businessNameCtrl.text.trim(),
          businessCategoryIds: _selectedCategoryIds.toList(),
          businessDescription: _businessDescCtrl.text.trim().isEmpty
              ? null
              : _businessDescCtrl.text.trim(),
          businessCountry: _businessCountryCtrl.text.trim().isEmpty
              ? null
              : _businessCountryCtrl.text.trim(),
          businessRegion: _businessRegionCtrl.text.trim().isEmpty
              ? null
              : _businessRegionCtrl.text.trim(),
          businessCity: _businessCityCtrl.text.trim().isEmpty
              ? null
              : _businessCityCtrl.text.trim(),
          businessAddress: _businessAddressCtrl.text.trim().isEmpty
              ? null
              : _businessAddressCtrl.text.trim(),
          productDescription: _productDescCtrl.text.trim().isEmpty
              ? null
              : _productDescCtrl.text.trim(),
          yearsInBusiness: _yearsInBusinessCtrl.text.trim().isEmpty
              ? null
              : _yearsInBusinessCtrl.text.trim(),
          websiteUrl:
              _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
          contactEmail: _contactEmailCtrl.text.trim().isEmpty
              ? null
              : _contactEmailCtrl.text.trim(),
          contactPhone: _contactPhoneCtrl.text.trim().isEmpty
              ? null
              : _contactPhoneCtrl.text.trim(),
        );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is SellerRegisterSuccess) {
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
          title: const Text('Seller Registration'),
        ),
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
                    buildWhen: (prev, curr) =>
                        curr is AuthLoading ||
                        curr is BusinessCategoriesLoaded ||
                        curr is AuthError,
                    builder: (context, state) {
                      if (state is BusinessCategoriesLoaded) {
                        _categories = state.categories;
                      }
                      final isLoading = state is AuthLoading;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const AuthLogo(width: 140, height: 80),
                              const ThemeToggleButton(),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _sectionTitle(context, 'Account Information',
                              'Create your seller account'),
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
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
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
                            label: 'Phone Number',
                            hint: 'e.g. 712345678',
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            prefix: CountryPickerField(
                              selectedCountry: _selectedCountry,
                              onSelected: (country) =>
                                  setState(() => _selectedCountry = country),
                              colorScheme: colorScheme,
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
                              if (v.length < 6 || v.length > _selectedCountry.maxLength) {
                                return 'Enter a valid phone number';
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
                            validator: (v) => v == null || v.length < 8
                                ? 'Min 8 characters'
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
                          const SizedBox(height: 28),
                          _sectionTitle(context, 'Business Information',
                              'Tell us about your business'),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _businessNameCtrl,
                            label: 'Business Name',
                            hint: 'Your business or store name',
                            icon: Uicons.shop,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Business name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Business Categories',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select all that apply',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _categories.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                )
                              : _categoryChips(colorScheme),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _businessDescCtrl,
                            label: 'Business Description (Optional)',
                            hint: 'Brief description of your business',
                            icon: Uicons.file,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _businessCountryCtrl,
                                  label: 'Country (Optional)',
                                  hint: 'e.g. Tanzania',
                                  icon: Uicons.globe,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _businessRegionCtrl,
                                  label: 'Region (Optional)',
                                  hint: 'e.g. Dar es Salaam',
                                  icon: Uicons.location,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _businessCityCtrl,
                                  label: 'City (Optional)',
                                  hint: 'e.g. Dar es Salaam',
                                  icon: Uicons.location,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _businessAddressCtrl,
                                  label: 'Address (Optional)',
                                  hint: 'Street address',
                                  icon: Uicons.location,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _productDescCtrl,
                            label: 'Product Description (Optional)',
                            hint: 'What products do you sell?',
                            icon: Uicons.box,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AuthTextField(
                                  controller: _yearsInBusinessCtrl,
                                  label: 'Years in Business (Optional)',
                                  hint: 'e.g. 3',
                                  icon: Uicons.clock,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AuthTextField(
                                  controller: _websiteCtrl,
                                  label: 'Website (Optional)',
                                  hint: 'https://...',
                                  icon: Uicons.globe,
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _contactEmailCtrl,
                            label: 'Contact Email (Optional)',
                            hint: 'business@email.com',
                            icon: Uicons.envelope,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: _contactPhoneCtrl,
                            label: 'Contact Phone (Optional)',
                            hint: 'Business phone number',
                            icon: Uicons.phone,
                            keyboardType: TextInputType.phone,
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
                                    text:
                                        'I agree to the XerinMarket Seller Agreement and ',
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
                                          ..onTap = () => context
                                              .push(AppConstants.termsRoute),
                                      ),
                                      const TextSpan(text: ' & '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => context
                                              .push(AppConstants.privacyRoute),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AuthPrimaryButton(
                            label: 'Register as Seller',
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
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () => context
                                  .push(AppConstants.brokerRegisterRoute),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Uicons.shop,
                                        size: 18, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Register as Broker',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _categoryChips(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final id = cat['id']?.toString() ?? '';
        final name = cat['name']?.toString() ?? 'Unknown';
        final isSelected = _selectedCategoryIds.contains(id);
        return FilterChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategoryIds.add(id);
              } else {
                _selectedCategoryIds.remove(id);
              }
            });
          },
          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
          checkmarkColor: colorScheme.primary,
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.onSurface.withValues(alpha: 0.15),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}
