import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../data/models/order_model.dart';
import '../../../../core/theme/uicons.dart';

class InvoicePage extends StatefulWidget {
  final OrderModel order;

  const InvoicePage({super.key, required this.order});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool _isGenerating = false;

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatPrice(double amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$currency $formatted';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'received_at_hub':
      case 'paid':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFE53935);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/logo/mark.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final bgBytes = await rootBundle.load(
      'assets/images/retro-style-organic-turing-lines-pattern-background-design.png',
    );
    final bgImage = pw.MemoryImage(bgBytes.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: pw.Opacity(
                  opacity: 0.06,
                  child: pw.Image(bgImage, fit: pw.BoxFit.cover),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfHeader(logoImage),
                    pw.SizedBox(height: 30),
                    _buildPdfInvoiceTitle(),
                    pw.SizedBox(height: 20),
                    _buildPdfOrderInfo(),
                    pw.SizedBox(height: 24),
                    _buildPdfItemsTable(),
                    pw.SizedBox(height: 20),
                    _buildPdfSummary(),
                    pw.Spacer(),
                    _buildPdfFooter(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logoImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logoImage, width: 50, height: 50),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Xerin Marketplace',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Your trusted online shopping platform',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Date: ${_formatDate(widget.order.createdAt ?? DateTime.now().toIso8601String())}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfInvoiceTitle() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Order Reference: ${widget.order.orderRef}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              widget.order.displayStatus.toUpperCase(),
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfOrderInfo() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Order Details',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Order Number:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              pw.Text(widget.order.orderNumber, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Items:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              pw.Text('${widget.order.itemCount}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Currency:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              pw.Text(widget.order.currency, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (widget.order.couponCode != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Coupon:', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                pw.Text(widget.order.couponCode!, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPdfItemsTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FixedColumnWidth(80),
        3: const pw.FixedColumnWidth(80),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue800),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Product', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Unit Price', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
          ],
        ),
        ...widget.order.items.map((item) => pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  if (item.variantName != null)
                    pw.Text(item.variantName!, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.formattedPrice, style: pw.TextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.formattedTotal, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPdfSummary() {
    final order = widget.order;
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 250,
        child: pw.Column(
          children: [
            _pdfSummaryRow('Subtotal', order.formattedSubtotal),
            if (order.discountAmount > 0)
              _pdfSummaryRow('Discount', '- ${_formatPrice(order.discountAmount, order.currency)}'),
            if (order.shippingAmount > 0)
              _pdfSummaryRow('Shipping', _formatPrice(order.shippingAmount, order.currency)),
            if (order.taxAmount > 0)
              _pdfSummaryRow('Tax', _formatPrice(order.taxAmount, order.currency)),
            pw.Divider(color: PdfColors.grey400, height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  order.formattedTotal,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, height: 1),
        pw.SizedBox(height: 12),
        pw.Center(
          child: pw.Text(
            'Generated by Xerin Marketplace',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'www.xerinmarketplace.com  |  support@xerinmarketplace.com',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Thank you for shopping with us!',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.blue800, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isGenerating = true);
    try {
      final doc = await _generatePdf();
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'invoice_${widget.order.orderRef}.pdf',
      );
    } catch (e) {
      NotificationService().error('Failed to generate PDF: $e');
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _printPdf() async {
    setState(() => _isGenerating = true);
    try {
      final doc = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (format) => doc.save(),
        name: 'invoice_${widget.order.orderRef}',
      );
    } catch (e) {
      NotificationService().error('Failed to print: $e');
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(widget.order.status);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      BackIconButton(
                        onTap: () => context.pop(),
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Invoice',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                      ),
                      IconButton(
                        onPressed: _isGenerating ? null : _printPdf,
                        icon: Icon(Uicons.file, size: 22, color: colorScheme.primary),
                      ),
                      IconButton(
                        onPressed: _isGenerating ? null : _downloadPdf,
                        icon: Icon(Uicons.download, size: 22, color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInvoicePreview(colorScheme, isDark, statusColor),
                        const SizedBox(height: 16),
                        _buildActionButtons(colorScheme),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isGenerating)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Generating PDF...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we create your invoice',
                          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicePreview(ColorScheme cs, bool isDark, Color statusColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _buildPreviewHeader(cs, statusColor),
          _buildPreviewOrderInfo(cs, isDark),
          _buildPreviewItems(cs, isDark),
          _buildPreviewSummary(cs, isDark),
          _buildPreviewFooter(cs),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(ColorScheme cs, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xerin Marketplace',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your trusted online shopping platform',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              Image.asset(
                'assets/logo/mark.png',
                width: 48,
                height: 48,
                errorBuilder: (_, __, ___) => Icon(Uicons.shop, color: Colors.white, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INVOICE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.order.displayStatus.toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewOrderInfo(ColorScheme cs, bool isDark) {
    final order = widget.order;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _infoItem('Order Ref', order.orderRef, cs),
              const SizedBox(width: 20),
              _infoItem('Date', _formatDate(order.createdAt ?? ''), cs),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoItem('Items', '${order.itemCount}', cs),
              const SizedBox(width: 20),
              _infoItem('Currency', order.currency, cs),
            ],
          ),
          if (order.couponCode != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _infoItem('Coupon', order.couponCode!, cs, valueColor: cs.primary),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildPreviewItems(ColorScheme cs, bool isDark) {
    final order = widget.order;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 12),
          ...order.items.map((item) => _buildPreviewItemRow(item, cs, isDark)),
        ],
      ),
    );
  }

  Widget _buildPreviewItemRow(OrderItemModel item, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: item.productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 20),
                    ),
                  )
                : Icon(Uicons.box, color: cs.primary.withValues(alpha: 0.4), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity} × ${item.formattedPrice}',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Text(
            item.formattedTotal,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSummary(ColorScheme cs, bool isDark) {
    final order = widget.order;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', order.formattedSubtotal, cs),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Discount', '- ${_formatPrice(order.discountAmount, order.currency)}', cs, valueColor: cs.primary),
          ],
          if (order.shippingAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Shipping', _formatPrice(order.shippingAmount, order.currency), cs),
          ],
          if (order.taxAmount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow('Tax', _formatPrice(order.taxAmount, order.currency), cs),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: cs.onSurface.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
              Text(
                order.formattedTotal,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildPreviewFooter(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Text(
            'Generated by Xerin Marketplace',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'www.xerinmarketplace.com  |  support@xerinmarketplace.com',
            style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 8),
          Text(
            'Thank you for shopping with us!',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isGenerating ? null : _printPdf,
              icon: Icon(Uicons.file, size: 20, color: cs.primary),
              label: Text('Print', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary.withValues(alpha: 0.3), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _downloadPdf,
              icon: const Icon(Uicons.download, size: 20, color: Colors.white),
              label: const Text('Download PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
