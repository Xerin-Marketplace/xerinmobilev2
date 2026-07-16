import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/seller_cubit.dart';
import '../cubit/seller_state.dart';

class ShopDetailsPage extends StatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  final _shopNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _populateFromStore(store) {
    if (store == null || _initialized) return;
    _shopNameCtrl.text = store.storeName ?? '';
    _phoneCtrl.text = store.contactPhone ?? '';
    _emailCtrl.text = store.contactEmail ?? '';
    _addressCtrl.text = [
      store.street,
      store.ward,
      store.district,
      store.region,
      store.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    _descriptionCtrl.text = store.description ?? '';
    _websiteCtrl.text = store.websiteUrl ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      'store_name': _shopNameCtrl.text,
      'contact_phone': _phoneCtrl.text,
      'contact_email': _emailCtrl.text,
      'description': _descriptionCtrl.text,
      'website_url': _websiteCtrl.text,
    };
    await context.read<SellerCubit>().updateStore(data);
    if (!mounted) return;
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SellerCubit, SellerState>(
          builder: (context, state) {
            if (state is SellerDashboardLoaded) {
              _populateFromStore(state.store);
            }

            if (state is SellerActionSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFF22C55E),
                  ),
                );
              });
            }

            if (state is SellerActionError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: const Color(0xFFE53935),
                  ),
                );
              });
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BackIconButton(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppConstants.sellerDashboardRoute);
                                }
                              },
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Shop Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: state is SellerDashboardLoaded &&
                                        state.store?.logoUrl != null &&
                                        state.store!.logoUrl!.isNotEmpty
                                    ? Image.network(
                                        state.store!.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Icon(
                                          Icons.store_rounded,
                                          color: colorScheme.primary,
                                          size: 48,
                                        ),
                                      )
                                    : Icon(
                                        Icons.store_rounded,
                                        color: colorScheme.primary,
                                        size: 48,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildField('Shop Name', _shopNameCtrl,
                            Icons.store_outlined, colorScheme),
                        const SizedBox(height: 16),
                        _buildField('Phone Number', _phoneCtrl,
                            Icons.phone_outlined, colorScheme),
                        const SizedBox(height: 16),
                        _buildField('Email Address', _emailCtrl,
                            Icons.email_outlined, colorScheme),
                        const SizedBox(height: 16),
                        _buildField('Website', _websiteCtrl,
                            Icons.language_outlined, colorScheme),
                        const SizedBox(height: 16),
                        _buildField('Shop Address', _addressCtrl,
                            Icons.location_on_outlined, colorScheme,
                            maxLines: 3),
                        const SizedBox(height: 16),
                        _buildField('Description', _descriptionCtrl,
                            Icons.description_outlined, colorScheme,
                            maxLines: 4),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      ColorScheme colorScheme,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
