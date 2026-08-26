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
  final _slugController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _logoUrl;
  String? _bannerUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadStore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _slugController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> store) {
    _nameController.text = store['name']?.toString() ?? '';
    _descController.text = store['description']?.toString() ?? '';
    _slugController.text = store['slug']?.toString() ?? '';
    _countryController.text = store['country']?.toString() ?? '';
    _cityController.text = store['city']?.toString() ?? '';
    _addressController.text = store['address']?.toString() ?? '';
    _phoneController.text = store['phone']?.toString() ?? '';
    _emailController.text = store['email']?.toString() ?? '';
    _logoUrl = store['logo_url']?.toString();
    _bannerUrl = store['banner_url']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
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
            _populateForm(state.store);
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
            padding: const EdgeInsets.all(16),
            children: [
              // Logo & Banner
              _buildImageSection(context),
              const SizedBox(height: 24),
              // Form fields
              _buildTextField(_nameController, 'Store Name'),
              const SizedBox(height: 12),
              _buildTextField(_descController, 'Description', maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(_slugController, 'Slug (URL)'),
              const SizedBox(height: 12),
              _buildTextField(_countryController, 'Country'),
              const SizedBox(height: 12),
              _buildTextField(_cityController, 'City'),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Address'),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Phone', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 24),
              // Save button
              FilledButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        final data = <String, dynamic>{
                          'name': _nameController.text.trim(),
                          'description': _descController.text.trim(),
                          'slug': _slugController.text.trim(),
                          'country': _countryController.text.trim(),
                          'city': _cityController.text.trim(),
                          'address': _addressController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'email': _emailController.text.trim(),
                        };
                        await context.read<SellerCubit>().updateStore(data);
                        setState(() => _isSaving = false);
                      },
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Uicons.check),
                label: const Text('Save Changes'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Column(
      children: [
        // Banner
        GestureDetector(
          onTap: () => _pickAndUploadImage(context, isLogo: false),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _bannerUrl != null
                  ? Image.network(
                      ApiConstants.resolveImageUrl(_bannerUrl) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder('Banner'),
                    )
                  : _buildImagePlaceholder('Banner'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logo
        GestureDetector(
          onTap: () => _pickAndUploadImage(context, isLogo: true),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ClipOval(
              child: _logoUrl != null
                  ? Image.network(
                      ApiConstants.resolveImageUrl(_logoUrl) ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder('Logo', isCircle: true),
                    )
                  : _buildImagePlaceholder('Logo', isCircle: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String label, {bool isCircle = false}) {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCircle ? Uicons.camera : Uicons.image, color: Colors.grey, size: isCircle ? 24 : 32),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, {required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

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
    }
  }
}
