import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';

class SellerDetailsPage extends StatefulWidget {
  const SellerDetailsPage({super.key});

  @override
  State<SellerDetailsPage> createState() => _SellerDetailsPageState();
}

class _SellerDetailsPageState extends State<SellerDetailsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _shopDescCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _shopNameNode = FocusNode();
  final _shopDescNode = FocusNode();
  final _shopAddressNode = FocusNode();
  String _shopCategory = 'Electronics';

  final List<String> _categories = [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Food & Beverages',
    'Health & Beauty',
    'Sports',
    'Books & Media',
    'Other',
  ];

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _shopNameCtrl.dispose();
    _shopDescCtrl.dispose();
    _shopAddressCtrl.dispose();
    _shopNameNode.dispose();
    _shopDescNode.dispose();
    _shopAddressNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onComplete() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    cubit.registerSeller(
      firstName: cubit.pendingFirstName ?? '',
      lastName: cubit.pendingLastName ?? '',
      email: cubit.pendingEmail ?? '',
      phone: cubit.pendingPhone ?? '',
      password: cubit.pendingPassword ?? '',
      businessName: _shopNameCtrl.text.trim(),
      businessCategory: _shopCategory,
      contactEmail: cubit.pendingEmail,
      contactPhone: cubit.pendingPhone,
    );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthSellerRegisterSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Shop "${state.seller.businessName}" registered successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go(
        AppConstants.registrationSuccessRoute,
        extra: {
          'isSeller': true,
          'shopName': state.seller.businessName,
        },
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    BackIconButton(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppConstants.registerRoute);
                        }
                      },
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Shop Details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill your shop information to start selling',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _shopNameCtrl,
                      focusNode: _shopNameNode,
                      label: 'Shop Name',
                      hint: 'e.g. Xerin Fashion Store',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your shop name' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _shopCategory,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _shopCategory = v ?? 'Electronics'),
                      decoration: InputDecoration(
                        labelText: 'Shop Category',
                        filled: true,
                        fillColor: colorScheme.surface.withValues(alpha: 0.6),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _shopDescCtrl,
                      focusNode: _shopDescNode,
                      label: 'Shop Description',
                      hint: 'Tell customers about your shop...',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter a short description'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _shopAddressCtrl,
                      focusNode: _shopAddressNode,
                      label: 'Shop Address',
                      hint: 'e.g. Mlimani City, Dar es Salaam',
                      icon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your shop address'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              disabledBackgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Complete Registration',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
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
