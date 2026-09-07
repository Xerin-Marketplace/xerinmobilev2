import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../config/constants/api_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';

class InvoicePage extends StatefulWidget {
  final OrderModel order;

  const InvoicePage({super.key, required this.order});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool _isGenerating = false;
  bool _isDownloadingBackend = false;
  bool _isDownloadingReceipt = false;

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtMoney(num amount, String currency) {
    final f = amount.toDouble().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $f';
  }

  // =====================
  // PDF GENERATION
  // =====================

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final logoBytes = await rootBundle.load('assets/logo/mark.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final o = widget.order;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Image(logo, width: 40, height: 40),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Xerin Marketplace', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text('www.xerinmarketplace.com', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text(_fmtDate(o.createdAt), style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(height: 30),

            // Order info
            pw.Text('Order: ${o.orderRef}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Status: ${o.displayStatus}', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.Text('Items: ${o.itemCount}', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),

            // Items table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FixedColumnWidth(40),
                2: const pw.FixedColumnWidth(70),
                3: const pw.FixedColumnWidth(70),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Product', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Qty', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Unit Price', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                  ],
                ),
                ...o.items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.productName, style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.formattedPrice, style: pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.formattedTotal, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _pdfRow('Subtotal', o.formattedSubtotal),
                    if (o.shippingAmount > 0) _pdfRow('Shipping', _fmtMoney(o.shippingAmount, o.currency)),
                    if (o.taxAmount > 0) _pdfRow('Tax', _fmtMoney(o.taxAmount, o.currency)),
                    if (o.discountAmount > 0) _pdfRow('Discount', '- ${_fmtMoney(o.discountAmount, o.currency)}'),
                    pw.Divider(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(o.formattedTotal, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.Spacer(),

            // Footer
            pw.Divider(height: 1),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('Thank you for shopping with us!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('support@xerinmarketplace.com', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400))),
          ],
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final doc = await _generatePdf();
      await Printing.sharePdf(bytes: await doc.save(), filename: 'invoice_${widget.order.orderRef}.pdf');
    } catch (_) {}
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _printPdf() async {
    setState(() => _isGenerating = true);
    try {
      final doc = await _generatePdf();
      await Printing.layoutPdf(onLayout: (format) => doc.save(), name: 'invoice_${widget.order.orderRef}');
    } catch (_) {}
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _downloadBackendInvoice() async {
    setState(() => _isDownloadingBackend = true);
    try {
      final token = GetIt.instance<TokenStorage>().accessToken;
      final url = '${ApiConstants.baseUrl}/api/v1${ApiConstants.orderInvoice(widget.order.id)}';
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix} $token'},
        ),
      );
      final bytes = Uint8List.fromList(response.data!);
      await Printing.sharePdf(bytes: bytes, filename: 'Xerin-Invoice-${formatOrderRef(widget.order.id)}.pdf');
    } catch (_) {
      NotificationService().error('Failed to download invoice from server');
    }
    if (mounted) setState(() => _isDownloadingBackend = false);
  }

  Future<void> _downloadBackendReceipt() async {
    setState(() => _isDownloadingReceipt = true);
    try {
      final token = GetIt.instance<TokenStorage>().accessToken;
      final url = '${ApiConstants.baseUrl}/api/v1${ApiConstants.orderReceipt(widget.order.id)}';
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix} $token'},
        ),
      );
      final bytes = Uint8List.fromList(response.data!);
      await Printing.sharePdf(bytes: bytes, filename: 'Xerin-Receipt-${formatOrderRef(widget.order.id)}.pdf');
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

  // =====================
  // UI
  // =====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final o = widget.order;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs, o),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      children: [
                        _buildInvoiceCard(cs, isDark, o),
                        const SizedBox(height: 16),
                        _buildActionButtons(cs),
                      ],
                    ),
                  ),
                  if (_isGenerating || _isDownloadingBackend || _isDownloadingReceipt)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, OrderModel o) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isGenerating ? null : _printPdf,
                icon: const Icon(Icons.print_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          const Text('Invoice',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          Text(o.orderRef,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(ColorScheme cs, bool isDark, OrderModel o) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xerin Marketplace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                    Text('www.xerinmarketplace.com', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                  ],
                ),
                Image.asset('assets/logo/mark.png', width: 36, height: 36,
                  errorBuilder: (_, _, _) => Icon(Icons.store_outlined, color: cs.primary, size: 28)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('INVOICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(o.displayStatus.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _row('Order Ref', o.orderRef, cs),
            _row('Date', _fmtDate(o.createdAt), cs),
            _row('Items', '${o.itemCount}', cs),
            if (o.couponCode != null) _row('Coupon', o.couponCode!, cs),
            const Divider(height: 24),
            Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            ...o.items.map((item) => _itemRow(item, cs)),
            const Divider(height: 24),
            _row('Subtotal', o.formattedSubtotal, cs),
            if (o.shippingAmount > 0) _row('Shipping', _fmtMoney(o.shippingAmount, o.currency), cs),
            if (o.taxAmount > 0) _row('Tax', _fmtMoney(o.taxAmount, o.currency), cs),
            if (o.discountAmount > 0) _row('Discount', '- ${_fmtMoney(o.discountAmount, o.currency)}', cs),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(o.formattedTotal, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: Text('Thank you for shopping with us!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary))),
            Center(child: Text('support@xerinmarketplace.com', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)))),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _printPdf,
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _downloadPdf,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloadingBackend ? null : _downloadBackendInvoice,
                icon: _isDownloadingBackend
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('Server Invoice'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloadingReceipt ? null : _downloadBackendReceipt,
                icon: _isDownloadingReceipt
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.receipt_outlined, size: 18),
                label: const Text('Receipt'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _itemRow(OrderItemModel item, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Qty ${item.quantity} × ${item.formattedPrice}', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Text(item.formattedTotal, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }
}
