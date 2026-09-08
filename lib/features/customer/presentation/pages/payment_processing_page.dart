import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../cubit/customer_cubit.dart';

class PaymentProcessingPage extends StatefulWidget {
  final String? paymentId;
  final String? orderId;
  final String? checkoutUrl;

  const PaymentProcessingPage({
    super.key,
    this.paymentId,
    this.orderId,
    this.checkoutUrl,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

enum _PaymentUIState { processing, success, failed, timedOut }

class _PaymentProcessingPageState extends State<PaymentProcessingPage>
    with TickerProviderStateMixin {
  _PaymentUIState _uiState = _PaymentUIState.processing;
  String _statusMessage = 'Confirming your payment...';
  Timer? _pollTimer;
  bool _isRetrying = false;
  bool _isRefreshing = false;

  String _paymentStatus = 'processing';
  String _orderStatus = '';
  bool _retryable = false;
  bool _terminal = false;
  String _stateMessage = '';
  String _paymentMethod = '';
  String _lastProvider = '';
  int _pollAfterSeconds = 5;
  DateTime? _pollStartTime;
  static const Duration _maxPollDuration = Duration(minutes: 5);

  final _retryPhoneController = TextEditingController();
  String _retryProvider = '';

  static const List<String> _mnoProviders = ['M-Pesa', 'Airtel Money', 'Mixx by Yas', 'HaloPesa'];

  static const Map<String, Map<String, dynamic>> _mnoInfo = {
    'M-Pesa':       {'flag': '🇹🇿', 'country': 'Tanzania', 'color': Color(0xFFFF6633)},
    'Airtel Money':  {'flag': '🇹🇿', 'country': 'Tanzania', 'color': Color(0xFFE40000)},
    'Mixx by Yas':   {'flag': '🇹🇿', 'country': 'Tanzania', 'color': Color(0xFF0066B3)},
    'HaloPesa':      {'flag': '🇹🇿', 'country': 'Tanzania', 'color': Color(0xFF00A651)},
  };

  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255') && digits.length == 12) return digits;
    if (digits.startsWith('0') && digits.length == 10) return '255${digits.substring(1)}';
    if (digits.length == 9) return '255$digits';
    return digits;
  }

  late AnimationController _successController;
  late AnimationController _failController;
  late Animation<double> _successScale;
  late Animation<double> _failScale;

  bool _isDownloadingInvoice = false;
  bool _isDownloadingReceipt = false;

  @override
  void initState() {
    super.initState();

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _failController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _failScale = CurvedAnimation(
      parent: _failController,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPaymentFlow();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _successController.dispose();
    _failController.dispose();
    _retryPhoneController.dispose();
    super.dispose();
  }

  void _startPaymentFlow() {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) {
      // No payment ID - likely COD, show success immediately
      _onPaymentSuccess();
      return;
    }
    _pollPaymentStatus();
  }

  void _pollPaymentStatus() {
    _pollTimer?.cancel();
    _pollStartTime = DateTime.now();
    _pollTimer = Timer.periodic(Duration(seconds: _pollAfterSeconds), (timer) async {
      if (_pollStartTime != null &&
          DateTime.now().difference(_pollStartTime!) > _maxPollDuration) {
        timer.cancel();
        _onPaymentTimeout();
        return;
      }
      await _refreshPaymentState(quiet: true);
    });
    _refreshPaymentState(quiet: false);
  }

  Future<void> _refreshPaymentState({required bool quiet}) async {
    if (!mounted) return;
    if (!quiet) setState(() => _isRefreshing = true);

    try {
      final cubit = context.read<CustomerCubit>();

      if (widget.orderId != null && widget.orderId!.isNotEmpty) {
        final state = await cubit.getOrderPaymentState(widget.orderId!);
        if (!mounted) return;

        if (state != null) {
          _paymentStatus = state['payment_status'] as String? ?? 'processing';
          _orderStatus = state['order_status'] as String? ?? '';
          _retryable = state['retryable'] as bool? ?? false;
          _terminal = state['terminal'] as bool? ?? false;
          _stateMessage = state['message'] as String? ?? '';
          final pollAfter = state['poll_after_seconds'] as int?;
          if (pollAfter != null && pollAfter > 0 && pollAfter != _pollAfterSeconds) {
            _pollAfterSeconds = pollAfter;
            _pollTimer?.cancel();
            _pollTimer = Timer.periodic(Duration(seconds: _pollAfterSeconds), (timer) async {
              if (_pollStartTime != null &&
                  DateTime.now().difference(_pollStartTime!) > _maxPollDuration) {
                timer.cancel();
                _onPaymentTimeout();
                return;
              }
              await _refreshPaymentState(quiet: true);
            });
          }

          final latestPayment = state['latest_payment'] as Map<String, dynamic>?;
          final provider = (latestPayment?['provider'] as String?) ?? '';
          final providerLower = provider.toLowerCase();
          _paymentMethod = (latestPayment?['method'] as String?) ?? '';
          _lastProvider = provider;

          if (latestPayment != null &&
              latestPayment['id'] != null &&
              (providerLower == 'zenopay' || providerLower == 'selcom') &&
              (_paymentStatus == 'pending' || _paymentStatus == 'processing')) {
            try {
              await cubit.verifyPaymentStatus(latestPayment['id'].toString());
              if (!mounted) return;
              final updatedState = await cubit.getOrderPaymentState(widget.orderId!);
              if (!mounted) return;
              if (updatedState != null) {
                _paymentStatus = updatedState['payment_status'] as String? ?? _paymentStatus;
                _orderStatus = updatedState['order_status'] as String? ?? _orderStatus;
                _retryable = updatedState['retryable'] as bool? ?? _retryable;
                _terminal = updatedState['terminal'] as bool? ?? _terminal;
                _stateMessage = updatedState['message'] as String? ?? _stateMessage;
              }
            } catch (_) {}
          }

          _handleStatusUpdate();
        }
      } else if (widget.paymentId != null) {
        final payment = await cubit.verifyPaymentStatus(widget.paymentId!);
        if (!mounted) return;
        if (payment != null) {
          _paymentStatus = payment.status;
          _handleStatusUpdate();
        }
      }
    } catch (_) {
    } finally {
      if (mounted && !quiet) setState(() => _isRefreshing = false);
    }
  }

  void _handleStatusUpdate() {
    if (_terminal) {
      _pollTimer?.cancel();
      if (_paymentStatus == 'completed') {
        _onPaymentSuccess();
      } else if (_paymentStatus == 'failed') {
        _onPaymentFailed('Payment was declined. Please try again.');
      } else if (_paymentStatus == 'cancelled') {
        if (_orderStatus == 'cancelled') {
          _onPaymentTimeout();
        } else {
          _onPaymentFailed('Payment was cancelled.');
        }
      } else {
        _onPaymentTimeout();
      }
      return;
    }
    if (_paymentStatus == 'completed') {
      _pollTimer?.cancel();
      _onPaymentSuccess();
    } else if (_paymentStatus == 'failed') {
      _pollTimer?.cancel();
      _onPaymentFailed('Payment was declined. Please try again.');
    } else if (_paymentStatus == 'cancelled') {
      _pollTimer?.cancel();
      if (_orderStatus == 'cancelled') {
        _onPaymentTimeout();
      } else {
        _onPaymentFailed('Payment was cancelled.');
      }
    } else if (_orderStatus == 'cancelled') {
      _pollTimer?.cancel();
      _onPaymentTimeout();
    }
  }

  void _onPaymentSuccess() {
    setState(() {
      _uiState = _PaymentUIState.success;
      _statusMessage = 'Payment Successful!';
    });
    _successController.forward();
    NotificationService().success('Payment completed successfully!');
  }

  void _onPaymentFailed(String message) {
    if (_retryProvider.isEmpty && _lastProvider.isNotEmpty) {
      final match = _mnoProviders.where((p) =>
        p.toLowerCase() == _lastProvider.toLowerCase() ||
        _lastProvider.toLowerCase().contains(p.toLowerCase().split(' ').first),
      ).firstOrNull;
      if (match != null) _retryProvider = match;
    }
    setState(() {
      _uiState = _PaymentUIState.failed;
      _statusMessage = message;
    });
    _failController.forward();
    NotificationService().error(message);
  }

  void _onPaymentTimeout() {
    setState(() {
      _uiState = _PaymentUIState.timedOut;
      _statusMessage = _stateMessage.isNotEmpty
          ? _stateMessage
          : 'Payment confirmation timed out. Check your order history for updates.';
    });
    _failController.forward();
  }

  Future<void> _retryPayment() async {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) return;

    if (_paymentMethod == 'mobile_money') {
      if (_retryProvider.isEmpty) {
        NotificationService().error('Please select a mobile network.');
        return;
      }
      if (_retryPhoneController.text.trim().isEmpty) {
        NotificationService().error('Please enter a mobile money number.');
        return;
      }
    }

    setState(() {
      _isRetrying = true;
      _uiState = _PaymentUIState.processing;
      _statusMessage = 'Retrying payment...';
    });
    final cubit = context.read<CustomerCubit>();
    final payment = await cubit.retryPayment(
      paymentId: widget.paymentId!,
      provider: _paymentMethod == 'mobile_money' ? _retryProvider : null,
      phoneNumber: _paymentMethod == 'mobile_money' ? _normalizePhone(_retryPhoneController.text.trim()) : null,
    );
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (payment == null) {
      _onPaymentFailed('Retry failed. The payment may still be active. Please wait and try again.');
      return;
    }
    if (payment.isCompleted) {
      _onPaymentSuccess();
    } else if (payment.isFailed || payment.isCancelled) {
      _onPaymentFailed('Payment was declined. Please try again.');
    } else {
      _pollPaymentStatus();
    }
  }

  Future<void> _downloadInvoice() async {
    if (widget.orderId == null || widget.orderId!.isEmpty) return;
    setState(() => _isDownloadingInvoice = true);
    try {
      final token = GetIt.instance<TokenStorage>().accessToken;
      final url = '${ApiConstants.baseUrl}/api/v1${ApiConstants.orderInvoice(widget.orderId!)}';
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix} $token'},
        ),
      );
      final bytes = Uint8List.fromList(response.data!);
      await Printing.sharePdf(bytes: bytes, filename: 'invoice_${formatOrderRef(widget.orderId!)}.pdf');
    } catch (_) {
      NotificationService().error('Failed to download invoice');
    }
    if (mounted) setState(() => _isDownloadingInvoice = false);
  }

  Future<void> _downloadReceipt() async {
    if (widget.orderId == null || widget.orderId!.isEmpty) return;
    setState(() => _isDownloadingReceipt = true);
    try {
      final token = GetIt.instance<TokenStorage>().accessToken;
      final url = '${ApiConstants.baseUrl}/api/v1${ApiConstants.orderReceipt(widget.orderId!)}';
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix} $token'},
        ),
      );
      final bytes = Uint8List.fromList(response.data!);
      await Printing.sharePdf(bytes: bytes, filename: 'receipt_${formatOrderRef(widget.orderId!)}.pdf');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        NotificationService().warning('Receipt available after payment is confirmed');
      } else {
        NotificationService().error('Failed to download receipt');
      }
    } catch (_) {
      NotificationService().error('Failed to download receipt');
    }
    if (mounted) setState(() => _isDownloadingReceipt = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(cs),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _buildContent(cs, isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back, size: 20, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Text('Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool isDark) {
    switch (_uiState) {
      case _PaymentUIState.processing:
        return _buildProcessingState(cs);
      case _PaymentUIState.success:
        return _buildSuccessState(cs, isDark);
      case _PaymentUIState.failed:
        return _buildFailedState(cs);
      case _PaymentUIState.timedOut:
        return _buildTimedOutState(cs);
    }
  }

  Widget _buildProcessingState(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 4,
                  color: cs.primary.withValues(alpha: 0.2),
                  value: 1,
                ),
                CircularProgressIndicator(
                  strokeWidth: 4,
                  color: cs.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Processing Payment',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          Text(_statusMessage,
            style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (widget.paymentId != null && widget.paymentId!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 6),
                  Text('Ref: ${formatOrderRef(widget.paymentId!)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4), fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_android, size: 20, color: const Color(0xFF3B82F6)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check your phone',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF3B82F6)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stateMessage.isNotEmpty
                                ? _stateMessage
                                : 'Complete the payment authorization on your phone. This page checks automatically for confirmed payment.',
                            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('You can keep this page open or return later. Xerin will update automatically.',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isRefreshing ? null : () => _refreshPaymentState(quiet: false),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text('Check now',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Payment Successful!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          Text(
            'Your order has been placed and payment confirmed.',
            style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          if (widget.orderId != null && widget.orderId!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order Reference',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                      Text(formatOrderRef(widget.orderId!),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment ID',
                        style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                      if (widget.paymentId != null && widget.paymentId!.isNotEmpty)
                        Text(widget.paymentId!.substring(0, 12),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6), fontFamily: 'monospace'),
                        )
                      else
                        Text('COD',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _downloadButton(
                  label: 'Invoice',
                  icon: Icons.description_outlined,
                  isDownloading: _isDownloadingInvoice,
                  onPressed: _downloadInvoice,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _downloadButton(
                  label: 'Receipt',
                  icon: Icons.receipt_long,
                  isDownloading: _isDownloadingReceipt,
                  onPressed: _downloadReceipt,
                  cs: cs,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.go('/'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Continue Shopping',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/order-history'),
            child: Text('View My Orders',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadButton({
    required String label,
    required IconData icon,
    required bool isDownloading,
    required VoidCallback onPressed,
    required ColorScheme cs,
  }) {
    return OutlinedButton(
      onPressed: isDownloading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
      ),
      child: isDownloading
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
    );
  }

  Widget _buildFailedState(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _failScale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: Color(0xFFEF4444),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Payment Failed',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          Text(_statusMessage,
            style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          if (_stateMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_stateMessage,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              textAlign: TextAlign.center,
            ),
          ],
          if (_retryable && _paymentMethod == 'mobile_money') ...[
            const SizedBox(height: 24),
            _buildRetryProviderSelector(cs),
            const SizedBox(height: 12),
            _buildRetryPhoneInput(cs),
          ],
          const SizedBox(height: 36),
          if (_retryable)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isRetrying ? null : _retryPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isRetrying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Retrying...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    )
                  : const Text('Retry Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time, size: 20, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('This payment is still active. Please wait for the result before retrying.',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/'),
            child: Text('Back to Home',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryProviderSelector(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Mobile Network',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 6),
            const Text('🇹🇿', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('Tanzania',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: _mnoProviders.map((provider) {
            final isSelected = _retryProvider == provider;
            final info = _mnoInfo[provider] ?? {};
            final brandColor = info['color'] as Color? ?? const Color(0xFF22C55E);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() => _retryProvider = provider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brandColor.withValues(alpha: 0.08)
                        : cs.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? brandColor : cs.onSurface.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            provider[0],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: brandColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? brandColor : cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text('🇹🇿', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text('Tanzania',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? brandColor : cs.onSurface.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle)))
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRetryPhoneInput(ColorScheme cs) {
    return TextField(
      controller: _retryPhoneController,
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
    );
  }

  Widget _buildTimedOutState(ColorScheme cs) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _failScale,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFFF59E0B),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Payment Window Expired',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          Text(_statusMessage,
            style: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
          if (_stateMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_stateMessage,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              textAlign: TextAlign.center,
            ),
          ],
          if (_retryable && _paymentMethod == 'mobile_money') ...[
            const SizedBox(height: 24),
            _buildRetryProviderSelector(cs),
            const SizedBox(height: 12),
            _buildRetryPhoneInput(cs),
          ],
          const SizedBox(height: 36),
          if (_retryable) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isRetrying ? null : _retryPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isRetrying
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Retrying...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : const Text('Retry Payment',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isRefreshing ? null : () => _refreshPaymentState(quiet: false),
                icon: _isRefreshing
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                  : Icon(Icons.refresh, size: 20, color: cs.primary),
                label: Text('Check Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextButton(
            onPressed: () => context.go('/'),
            child: Text('Back to Home',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
