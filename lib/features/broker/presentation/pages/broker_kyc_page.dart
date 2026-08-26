import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../cubit/broker_cubit.dart';
import '../../data/models/broker_models.dart';

class BrokerKycPage extends StatefulWidget {
  const BrokerKycPage({super.key});

  @override
  State<BrokerKycPage> createState() => _BrokerKycPageState();
}

class _BrokerKycPageState extends State<BrokerKycPage> {
  final _nidaCtrl = TextEditingController();
  bool _busy = false;

  static const _docTypes = [
    {'key': 'national_id', 'label': 'National ID / NIDA Document'},
    {'key': 'profile_photo', 'label': 'Passport-size Profile Photo'},
    {'key': 'selfie', 'label': 'Selfie / Identity Verification Image'},
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Broker KYC')),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity Verification',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Broker KYC',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Status: ${broker.status.replaceAll('_', ' ').toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (broker.statusReason != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              broker.statusReason!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '1. National ID / NIDA Number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nidaCtrl,
                          enabled: !locked,
                          decoration: InputDecoration(
                            hintText: 'Enter your NIDA number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: locked || _busy
                            ? null
                            : () {
                                setState(() => _busy = true);
                                context.read<BrokerCubit>()
                                    .updateNidaNumber(_nidaCtrl.text.trim());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '2. Upload Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._docTypes.map((docType) {
                    final key = docType['key']!;
                    final label = docType['label']!;
                    final uploaded = docs.where((d) => d.documentType == key).toList();
                    final isUploaded = uploaded.isNotEmpty;
                    final isMissing = kycStatus.missingDocuments.contains(key);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUploaded
                              ? Colors.green.withValues(alpha: 0.3)
                              : isMissing
                                  ? Colors.orange.withValues(alpha: 0.3)
                                  : colorScheme.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isUploaded ? Uicons.circleCheck : Uicons.upload,
                            color: isUploaded
                                ? Colors.green
                                : isMissing
                                    ? Colors.orange
                                    : colorScheme.onSurface.withValues(alpha: 0.4),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (isUploaded) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: ${uploaded.first.status}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!locked && !isUploaded)
                            ElevatedButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      NotificationService().info(
                                          'Document upload will be available in the next update. Please use the web dashboard.');
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Upload'),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (kycStatus.canSubmitForReview && !locked) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() => _busy = true);
                                context.read<BrokerCubit>().submitKyc();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Submit KYC for Review',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          if (state is BrokerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<BrokerCubit>().loadKyc(),
                    child: const Text('Retry'),
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
}
