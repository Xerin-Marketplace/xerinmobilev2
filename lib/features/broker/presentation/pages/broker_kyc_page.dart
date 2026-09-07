import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

const _mawingaPrimary = Color(0xFF6D28D9);

class BrokerKycPage extends StatefulWidget {
  const BrokerKycPage({super.key});

  @override
  State<BrokerKycPage> createState() => _BrokerKycPageState();
}

class _BrokerKycPageState extends State<BrokerKycPage> {
  final _nidaCtrl = TextEditingController();
  bool _busy = false;

  static const _docTypes = [
    {'key': 'national_id', 'label': 'National ID / NIDA document'},
    {'key': 'profile_photo', 'label': 'Passport-size profile photo'},
    {'key': 'selfie', 'label': 'Selfie / identity verification image'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<BrokerCubit>().loadKyc();
  }

  @override
  void dispose() {
    _nidaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF7F5FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Identity verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<BrokerCubit, BrokerState>(
        listener: (context, state) {
          if (state is BrokerActionSuccess) {
            NotificationService().success(state.message);
          } else if (state is BrokerError) {
            NotificationService().error(state.message);
          }
          if (state is BrokerActionSuccess || state is BrokerError) {
            setState(() => _busy = false);
          }
        },
        builder: (context, state) {
          if (state is BrokerLoading || state is BrokerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BrokerKycLoaded) {
            final broker = state.broker;
            final kycStatus = state.kycStatus;
            final docs = state.documents;
            _nidaCtrl.text = broker.nidaNumber ?? '';

            final locked = ['kyc_submitted', 'under_review', 'approved', 'suspended']
                .contains(broker.status);

            return RefreshIndicator(
              onRefresh: () => context.read<BrokerCubit>().loadKyc(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _statusHeader(cs, broker),
                  const SizedBox(height: 20),
                  _sectionTitle(cs, '1. National ID / NIDA Number'),
                  const SizedBox(height: 10),
                  _nidaField(cs, locked),
                  const SizedBox(height: 24),
                  _sectionTitle(cs, '2. Required documents'),
                  const SizedBox(height: 12),
                  ..._docTypes.map((docType) {
                    final key = docType['key']!;
                    final label = docType['label']!;
                    final uploaded = docs.where((d) => d.documentType == key).toList();
                    return _documentCard(cs, label, key, uploaded, locked);
                  }),
                  const SizedBox(height: 24),
                  _sectionTitle(cs, '3. Submit for review'),
                  const SizedBox(height: 8),
                  _submitSection(cs, kycStatus, locked),
                ],
              ),
            );
          }
          if (state is BrokerError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Uicons.triangleWarning, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<BrokerCubit>().loadKyc(),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _statusHeader(ColorScheme cs, BrokerModel broker) {
    final statusConfig = _getStatusConfig(broker.status);
    final isApproved = broker.status == 'approved';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isApproved
              ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
              : [statusConfig['color'] as Color, (statusConfig['color'] as Color).withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusConfig['icon'] as IconData, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Broker KYC',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Status: ${broker.status.replaceAll('_', ' ')}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8))),
          ])),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(isApproved ? Uicons.circleCheck : statusConfig['icon'] as IconData,
                size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(
              isApproved
                  ? 'KYC approved — you can use all broker features.'
                  : statusConfig['message'] as String,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            )),
          ]),
        ),
        if (broker.statusReason != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Uicons.circleExclamation, size: 16, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Expanded(child: Text(broker.statusReason!,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)))),
            ]),
          ),
        ],
      ]),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'approved':
        return {'color': const Color(0xFF22C55E), 'icon': Uicons.circleCheck, 'message': 'Your KYC has been approved.'};
      case 'kyc_submitted':
        return {'color': const Color(0xFF3B82F6), 'icon': Uicons.clock, 'message': 'KYC submitted — awaiting admin review.'};
      case 'under_review':
        return {'color': const Color(0xFF3B82F6), 'icon': Uicons.clock, 'message': 'Your documents are under review.'};
      case 'rejected':
        return {'color': const Color(0xFFEF4444), 'icon': Uicons.circleExclamation, 'message': 'KYC rejected — please review and resubmit.'};
      default:
        return {'color': _mawingaPrimary, 'icon': Uicons.userShield, 'message': 'Complete your KYC to unlock broker features.'};
    }
  }

  Widget _sectionTitle(ColorScheme cs, String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface));
  }

  Widget _nidaField(ColorScheme cs, bool locked) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _nidaCtrl,
          enabled: !locked,
          decoration: InputDecoration(
            hintText: 'Enter your NIDA number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
      const SizedBox(width: 10),
      FilledButton(
        onPressed: locked || _busy ? null : () {
          setState(() => _busy = true);
          context.read<BrokerCubit>().updateNidaNumber(_nidaCtrl.text.trim());
        },
        style: FilledButton.styleFrom(
          backgroundColor: _mawingaPrimary, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Save'),
      ),
    ]);
  }

  Widget _documentCard(ColorScheme cs, String label, String key,
      List<BrokerKycDocumentModel> uploaded, bool locked) {
    final isUploaded = uploaded.isNotEmpty;
    final docStatus = isUploaded ? uploaded.first.status : 'missing';
    final isApproved = docStatus == 'approved';
    final isPending = docStatus == 'pending';
    final isRejected = docStatus == 'rejected';

    final statusColor = isApproved
        ? const Color(0xFF22C55E)
        : isPending
            ? const Color(0xFFF59E0B)
            : isRejected
                ? const Color(0xFFEF4444)
                : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isUploaded ? Uicons.checkCircle : Uicons.upload, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 4),
          if (isUploaded)
            Text('Uploaded · $docStatus',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor))
          else
            Text('Not uploaded',
                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
        ])),
        if (!locked)
          TextButton(
            onPressed: _busy ? null : () => _pickAndUpload(key),
            style: TextButton.styleFrom(foregroundColor: _mawingaPrimary),
            child: Text(isUploaded ? 'Replace' : 'Upload',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  Future<void> _pickAndUpload(String docType) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Select source',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Uicons.smartphone, color: _mawingaPrimary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Uicons.image, color: _mawingaPrimary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    if (!mounted) return;

    setState(() => _busy = true);
    NotificationService().info('Uploading document...');

    context.read<BrokerCubit>().uploadKycDocument(
      documentType: docType,
      filePath: file.path,
      fileName: file.name,
    );
  }

  Widget _submitSection(ColorScheme cs, BrokerKycStatusModel kycStatus, bool locked) {
    final missing = kycStatus.missingDocuments;
    final canSubmit = kycStatus.canSubmitForReview && !locked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Uicons.listCheck, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text('Missing: ${missing.isEmpty ? 'None' : missing.join(', ')}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.6))),
        ]),
        const SizedBox(height: 16),
        if (canSubmit)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : () {
                setState(() => _busy = true);
                context.read<BrokerCubit>().submitKyc();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _mawingaPrimary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit KYC for Review',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              locked ? 'KYC is locked — no changes allowed at this stage.' : 'Complete all required documents and NIDA number to submit.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
      ]),
    );
  }
}
