import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/seller_cubit.dart';
import '../cubit/seller_state.dart';

class KycPage extends StatefulWidget {
  final bool showAsDialog;

  const KycPage({super.key, this.showAsDialog = false});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tinCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _nidaCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _mobileMoneyCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  String _selectedRegion = 'Dar es Salaam';
  String _selectedCity = 'Dar es Salaam';
  String _selectedPayment = 'Mobile Money';
  String _selectedIdType = 'NIDA';
  bool _isSubmitting = false;
  File? _shopLogo;
  File? _idFront;
  File? _idBack;
  final _picker = ImagePicker();

  final List<String> _regions = [
    'Dar es Salaam',
    'Dodoma',
    'Arusha',
    'Mwanza',
    'Mbeya',
    'Zanzibar',
    'Tanga',
    'Morogoro',
    'Kilimanjaro',
    'Mtwara',
    'Tabora',
    'Kigoma',
  ];

  final Map<String, List<String>> _cities = {
    'Dar es Salaam': ['Ilala', 'Kinondoni', 'Temeke', 'Ubungo', 'Kigamboni'],
    'Dodoma': ['Dodoma Urban', 'Chamwino', 'Bahi', 'Kondoa'],
    'Arusha': ['Arusha Urban', 'Arusha Rural', 'Meru', 'Karatu'],
    'Mwanza': ['Nyamagana', 'Ilemela', 'Sengerema', 'Geita'],
    'Mbeya': ['Mbeya Urban', 'Mbeya Rural', 'Rungwe', 'Kyela'],
    'Zanzibar': ['Mjini Magharibi', 'Kaskazini A', 'Kaskazini B', 'Kusini'],
    'Tanga': ['Tanga Urban', 'Muheza', 'Korogwe', 'Pangani'],
    'Morogoro': ['Morogoro Urban', 'Morogoro Rural', 'Kilosa', 'Ifakara'],
    'Kilimanjaro': ['Moshi Urban', 'Moshi Rural', 'Hai', 'Rombo'],
    'Mtwara': ['Mtwara Urban', 'Mtwara Rural', 'Tandahimba', 'Newala'],
    'Tabora': ['Tabora Urban', 'Uyui', 'Sikonge', 'Nzega'],
    'Kigoma': ['Kigoma Urban', 'Kigoma Rural', 'Kasulu', 'Kibondo'],
  };

  final List<String> _paymentMethods = ['Mobile Money', 'Bank Account'];
  final List<String> _idTypes = ['NIDA', 'Passport', 'Voter ID', 'Driving License'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SellerCubit>().refreshKyc();
    });
  }

  @override
  void dispose() {
    _tinCtrl.dispose();
    _licenseCtrl.dispose();
    _nidaCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _mobileMoneyCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        if (type == 'logo') _shopLogo = File(image.path);
        if (type == 'front') _idFront = File(image.path);
        if (type == 'back') _idBack = File(image.path);
      });
    }
  }

  Widget _buildImagePicker({
    required String label,
    required String type,
    File? image,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
    IconData icon = Icons.keyboard_arrow_down_rounded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surface.withValues(alpha: 0.6),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(
                icon,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
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
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idFront == null || _idBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload ID front and back images'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await context.read<SellerCubit>().submitKycDocuments(
          tinFile: _shopLogo,
          businessProfileFile: _idFront,
          businessRegistrationFile: _idBack,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final state = context.read<SellerCubit>().state;
    if (state is SellerActionSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
      if (widget.showAsDialog && context.canPop()) {
        context.pop();
      } else {
        context.go(AppConstants.sellerDashboardRoute);
      }
    } else if (state is SellerActionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              BackIconButton(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(
                                        AppConstants.sellerDashboardRoute);
                                  }
                                },
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'KYC Verification',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Complete your KYC to unlock payouts and start selling.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ─── Business Info ───
                          _buildSectionTitle('Business Information', colorScheme),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _tinCtrl,
                            label: 'TIN Number',
                            hint: 'e.g. 123-456-789',
                            icon: Icons.receipt_long_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter your TIN number' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _licenseCtrl,
                            label: 'Business License Number',
                            hint: 'e.g. BL-2026-00123',
                            icon: Icons.badge_outlined,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter business license number'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Region',
                            value: _selectedRegion,
                            items: _regions,
                            onChanged: (v) {
                              setState(() {
                                _selectedRegion = v ?? _selectedRegion;
                                _selectedCity =
                                    _cities[_selectedRegion]!.first;
                              });
                            },
                            colorScheme: colorScheme,
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'City / District',
                            value: _selectedCity,
                            items: _cities[_selectedRegion] ?? ['Dar es Salaam'],
                            onChanged: (v) =>
                                setState(() => _selectedCity = v ?? _selectedCity),
                            colorScheme: colorScheme,
                            icon: Icons.map_outlined,
                          ),
                          const SizedBox(height: 20),

                          // ─── Shop Logo ───
                          _buildSectionTitle('Shop Logo', colorScheme),
                          const SizedBox(height: 12),
                          _buildImagePicker(
                            label: 'Upload Shop Logo',
                            type: 'logo',
                            image: _shopLogo,
                            icon: Icons.store_outlined,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 24),

                          // ─── Payment Info ───
                          _buildSectionTitle('Payment Information', colorScheme),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'Preferred Payment Method',
                            value: _selectedPayment,
                            items: _paymentMethods,
                            onChanged: (v) => setState(
                                () => _selectedPayment = v ?? _selectedPayment),
                            colorScheme: colorScheme,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedPayment == 'Bank Account') ...[
                            AuthTextField(
                              controller: _bankNameCtrl,
                              label: 'Bank Name',
                              hint: 'e.g. CRDB Bank',
                              icon: Icons.account_balance_outlined,
                              textCapitalization: TextCapitalization.words,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter bank name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              controller: _bankAccountCtrl,
                              label: 'Bank Account Number',
                              hint: 'e.g. 0151234567890',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter account number'
                                  : null,
                            ),
                          ] else ...[
                            AuthTextField(
                              controller: _mobileMoneyCtrl,
                              label: 'Mobile Money Number',
                              hint: 'e.g. 0712345678',
                              icon: Icons.phone_android_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter mobile money number'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 24),

                          // ─── ID Verification ───
                          _buildSectionTitle('ID Verification', colorScheme),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            label: 'ID Type',
                            value: _selectedIdType,
                            items: _idTypes,
                            onChanged: (v) => setState(
                                () => _selectedIdType = v ?? _selectedIdType),
                            colorScheme: colorScheme,
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _nidaCtrl,
                            label: '$_selectedIdType Number',
                            hint: 'Enter your $_selectedIdType number',
                            icon: Icons.fingerprint_outlined,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your $_selectedIdType number'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload $_selectedIdType (Front)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImagePicker(
                            label: 'Upload ID Front',
                            type: 'front',
                            image: _idFront,
                            icon: Icons.document_scanner_outlined,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload $_selectedIdType (Back)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImagePicker(
                            label: 'Upload ID Back',
                            type: 'back',
                            image: _idBack,
                            icon: Icons.document_scanner_outlined,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 32),

                          // ─── Submit ───
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Submit KYC',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
