import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../config/constants/app_constants.dart';
import '../../../auth/data/models/user_model.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';
import '../../data/models/address_model.dart';
import '../../data/models/cart_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  String? _selectedAddressId;
  String _selectedPaymentMethod = 'mobile_money';
  bool _isProcessing = false;

  String _deliveryMode = 'local';
  bool _isDetectingMode = false;
  Map<String, dynamic>? _detectedMode;

  List<Map<String, dynamic>> _logisticsCompanies = [];
  String? _selectedCompanyId;
  bool _isLoadingLogistics = false;

  List<Map<String, dynamic>> _pricingOptions = [];
  Map<String, dynamic>? _selectedRate;
  bool _isLoadingPricing = false;

  Map<String, dynamic>? _frozenQuote;
  bool _isFreezingQuote = false;

  String? _appliedCouponCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCubit>().loadAll();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _phoneController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  double get _shippingAmount {
    if (_frozenQuote != null) return _parsePrice(_frozenQuote!['delivery_amount']);
    if (_selectedRate != null) return _parsePrice(_selectedRate!['delivery_amount']);
    return 0.0;
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'TZS $formatted';
  }

  static const _tzRegions = [
    'Dar es Salaam', 'Dodoma', 'Arusha', 'Mwanza', 'Mbeya', 'Morogoro',
    'Tanga', 'Kilimanjaro', 'Zanzibar', 'Mtwara', 'Lindi', 'Ruvuma',
    'Iringa', 'Njombe', 'Songwe', 'Rukwa', 'Katavi', 'Kigoma', 'Geita',
    'Shinyanga', 'Simiyu', 'Kagera', 'Mara', 'Manyara', 'Singida', 'Tabora', 'Pwani',
  ];

  Future<void> _detectDeliveryMode() async {
    if (_selectedAddressId == null) return;
    setState(() => _isDetectingMode = true);
    try {
      final result = await context.read<CustomerCubit>().detectDeliveryMode(_selectedAddressId!);
      setState(() {
        _detectedMode = result;
        _isDetectingMode = false;
        final mode = result?['delivery_mode'] as String?;
        if (mode != null && mode != _deliveryMode) {
          _deliveryMode = mode;
          _logisticsCompanies = [];
          _selectedCompanyId = null;
          _pricingOptions = [];
          _selectedRate = null;
          _frozenQuote = null;
        }
      });
      if (mounted && result != null) _fetchEligibleLogistics();
    } catch (e) {
      setState(() => _isDetectingMode = false);
      if (mounted) NotificationService().error('Failed to detect delivery mode: $e');
    }
  }

  Future<void> _fetchEligibleLogistics() async {
    if (_selectedAddressId == null) return;
    setState(() => _isLoadingLogistics = true);
    try {
      final result = await context.read<CustomerCubit>().getEligibleLogistics(
        addressId: _selectedAddressId!,
        deliveryMode: _deliveryMode,
      );
      final companies = <Map<String, dynamic>>[];
      if (result != null) {
        final rawResults = result['results'];
        if (rawResults is List) {
          companies.addAll(rawResults.cast<Map<String, dynamic>>());
        }
      }
      setState(() {
        _logisticsCompanies = companies;
        _isLoadingLogistics = false;
        if (companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = companies.first['logistics_company_id']?.toString();
          _fetchMultiSellerPricing();
        }
      });
    } catch (e) {
      setState(() => _isLoadingLogistics = false);
      if (mounted) NotificationService().error('Failed to load logistics companies: $e');
    }
  }

  Future<void> _fetchMultiSellerPricing() async {
    if (_selectedAddressId == null || _selectedCompanyId == null) return;
    setState(() {
      _isLoadingPricing = true;
      _pricingOptions = [];
      _selectedRate = null;
      _frozenQuote = null;
    });
    try {
      final result = await context.read<CustomerCubit>().getMultiSellerPricing(
        addressId: _selectedAddressId!,
        logisticsCompanyId: _selectedCompanyId!,
        deliveryMode: _deliveryMode,
      );
      final options = <Map<String, dynamic>>[];
      if (result != null) {
        final rawOptions = result['options'];
        if (rawOptions is List) {
          options.addAll(rawOptions.cast<Map<String, dynamic>>());
        }
      }
      setState(() {
        _pricingOptions = options;
        _isLoadingPricing = false;
      });
    } catch (e) {
      setState(() => _isLoadingPricing = false);
      if (mounted) NotificationService().error('Failed to load pricing: $e');
    }
  }

  Future<void> _freezeQuote() async {
    if (_selectedAddressId == null || _selectedCompanyId == null || _selectedRate == null) return;
    final rateId = _selectedRate!['rate_id']?.toString();
    if (rateId == null) return;
    setState(() => _isFreezingQuote = true);
    try {
      final result = await context.read<CustomerCubit>().freezeDeliveryQuote(
        addressId: _selectedAddressId!,
        logisticsCompanyId: _selectedCompanyId!,
        rateId: rateId,
        deliveryMode: _deliveryMode,
      );
      setState(() {
        _frozenQuote = result;
        _isFreezingQuote = false;
      });
    } catch (e) {
      setState(() => _isFreezingQuote = false);
      if (mounted) NotificationService().error('Failed to lock delivery quote: $e');
    }
  }

  void _onCompanyChanged(String companyId) {
    setState(() {
      _selectedCompanyId = companyId;
      _pricingOptions = [];
      _selectedRate = null;
      _frozenQuote = null;
    });
    _fetchMultiSellerPricing();
  }

  void _onRateSelected(Map<String, dynamic> rate) {
    setState(() {
      _selectedRate = rate;
      _frozenQuote = null;
    });
    _freezeQuote();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null) {
      NotificationService().warning('Please select a delivery address');
      return;
    }
    if (_selectedRate == null) {
      NotificationService().warning('Please select a delivery service');
      return;
    }
    if (_frozenQuote == null) {
      NotificationService().warning('Please wait for the delivery quote to lock');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      NotificationService().warning('Please enter your mobile money number');
      return;
    }

    setState(() => _isProcessing = true);

    final cubit = context.read<CustomerCubit>();
    final rateId = _selectedRate!['rate_id']?.toString();
    final quoteId = _frozenQuote!['id']?.toString();

    await cubit.placeOrderAndPay(
      shippingAddressId: _selectedAddressId!,
      shippingRateId: rateId,
      deliveryQuoteId: quoteId,
      deliveryMode: _deliveryMode,
      couponCode: _appliedCouponCode,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final state = cubit.state;

    if (state is PaymentFailed) {
      NotificationService().error(state.message);
      return;
    }

    if (state is PaymentSuccess) {
      context.read<CartCubit>().clearCart();
      NotificationService().success('Order placed successfully!');

      if (state.checkoutUrl != null) {
        context.go('/payment-processing?payment_id=${state.paymentId}&order_id=${state.orderId}&checkout_url=${Uri.encodeComponent(state.checkoutUrl!)}');
      } else if (state.paymentId.isNotEmpty) {
        context.go('/payment-processing?payment_id=${state.paymentId}&order_id=${state.orderId}');
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = context.watch<CartCubit>().state;
    final cartItems = cartState is CartLoaded ? cartState.cart.items : <CartItemModel>[];
    final cartTotal = cartState is CartLoaded ? cartState.cart.total : 0.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CustomerCubit, CustomerState>(
          builder: (context, state) {
            final addresses = state is CustomerLoaded ? state.addresses : <AddressModel>[];
            final isLoading = state is CustomerLoading;

            if (isLoading && addresses.isEmpty) {
              return _buildLoadingState(colorScheme);
            }

            if (_selectedAddressId == null && addresses.isNotEmpty) {
              final defaultAddr = addresses.where((a) => a.isDefault).firstOrNull;
              final addr = defaultAddr ?? addresses.first;
              _selectedAddressId = addr.id;
              if (_recipientNameController.text.isEmpty && addr.recipientName != null) {
                _recipientNameController.text = addr.recipientName!;
              }
              if (_recipientPhoneController.text.isEmpty && addr.recipientPhone != null) {
                _recipientPhoneController.text = addr.recipientPhone!;
              }
              _detectDeliveryMode();
            }

            if (cartItems.isEmpty) {
              return _buildEmptyCart(colorScheme);
            }

            return _buildCheckoutSheet(
              colorScheme,
              isDark,
              cartItems,
              cartTotal,
              addresses,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs) {
    return Column(
      children: [
        _buildHeader(cs),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildEmptyCart(ColorScheme cs) {
    return Column(
      children: [
        _buildHeader(cs),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Your cart is empty',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text('Add items to checkout',
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checkout',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                Text('Review and complete your order',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSheet(
    ColorScheme cs,
    bool isDark,
    List<CartItemModel> cartItems,
    double cartTotal,
    List<AddressModel> addresses,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemsSection(cs, isDark, cartItems),
                      const SizedBox(height: 12),
                      _buildDeliverySection(cs, isDark, addresses),
                      const SizedBox(height: 12),
                      _buildCustomerSection(cs, isDark, addresses),
                      const SizedBox(height: 12),
                      _buildDeliveryModeSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildLogisticsSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildPaymentSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildNotesSection(cs, isDark),
                      const SizedBox(height: 12),
                      _buildSummarySection(cs, isDark, cartTotal),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(cs, isDark, cartTotal),
          ],
        ),
        if (_isProcessing) _buildProcessingOverlay(cs),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required ColorScheme cs,
    required bool isDark,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildItemsSection(ColorScheme cs, bool isDark, List<CartItemModel> cartItems) {
    return _buildSection(
      title: 'Order Items',
      cs: cs,
      isDark: isDark,
      child: Column(
        children: cartItems.map((item) => _buildCartItemRow(item, cs)).toList(),
      ),
    );
  }

  Widget _buildDeliverySection(ColorScheme cs, bool isDark, List<AddressModel> addresses) {
    final selectedAddr = addresses.where((a) => a.id == _selectedAddressId).firstOrNull;

    return _buildSection(
      title: 'Delivery Address',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedAddr != null) ...[
            if (selectedAddr.label != null && selectedAddr.label!.isNotEmpty)
              Text(selectedAddr.label!,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            Text(selectedAddr.street,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            Text('${selectedAddr.city}, ${selectedAddr.region}, ${selectedAddr.country}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            if (selectedAddr.recipientName != null && selectedAddr.recipientName!.isNotEmpty)
              Text('${selectedAddr.recipientName}${selectedAddr.recipientPhone != null && selectedAddr.recipientPhone!.isNotEmpty ? ' · ${selectedAddr.recipientPhone}' : ''}',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showAddressPicker(cs, isDark, addresses),
                  child: Text('Change address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showAddAddressDrawer(cs, isDark),
                  child: Text('Add new',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ),
              ],
            ),
          ] else if (addresses.isEmpty) ...[
            Text('No delivery address yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Text('Add an address to proceed with checkout',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => _showAddAddressDrawer(cs, isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Add Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            ...addresses.map((addr) => _buildAddressSelector(addr, cs, isDark)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAddAddressDrawer(cs, isDark),
              child: Text('Add new address',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ColorScheme cs, bool isDark, List<AddressModel> addresses) {
    final user = GetIt.instance<TokenStorage>().currentUser;
    final selectedAddr = addresses.where((a) => a.id == _selectedAddressId).firstOrNull;

    final displayName = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Not configured';
    final displayEmail = (user?.email.isNotEmpty == true) ? user!.email : 'Not configured';
    final displayPhone = selectedAddr?.recipientPhone?.isNotEmpty == true
        ? selectedAddr!.recipientPhone!
        : (user?.phone?.isNotEmpty == true ? user!.phone! : 'Not configured');

    return _buildSection(
      title: 'Customer',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(displayName,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppConstants.profileInfoRoute),
                child: Text('Edit profile',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCustomerInfoRow(label: 'Email', value: displayEmail, cs: cs, isMissing: displayEmail == 'Not configured'),
          const SizedBox(height: 8),
          _buildCustomerInfoRow(label: 'Phone', value: displayPhone, cs: cs, isMissing: displayPhone == 'Not configured'),
          const SizedBox(height: 8),
          _buildCustomerInfoRow(
            label: 'Delivery address',
            value: selectedAddr != null
                ? '${selectedAddr.street}, ${selectedAddr.city}, ${selectedAddr.region}'
                : 'Select a delivery address above',
            cs: cs,
            isMissing: selectedAddr == null,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoRow({
    required String label,
    required String value,
    required ColorScheme cs,
    bool isMissing = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
        ),
        Flexible(
          child: Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMissing
                  ? const Color(0xFFE53935).withValues(alpha: 0.6)
                  : cs.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showAddressPicker(ColorScheme cs, bool isDark, List<AddressModel> addresses) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
            ),
            ...addresses.map((addr) => GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAddressId = addr.id;
                  if (addr.recipientName != null && _recipientNameController.text.isEmpty) {
                    _recipientNameController.text = addr.recipientName!;
                  }
                  if (addr.recipientPhone != null && _recipientPhoneController.text.isEmpty) {
                    _recipientPhoneController.text = addr.recipientPhone!;
                  }
                  _logisticsCompanies = [];
                  _selectedCompanyId = null;
                  _pricingOptions = [];
                  _selectedRate = null;
                  _frozenQuote = null;
                });
                _detectDeliveryMode();
                Navigator.pop(ctx);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (addr.label != null && addr.label!.isNotEmpty)
                            Text(addr.label!,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                            ),
                          Text(addr.street,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                          Text(addr.fullAddress,
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildRadioDot(_selectedAddressId == addr.id, cs.primary),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryModeSection(ColorScheme cs, bool isDark) {
    final isCrossBorder = _deliveryMode == 'international';
    return _buildSection(
      title: 'Delivery Route',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDetectingMode)
            Row(
              children: [
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                ),
                const SizedBox(width: 8),
                Text('Detecting delivery route...',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            )
          else ...[
            Text(
              isCrossBorder ? 'International / Cross-border' : 'Domestic / Local',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              isCrossBorder
                ? 'Products ship from a different country'
                : 'All products ship within the same country',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            if (_detectedMode != null && _detectedMode!['origins'] is List && (_detectedMode!['origins'] as List).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${(_detectedMode!['origins'] as List).length} store route${(_detectedMode!['origins'] as List).length == 1 ? '' : 's'} detected',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Delivery Service',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingLogistics) ...[
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
          ] else if (_logisticsCompanies.isEmpty) ...[
            Text('No logistics available',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            Text(_selectedAddressId == null ? 'Select an address first' : 'No companies cover this route',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3)),
            ),
          ] else ...[
            Text('Logistics Company',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 10),
            ..._logisticsCompanies.map((company) => _buildLogisticsCompanyCard(company, cs, isDark)),
            if (_selectedCompanyId != null) ...[
              const SizedBox(height: 16),
              Text('Delivery Options',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 10),
              if (_isLoadingPricing)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else if (_pricingOptions.isEmpty)
                Text('No pricing available', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)))
              else
                ..._pricingOptions.map((option) => _buildPricingOption(option, cs, isDark)),
              if (_frozenQuote != null) ...[
                const SizedBox(height: 8),
                Text('Delivery quote locked',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF22C55E)),
                ),
              ] else if (_selectedRate != null && _isFreezingQuote)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsCompanyCard(Map<String, dynamic> company, ColorScheme cs, bool isDark) {
    final isSelected = _selectedCompanyId == company['logistics_company_id']?.toString();
    final name = company['name'] as String? ?? 'Logistics Company';
    final coveredSellers = company['covered_seller_count'] as int? ?? 0;
    final totalSellers = company['seller_count'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _onCompanyChanged(company['logistics_company_id']?.toString() ?? ''),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? cs.primary : cs.onSurface),
                  ),
                  Text('Covers $coveredSellers of $totalSellers sellers',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingOption(Map<String, dynamic> option, ColorScheme cs, bool isDark) {
    final isSelected = _selectedRate?['rate_id'] == option['rate_id'];
    final methodName = option['method_name'] as String? ?? 'Delivery';
    final amount = _parsePrice(option['delivery_amount']);
    final minDays = option['min_delivery_days'] as int? ?? 1;
    final maxDays = option['max_delivery_days'] as int? ?? 7;
    final isFree = amount == 0;

    return GestureDetector(
      onTap: () => _onRateSelected(option),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(methodName,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? cs.primary : cs.onSurface),
                  ),
                  Text('$minDays-$maxDays business days',
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(isFree ? 'FREE' : _formatCurrency(amount),
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: isFree ? const Color(0xFF22C55E) : cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Payment Method',
      cs: cs,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mobile Money',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF22C55E)),
          ),
          Text('Pay via M-Pesa, Airtel Money, HaloPesa or Mixx',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          _buildPhoneInput(cs),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ColorScheme cs, bool isDark) {
    return _buildSection(
      title: 'Order Notes',
      cs: cs,
      isDark: isDark,
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Any special instructions for delivery...',
          hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSummarySection(ColorScheme cs, bool isDark, double cartTotal) {
    return _buildSection(
      title: 'Order Summary',
      cs: cs,
      isDark: isDark,
      child: _buildSummaryContent(cartTotal, cs),
    );
  }

  Widget _buildBottomBar(ColorScheme cs, bool isDark, double cartTotal) {
    final total = cartTotal + _shippingAmount;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                Text(_formatCurrency(total),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Processing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : Text('Pay ${_formatCurrency(total)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(ColorScheme cs) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48, height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text('Processing Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Text('Please wait while we confirm your payment...',
                style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(double cartTotal, ColorScheme cs) {
    final shipping = _shippingAmount;
    final discount = cartTotal - (context.read<CartCubit>().state is CartLoaded ? (context.read<CartCubit>().state as CartLoaded).cart.total : cartTotal);
    final grandTotal = cartTotal + shipping - (discount > 0 ? discount : 0);
    return Column(
      children: [
        _summaryRow('Subtotal', _formatCurrency(cartTotal), cs),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Discount', '- ${_formatCurrency(discount)}', cs, color: const Color(0xFF22C55E)),
        ],
        const SizedBox(height: 8),
        _summaryRow('Shipping', _selectedRate == null ? 'Select a service' : _formatCurrency(shipping), cs),
        const SizedBox(height: 8),
        _summaryRow('Tax', 'Included', cs),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text(_formatCurrency(grandTotal),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Money Number',
            labelStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
            hintText: 'e.g. 0712345678',
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
            prefixText: '+255 ',
            prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showAddAddressDrawer(ColorScheme cs, bool isDark) {
    final labelCtrl = TextEditingController();
    final recipientNameCtrl = TextEditingController();
    final recipientPhoneCtrl = TextEditingController();
    final countryCtrl = TextEditingController(text: 'Tanzania');
    final regionCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    final wardCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final landmarkCtrl = TextEditingController();
    final postalCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    double? savedLatitude;
    double? savedLongitude;
    bool isFetchingLocation = false;
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text('Add Delivery Address',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(Icons.close, size: 22, color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(ctx).viewInsets.bottom,
                        left: 20, right: 20, top: 16,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isFetchingLocation ? null : () async {
                                setModalState(() => isFetchingLocation = true);
                                try {
                                  final location = await GetIt.instance<LocationService>().getCurrentLocation();
                                  setModalState(() {
                                    if (location.country != null) countryCtrl.text = location.country!;
                                    if (location.region != null) regionCtrl.text = location.region!;
                                    if (location.city != null) cityCtrl.text = location.city!;
                                    if (location.district != null) districtCtrl.text = location.district!;
                                    if (location.ward != null) wardCtrl.text = location.ward!;
                                    if (location.street != null) streetCtrl.text = location.street!;
                                    if (location.postalCode != null) postalCtrl.text = location.postalCode!;
                                    if (location.landmark != null) landmarkCtrl.text = location.landmark!;
                                    savedLatitude = location.latitude;
                                    savedLongitude = location.longitude;
                                    isFetchingLocation = false;
                                  });
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Location detected: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                                        backgroundColor: const Color(0xFF22C55E),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isFetchingLocation = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                                        backgroundColor: const Color(0xFFE53935),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: isFetchingLocation
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location, size: 18),
                              label: Text(isFetchingLocation ? 'Detecting location...' : 'Use My Current Location'),
                            ),
                            const SizedBox(height: 16),
                            _drawerField(label: 'Address label', hint: 'e.g. Home, Work', controller: labelCtrl, cs: cs, required: false),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Recipient name', hint: 'Person receiving delivery', controller: recipientNameCtrl, cs: cs, required: false),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Recipient phone', hint: '+255...', controller: recipientPhoneCtrl, cs: cs, required: false, keyboardType: TextInputType.phone),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Country', hint: 'Tanzania', controller: countryCtrl, cs: cs, required: true, readOnly: true),
                            const SizedBox(height: 12),
                            _drawerDropdown(label: 'Region (official)', hint: 'Select official region', controller: regionCtrl, items: _tzRegions, cs: cs, required: true),
                            const SizedBox(height: 12),
                            _drawerField(label: 'District', hint: 'e.g. Kinondoni', controller: districtCtrl, cs: cs, required: false),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Ward', hint: 'e.g. Mikocheni', controller: wardCtrl, cs: cs, required: false),
                            const SizedBox(height: 12),
                            _drawerField(label: 'City', hint: 'e.g. Dar es Salaam', controller: cityCtrl, cs: cs, required: true),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Street / address line', hint: 'Street, building and house number', controller: streetCtrl, cs: cs, required: true),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Landmark', hint: 'Near...', controller: landmarkCtrl, cs: cs, required: false),
                            const SizedBox(height: 12),
                            _drawerField(label: 'Postal code', hint: 'Optional', controller: postalCtrl, cs: cs, required: false, keyboardType: TextInputType.number),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              value: isDefault,
                              onChanged: (v) => setModalState(() => isDefault = v ?? false),
                              title: Text('Use as default delivery address',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                              subtitle: Text('Checkout will prefer this address.',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.15)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('Cancel',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          Navigator.pop(ctx);
                                          context.read<CustomerCubit>().addAddress(
                                            country: countryCtrl.text.trim(),
                                            region: regionCtrl.text.trim(),
                                            city: cityCtrl.text.trim(),
                                            street: streetCtrl.text.trim(),
                                            postalCode: postalCtrl.text.trim().isEmpty ? null : postalCtrl.text.trim(),
                                            label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                                            recipientName: recipientNameCtrl.text.trim().isEmpty ? null : recipientNameCtrl.text.trim(),
                                            recipientPhone: recipientPhoneCtrl.text.trim().isEmpty ? null : recipientPhoneCtrl.text.trim(),
                                            district: districtCtrl.text.trim().isEmpty ? null : districtCtrl.text.trim(),
                                            ward: wardCtrl.text.trim().isEmpty ? null : wardCtrl.text.trim(),
                                            landmark: landmarkCtrl.text.trim().isEmpty ? null : landmarkCtrl.text.trim(),
                                            latitude: savedLatitude,
                                            longitude: savedLongitude,
                                            isDefault: isDefault,
                                          ).then((_) {
                                            NotificationService().success('Address added successfully');
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cs.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: const Text('Add Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _drawerField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ColorScheme cs,
    bool required = true,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
        hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _drawerDropdown({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required ColorScheme cs,
    bool required = true,
  }) {
    final rawValue = controller.text.isEmpty ? null : controller.text;
    String? dropdownValue;
    if (rawValue != null) {
      if (items.contains(rawValue)) {
        dropdownValue = rawValue;
      } else {
        final lower = rawValue.toLowerCase();
        dropdownValue = items.where((item) => lower.contains(item.toLowerCase())).firstOrNull;
        if (dropdownValue != null) {
          controller.text = dropdownValue;
        }
      }
    }
    return DropdownButtonFormField<String>(
      value: dropdownValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
        hintStyle: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.3)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: TextStyle(fontSize: 14, color: cs.onSurface)),
      )).toList(),
      onChanged: (value) {
        if (value != null) controller.text = value;
      },
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  Widget _buildCartItemRow(CartItemModel item, ColorScheme cs) {
    final imageUrl = item.product?.thumbnailUrl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => SizedBox(
                  width: 48, height: 48,
                  child: Icon(Icons.inventory_2_outlined, color: cs.onSurface.withValues(alpha: 0.3), size: 22),
                ),
              ),
            )
          else
            Icon(Icons.inventory_2_outlined, color: cs.onSurface.withValues(alpha: 0.3), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product?.name ?? 'Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(item.formattedTotal, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildRadioDot(bool isSelected, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.2), width: 2),
      ),
      child: isSelected
          ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
          : null,
    );
  }

  Widget _buildAddressSelector(AddressModel address, ColorScheme cs, bool isDark) {
    final isSelected = _selectedAddressId == address.id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressId = address.id;
          _logisticsCompanies = [];
          _selectedCompanyId = null;
          _pricingOptions = [];
          _selectedRate = null;
          _frozenQuote = null;
        });
        _detectDeliveryMode();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.label != null && address.label!.isNotEmpty)
                    Text(address.label!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                    ),
                  Text(address.street, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  Text(address.fullAddress, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            _buildRadioDot(isSelected, cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? cs.onSurface)),
      ],
    );
  }
}
