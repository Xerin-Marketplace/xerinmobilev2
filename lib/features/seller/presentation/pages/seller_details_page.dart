import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../seller/data/datasources/seller_remote_datasource.dart';

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
  List<Map<String, dynamic>> _businessCategories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final ds = GetIt.instance<SellerRemoteDataSource>();
      final cats = await ds.getBusinessCategories();
      if (mounted) {
        setState(() {
          // Use API categories only if they have UUID-format IDs,
          // otherwise use fallback categories with valid UUIDs
          final hasUuidIds = cats.isNotEmpty &&
              _isUuid(cats.first['id']?.toString() ?? '');
          _businessCategories = hasUuidIds ? cats : _fallbackCategories();
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _businessCategories = _fallbackCategories();
          _loadingCategories = false;
        });
      }
    }
  }

  bool _isUuid(String id) {
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);
  }

  List<Map<String, dynamic>> _fallbackCategories() {
    return [
      {'id': '550e8400-e29b-41d4-a716-446655440001', 'name': 'Fashion & Clothing'},
      {'id': '550e8400-e29b-41d4-a716-446655440002', 'name': 'Electronics & Technology'},
      {'id': '550e8400-e29b-41d4-a716-446655440003', 'name': 'Food & Grocery'},
      {'id': '550e8400-e29b-41d4-a716-446655440004', 'name': 'Beauty & Cosmetics'},
      {'id': '550e8400-e29b-41d4-a716-446655440005', 'name': 'Health & Pharmacy'},
      {'id': '550e8400-e29b-41d4-a716-446655440006', 'name': 'Home & Furniture'},
      {'id': '550e8400-e29b-41d4-a716-446655440007', 'name': 'Sports & Fitness'},
      {'id': '550e8400-e29b-41d4-a716-446655440008', 'name': 'Books & Stationery'},
      {'id': '550e8400-e29b-41d4-a716-446655440009', 'name': 'Toys & Kids'},
      {'id': '550e8400-e29b-41d4-a716-446655440010', 'name': 'Automotive'},
      {'id': '550e8400-e29b-41d4-a716-446655440011', 'name': 'General Retail'},
    ];
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

  Widget _buildCategorySelector(ColorScheme cs) {
    if (_loadingCategories) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading categories...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_businessCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No categories available. Please try again later.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _loadingCategories = true);
                _loadCategories();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCategoryBottomSheet(cs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedCategoryId == null
                    ? cs.onSurface.withValues(alpha: 0.08)
                    : cs.primary.withValues(alpha: 0.3),
                width: _selectedCategoryId == null ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedCategoryId != null)
                        Text(
                          _businessCategories.firstWhere(
                            (c) => c['id']?.toString() == _selectedCategoryId,
                            orElse: () => {'name': 'Unknown'},
                          )['name']?.toString() ??
                              'Unknown',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        )
                      else
                        Text(
                          'Select a category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      if (_selectedCategoryId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Tap to change',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: cs.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryBottomSheet(ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.category_rounded, color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Business Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Choose the category that fits your business',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _businessCategories.length,
                itemBuilder: (context, index) {
                  final cat = _businessCategories[index];
                  final id = cat['id']?.toString() ?? '';
                  final name = cat['name']?.toString() ?? 'Unknown';
                  final isSelected = id == _selectedCategoryId;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategoryId = id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.12)
                                    : cs.onSurface.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _categoryIcon(name),
                                size: 20,
                                color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fashion') || lower.contains('cloth')) return Icons.checkroom_rounded;
    if (lower.contains('electronic') || lower.contains('tech')) return Icons.devices_rounded;
    if (lower.contains('food') || lower.contains('grocery')) return Icons.restaurant_rounded;
    if (lower.contains('beauty') || lower.contains('cosmetic')) return Icons.face_retouching_natural_rounded;
    if (lower.contains('health') || lower.contains('pharma')) return Icons.medical_services_rounded;
    if (lower.contains('home') || lower.contains('furniture')) return Icons.chair_rounded;
    if (lower.contains('sport') || lower.contains('fitness')) return Icons.sports_basketball_rounded;
    if (lower.contains('book') || lower.contains('station')) return Icons.menu_book_rounded;
    if (lower.contains('toy') || lower.contains('kid')) return Icons.toys_rounded;
    if (lower.contains('auto') || lower.contains('car')) return Icons.directions_car_rounded;
    return Icons.store_rounded;
  }

  void _onComplete() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      NotificationService().warning('Please select a business category');
      return;
    }
    final cubit = context.read<AuthCubit>();
    cubit.registerSeller(
      firstName: cubit.pendingFirstName ?? '',
      lastName: cubit.pendingLastName ?? '',
      email: cubit.pendingEmail ?? '',
      phone: cubit.pendingPhone ?? '',
      password: cubit.pendingPassword ?? '',
      businessName: _shopNameCtrl.text.trim(),
      businessCategoryIds: [_selectedCategoryId!],
      contactEmail: cubit.pendingEmail,
      contactPhone: cubit.pendingPhone,
    );
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthSellerRegisterSuccess) {
      NotificationService().success('Shop "${state.seller.businessName}" registered!');
      final phone = context.read<AuthCubit>().pendingPhone ?? '';
      context.go(
        AppConstants.verifyOtpRoute,
        extra: {'phone': phone, 'fromSeller': true},
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
                        borderRadius: BorderRadius.circular(12),
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
                    _buildCategorySelector(colorScheme),
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
                                borderRadius: BorderRadius.circular(10),
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
