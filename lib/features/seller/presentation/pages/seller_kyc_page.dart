import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerKycPage extends StatefulWidget {
  const SellerKycPage({super.key});

  @override
  State<SellerKycPage> createState() => _SellerKycPageState();
}

class _SellerKycPageState extends State<SellerKycPage> {
  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadKyc();
  }

  static const _docTypes = [
    ('tin', 'TIN Certificate', 'Valid Taxpayer Identification Number certificate.'),
    ('business_registration', 'Business Registration / Incorporation', 'Official business registration or incorporation certificate.'),
    ('business_licence', 'Business Licence', 'Current operating/business licence. Licence number and expiry date are required.'),
    ('business_profile', 'Business Profile', 'Required company or business profile document.'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Verification')),
      body: BlocConsumer<SellerCubit, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFEF4444)),
            );
          }
          if (state is SellerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF22C55E)),
            );
          }
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerKycLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadKyc(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 16),
                  _buildProgressCard(cs, state.kycStatus, state.documents),
                  const SizedBox(height: 24),
                  _buildSubmissionSection(cs, state.documents, state.kycStatus),
                  const SizedBox(height: 24),
                  _buildRequiredDocumentsSection(cs, state.documents),
                  const SizedBox(height: 24),
                  _buildBulkUploadSection(cs),
                  const SizedBox(height: 24),
                  _buildFooter(cs),
                ],
              ),
            );
          }
          if (state is SellerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Uicons.circleExclamation, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.read<SellerCubit>().loadKyc(),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seller Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Submit the required documents once. After submission you can view them and, until Admin starts review, replace a document if you notice a mistake.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildProgressCard(ColorScheme cs, SellerKycStatusModel kyc, List<SellerKycDocumentModel> docs) {
    final sellerStatus = kyc.sellerStatus ?? 'unknown';
    final statusColor = _getStatusColor(sellerStatus);
    final uploadedCount = docs.where((d) => d.status != 'not_uploaded').length;
    final totalCount = _docTypes.length;
    final percent = (uploadedCount / totalCount * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Documents complete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
              const Spacer(),
              Text('$percent%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: cs.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_statusIcon(sellerStatus), size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text('Seller status: ', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
              Text(sellerStatus, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionSection(ColorScheme cs, List<SellerKycDocumentModel> docs, SellerKycStatusModel kyc) {
    final canEdit = kyc.sellerStatus == 'pending' || kyc.sellerStatus == 'rejected' || kyc.sellerStatus == 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Initial document submission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('PDF only \u00b7 maximum 10 MB per document.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        const SizedBox(height: 16),
        ..._docTypes.map((doc) {
          final existing = docs.where((d) => d.documentType == doc.$1).firstOrNull;
          return _buildDocUploadCard(cs, doc.$1, doc.$2, doc.$3, existing, canEdit);
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All selected documents will be submitted for review.'), backgroundColor: Color(0xFF3B82F6)),
              );
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit All Documents', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDocUploadCard(ColorScheme cs, String docType, String title, String desc, SellerKycDocumentModel? existing, bool canEdit) {
    final hasDoc = existing != null && existing.status != 'not_uploaded';
    final status = existing?.status ?? 'not_uploaded';
    final statusColor = _getDocStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ),
              if (hasDoc) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),

          // Business licence extra fields
          if (docType == 'business_licence') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Licence number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Enter licence number',
                          hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: cs.onSurface.withValues(alpha: 0.03),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expiry date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
                      const SizedBox(height: 4),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'mm/dd/yyyy',
                          hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: cs.onSurface.withValues(alpha: 0.03),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          suffixIcon: Icon(Icons.calendar_today, size: 14, color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                        onTap: () async {
                          await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          if (hasDoc && !canEdit) ...[
            // View only
            Row(
              children: [
                Icon(Uicons.eye, size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text('View only', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                const Spacer(),
                GestureDetector(
                  onTap: () => _viewDocument(existing),
                  child: Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ],
            ),
          ] else if (hasDoc) ...[
            // Can replace or delete
            Row(
              children: [
                GestureDetector(
                  onTap: () => _uploadDocument(docType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Uicons.refresh, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Text('Replace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _viewDocument(existing),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(existing),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444).withValues(alpha: 0.7))),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Choose file
            GestureDetector(
              onTap: () => _uploadDocument(docType),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Uicons.upload, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text('Choose $title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text('PDF only \u00b7 max 10 MB', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildRequiredDocumentsSection(ColorScheme cs, List<SellerKycDocumentModel> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Required Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 16),
        ..._docTypes.map((doc) {
          final existing = docs.where((d) => d.documentType == doc.$1).firstOrNull;
          return _buildRequiredDocTile(cs, doc.$1, doc.$2, existing);
        }),
      ],
    );
  }

  Widget _buildRequiredDocTile(ColorScheme cs, String docType, String title, SellerKycDocumentModel? existing) {
    final hasDoc = existing != null && existing.status != 'not_uploaded';
    final status = existing?.status ?? 'not_uploaded';
    final statusColor = _getDocStatusColor(status);
    final isMissing = !hasDoc;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isMissing ? const Color(0xFFEF4444).withValues(alpha: 0.15) : cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          if (isMissing)
            Icon(Uicons.circleExclamation, size: 16, color: const Color(0xFFEF4444).withValues(alpha: 0.5))
          else
            Icon(_statusIcon(status), size: 16, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 2),
                if (isMissing)
                  Text('Not uploaded', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444).withValues(alpha: 0.6)))
                else
                  Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ],
            ),
          ),
          if (hasDoc) ...[
            GestureDetector(
              onTap: () => _viewDocument(existing),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
              ),
            ),
            const SizedBox(width: 4),
            Text('View only', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
          ] else
            Text('missing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444).withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildBulkUploadSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 4),
          Text('Need to submit TIN, Business Licence and Business Profile together?',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text('Use the Business Documents workspace to select, preview and submit all required verification files in one action.',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          const SizedBox(height: 16),

          // Document type dropdown
          Text('Document type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          _BulkUploadForm(cs: cs),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('KYC verification status page coming soon.')),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View KYC verification status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: cs.primary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('\u00a9 2026 Xerin Market Seller Center',
          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
      ],
    );
  }

  void _uploadDocument(String docType) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (!mounted) return;
      await context.read<SellerCubit>().uploadKycDocument(
        documentType: docType,
        filePath: file.path,
        fileName: file.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  void _viewDocument(SellerKycDocumentModel doc) {
    final url = doc.fileUrl ?? doc.documentUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening document: $url'), backgroundColor: const Color(0xFF3B82F6)),
    );
  }

  void _confirmDelete(SellerKycDocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Document?'),
        content: Text('Remove this ${_formatDocType(doc.documentType)}? You can re-upload it before Admin review.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); context.read<SellerCubit>().deleteKycDocument(doc.id); },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'under_review': return const Color(0xFF3B82F6);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF9CA3AF);
    }
  }

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'approved': return const Color(0xFF22C55E);
      case 'pending': return const Color(0xFFF59E0B);
      case 'under_review': return const Color(0xFF3B82F6);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved': return Uicons.circleCheck;
      case 'pending': return Uicons.clock;
      case 'under_review': return Uicons.eye;
      case 'rejected': return Uicons.circleExclamation;
      default: return Uicons.circleInfo;
    }
  }

  String _formatDocType(String type) {
    switch (type) {
      case 'tin': return 'TIN Certificate';
      case 'business_registration': return 'Business Registration';
      case 'business_licence': return 'Business Licence';
      case 'business_profile': return 'Business Profile';
      default: return type;
    }
  }
}

// ─── Bulk Upload Form ───
class _BulkUploadForm extends StatefulWidget {
  final ColorScheme cs;

  const _BulkUploadForm({required this.cs});

  @override
  State<_BulkUploadForm> createState() => _BulkUploadFormState();
}

class _BulkUploadFormState extends State<_BulkUploadForm> {
  String _docType = 'tin';
  String? _fileName;
  String? _filePath;
  bool _isUploading = false;

  static const _docOptions = [
    ('tin', 'TIN'),
    ('business_registration', 'Business Registration'),
    ('business_licence', 'Business License'),
    ('business_profile', 'Business Profile'),
  ];

  Future<void> _pickFile() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      setState(() {
        _fileName = file.name;
        _filePath = file.path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selection failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a file first'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      await context.read<SellerCubit>().uploadKycDocument(
        documentType: _docType,
        filePath: _filePath!,
        fileName: _fileName,
      );
      if (mounted) {
        setState(() {
          _fileName = null;
          _filePath = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document type dropdown
        DropdownButtonFormField<String>(
          initialValue: _docType,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: _docOptions.map((opt) => DropdownMenuItem(value: opt.$1, child: Text(opt.$2, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => _docType = v!),
        ),
        const SizedBox(height: 12),

        // File picker
        Text('File (PDF, JPG, PNG)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Uicons.upload, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName ?? 'No file chosen',
                    style: TextStyle(fontSize: 13, color: _fileName != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_fileName != null)
                  GestureDetector(
                    onTap: () => setState(() { _fileName = null; _filePath = null; }),
                    child: Icon(Uicons.crossSmall, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isUploading ? null : _upload,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUploading
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
