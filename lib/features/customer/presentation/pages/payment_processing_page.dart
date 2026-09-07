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

enum _PaymentUIState { processing, success, failed }

class _PaymentProcessingPageState extends State<PaymentProcessingPage>
    with TickerProviderStateMixin {
  _PaymentUIState _uiState = _PaymentUIState.processing;
  String _statusMessage = 'Confirming your payment...';
  Timer? _pollTimer;
  int _attempts = 0;
  static const int _maxAttempts = 30;
  bool _isRetrying = false;

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
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _attempts++;
      if (_attempts > _maxAttempts) {
        timer.cancel();
        _onPaymentTimeout();
        return;
      }

      final cubit = context.read<CustomerCubit>();
      final payment = await cubit.verifyPaymentStatus(widget.paymentId!);

      if (!mounted) return;

      if (payment == null) return;

      if (payment.isCompleted) {
        timer.cancel();
        _onPaymentSuccess();
      } else if (payment.isFailed) {
        timer.cancel();
        _onPaymentFailed('Payment was declined. Please try again.');
      } else if (payment.isCancelled) {
        timer.cancel();
        _onPaymentFailed('Payment was cancelled.');
      }
    });
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
    setState(() {
      _uiState = _PaymentUIState.failed;
      _statusMessage = message;
    });
    _failController.forward();
    NotificationService().error(message);
  }

  void _onPaymentTimeout() {
    setState(() {
      _uiState = _PaymentUIState.failed;
      _statusMessage = 'Payment confirmation timed out. Check your order history for updates.';
    });
    _failController.forward();
  }

  Future<void> _retryPayment() async {
    if (widget.paymentId == null || widget.paymentId!.isEmpty) return;
    setState(() {
      _isRetrying = true;
      _uiState = _PaymentUIState.processing;
      _statusMessage = 'Retrying payment...';
      _attempts = 0;
    });
    final cubit = context.read<CustomerCubit>();
    final payment = await cubit.retryPayment(paymentId: widget.paymentId!);
    if (!mounted) return;
    setState(() => _isRetrying = false);
    if (payment == null) {
      _onPaymentFailed('Retry failed. Please try again later.');
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
    }
  }

  Widget _buildProcessingState(ColorScheme cs) {
    return Column(
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
        Text('This may take a few moments...',
          style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
        ),
      ],
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
    return Column(
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
        const SizedBox(height: 36),
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
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/'),
          child: Text('Back to Home',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      ],
    );
  }
}
