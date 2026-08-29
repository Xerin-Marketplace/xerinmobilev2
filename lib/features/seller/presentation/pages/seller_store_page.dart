import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';

class SellerStorePage extends StatefulWidget {
  const SellerStorePage({super.key});

  @override
  State<SellerStorePage> createState() => _SellerStorePageState();
}

class _SellerStorePageState extends State<SellerStorePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _aboutController = TextEditingController();
  final _slugController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _shippingPolicyController = TextEditingController();
  final _returnPolicyController = TextEditingController();

  String? _logoUrl;
  String? _bannerUrl;
  String _storeStatus = 'pending';
  bool _isVerified = false;
  bool _isFeatured = false;
  bool _vacationMode = false;
  bool _acceptOrders = true;
  double _rating = 0;
  int _reviewCount = 0;
  int _followersCount = 0;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadStore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _aboutController.dispose();
    _slugController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _shippingPolicyController.dispose();
    _returnPolicyController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> s) {
    _nameController.text = s['store_name']?.toString() ?? s['name']?.toString() ?? '';
    _descController.text = s['description']?.toString() ?? '';
    _aboutController.text = s['about']?.toString() ?? '';
    _slugController.text = s['slug']?.toString() ?? '';
    _countryController.text = s['country']?.toString() ?? '';
    _regionController.text = s['region']?.toString() ?? '';
    _districtController.text = s['district']?.toString() ?? '';
    _wardController.text = s['ward']?.toString() ?? '';
    _streetController.text = s['street']?.toString() ?? '';
    _phoneController.text = s['contact_phone']?.toString() ?? s['phone']?.toString() ?? '';
    _whatsappController.text = s['whatsapp_phone']?.toString() ?? '';
    _emailController.text = s['contact_email']?.toString() ?? s['email']?.toString() ?? '';
    _websiteController.text = s['website_url']?.toString() ?? '';
    _facebookController.text = s['facebook_url']?.toString() ?? '';
    _instagramController.text = s['instagram_url']?.toString() ?? '';
    _tiktokController.text = s['tiktok_url']?.toString() ?? '';
    _shippingPolicyController.text = s['shipping_policy']?.toString() ?? '';
    _returnPolicyController.text = s['return_policy']?.toString() ?? '';
    _logoUrl = s['logo_url']?.toString();
    _bannerUrl = s['banner_url']?.toString();
    _storeStatus = s['status']?.toString() ?? 'pending';
    _isVerified = s['is_verified'] as bool? ?? false;
    _isFeatured = s['is_featured'] as bool? ?? false;
    _vacationMode = s['vacation_mode'] as bool? ?? false;
    _acceptOrders = s['accept_orders'] as bool? ?? true;
    _rating = (s['rating'] as num?)?.toDouble() ?? 0;
    _reviewCount = s['review_count'] as int? ?? 0;
    _followersCount = s['followers_count'] as int? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('My Store')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          if (state is SellerStoreLoaded) {
            setState(() => _populateForm(state.store));
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerError && _nameController.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerCubit>().loadStore(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _buildBannerSection(context, cs, isDark),
              const SizedBox(height: 16),
              _buildStatsRow(cs, isDark),
              const SizedBox(height: 12),
              _buildStatusBadges(cs),
              const SizedBox(height: 20),
              _buildStoreUrlCard(context, cs, isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildSectionCard(cs, isDark, 'Store Information', Uicons.shop, [
                      _buildField(_nameController, 'Store Name', cs),
                      const SizedBox(height: 12),
                      _buildField(_descController, 'Short Description', cs, maxLines: 2),
                      const SizedBox(height: 12),
                      _buildField(_aboutController, 'About Store', cs, maxLines: 4),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionCard(cs, isDark, 'Contact', Uicons.phone, [
                      _buildField(_phoneController, 'Phone', cs, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildField(_whatsappController, 'WhatsApp', cs, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildField(_emailController, 'Email', cs, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildField(_websiteController, 'Website', cs, keyboardType: TextInputType.url),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionCard(cs, isDark, 'Location', Uicons.mapPin, [
                      _buildField(_countryController, 'Country', cs),
                      const SizedBox(height: 12),
                      _buildField(_regionController, 'Region', cs),
                      const SizedBox(height: 12),
                      _buildField(_districtController, 'District', cs),
                      const SizedBox(height: 12),
                      _buildField(_wardController, 'Ward', cs),
                      const SizedBox(height: 12),
                      _buildField(_streetController, 'Street', cs),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionCard(cs, isDark, 'Social Media', Uicons.globe, [
                      _buildField(_facebookController, 'Facebook', cs, keyboardType: TextInputType.url),
                      const SizedBox(height: 12),
                      _buildField(_instagramController, 'Instagram', cs, keyboardType: TextInputType.url),
                      const SizedBox(height: 12),
                      _buildField(_tiktokController, 'TikTok', cs, keyboardType: TextInputType.url),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionCard(cs, isDark, 'Policies', Uicons.shieldCheck, [
                      _buildField(_shippingPolicyController, 'Shipping Policy', cs, maxLines: 3),
                      const SizedBox(height: 12),
                      _buildField(_returnPolicyController, 'Return Policy', cs, maxLines: 3),
                    ]),
                    const SizedBox(height: 16),
                    _buildToggleCard(cs, isDark),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              final data = <String, dynamic>{
                                'store_name': _nameController.text.trim(),
                                'description': _descController.text.trim(),
                                'about': _aboutController.text.trim(),
                                'country': _countryController.text.trim(),
                                'region': _regionController.text.trim(),
                                'district': _districtController.text.trim(),
                                'ward': _wardController.text.trim(),
                                'street': _streetController.text.trim(),
                                'contact_phone': _phoneController.text.trim(),
                                'whatsapp_phone': _whatsappController.text.trim(),
                                'contact_email': _emailController.text.trim(),
                                'website_url': _websiteController.text.trim(),
                                'facebook_url': _facebookController.text.trim(),
                                'instagram_url': _instagramController.text.trim(),
                                'tiktok_url': _tiktokController.text.trim(),
                                'shipping_policy': _shippingPolicyController.text.trim(),
                                'return_policy': _returnPolicyController.text.trim(),
                                'vacation_mode': _vacationMode,
                                'accept_orders': _acceptOrders,
                              };
                              await context.read<SellerCubit>().updateStore(data);
                              setState(() => _isSaving = false);
                            },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Uicons.check),
                      label: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context, ColorScheme cs, bool isDark) {
    final resolvedBanner = ApiConstants.resolveImageUrl(_bannerUrl);
    final resolvedLogo = ApiConstants.resolveImageUrl(_logoUrl);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : () => _pickAndUploadImage(context, isLogo: false),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (resolvedBanner != null)
                  Positioned.fill(
                    child: Image.network(
                      resolvedBanner,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.primary.withValues(alpha: 0.3),
                        child: Center(
                          child: Icon(Uicons.imageSlash, size: 32, color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isVerified)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Uicons.badgeCheck, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Verified', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Uicons.camera, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text('Change Banner', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -35,
          left: 20,
          child: GestureDetector(
            onTap: _isUploading ? null : () => _pickAndUploadImage(context, isLogo: true),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: ClipOval(
                child: resolvedLogo != null
                    ? Image.network(
                        resolvedLogo,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: cs.primary.withValues(alpha: 0.1),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: cs.primary.withValues(alpha: 0.1),
                          child: Icon(Uicons.shop, size: 28, color: cs.primary),
                        ),
                      )
                    : Container(
                        color: cs.primary.withValues(alpha: 0.1),
                        child: Icon(Uicons.shop, size: 32, color: cs.primary),
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -22,
          left: 82,
          child: GestureDetector(
            onTap: _isUploading ? null : () => _pickAndUploadImage(context, isLogo: true),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Icon(Uicons.camera, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme cs, bool isDark) {
    final stats = [
      ('Rating', _rating.toStringAsFixed(1), Uicons.star, Colors.amber),
      ('Followers', '$_followersCount', Uicons.heart, Colors.pink),
      ('Reviews', '$_reviewCount', Uicons.comments, Colors.blue),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats.map((s) {
          final (label, value, icon, color) = s;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(label, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadges(ColorScheme cs) {
    final statusInfo = _getStatusInfo(_storeStatus);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusInfo.$2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusInfo.$2.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusInfo.$3, size: 12, color: statusInfo.$2),
                const SizedBox(width: 4),
                Text(statusInfo.$1,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusInfo.$2)),
              ],
            ),
          ),
          if (_isFeatured) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Uicons.star, size: 12, color: Colors.amber[700]),
                  const SizedBox(width: 4),
                  Text('Featured Store',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber[700])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color, IconData) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return ('Active', const Color(0xFF22C55E), Uicons.checkCircle);
      case 'pending':
        return ('Pending', Colors.orange, Uicons.clock);
      case 'suspended':
        return ('Suspended', Colors.red, Uicons.circleXmark);
      case 'rejected':
        return ('Rejected', Colors.red, Uicons.circleXmark);
      default:
        return (status, Colors.grey, Uicons.circle);
    }
  }

  Widget _buildStoreUrlCard(BuildContext context, ColorScheme cs, bool isDark) {
    final slug = _slugController.text.trim();
    final url = slug.isNotEmpty ? 'xerinmarketplace.com/store/$slug' : 'xerinmarketplace.com/store/...';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Uicons.globe, size: 16, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Store URL',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 2),
                  Text(url,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (slug.isNotEmpty)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Uicons.copy, size: 16, color: cs.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(ColorScheme cs, bool isDark, String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, ColorScheme cs,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildToggleCard(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            cs, 'Accept Orders', 'Allow customers to place orders', _acceptOrders,
            (v) => setState(() => _acceptOrders = v), Uicons.shoppingBag,
          ),
          const Divider(height: 24),
          _buildToggleRow(
            cs, 'Vacation Mode', 'Temporarily close your store', _vacationMode,
            (v) => setState(() => _vacationMode = v), Uicons.pause,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(ColorScheme cs, String title, String subtitle, bool value,
      Function(bool) onChanged, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: (value ? cs.primary : cs.onSurface).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: value ? cs.primary : cs.onSurface.withValues(alpha: 0.4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: cs.primary,
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, {required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

      setState(() => _isUploading = true);
      if (isLogo) {
        await context.read<SellerCubit>().uploadStoreLogo(image.path);
      } else {
        await context.read<SellerCubit>().uploadStoreBanner(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
