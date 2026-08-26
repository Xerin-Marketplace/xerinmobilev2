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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC & Compliance')),
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
        },
        builder: (context, state) {
          if (state is SellerLoading || state is SellerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SellerKycLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadKyc(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(context, state.kycStatus),
                  const SizedBox(height: 16),
                  _buildDocumentsSection(context, state.documents, state.kycStatus),
                  const SizedBox(height: 24),
                  _buildPayoutAccountsSection(context, state.payoutAccounts),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          if (state is SellerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Uicons.circleExclamation, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerCubit>().loadKyc(),
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

  Widget _buildStatusCard(BuildContext context, SellerKycStatusModel kyc) {
    final sellerStatus = kyc.sellerStatus ?? 'unknown';
    final statusColor = _getStatusColor(sellerStatus);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Uicons.shieldCheck, color: statusColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seller Status: ${sellerStatus.toUpperCase()}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          if (kyc.missingDocuments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Missing Documents:', style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...kyc.missingDocuments.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Uicons.circleExclamation, size: 14, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(doc, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                )),
          ],
          if (kyc.canSubmitForReview) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All documents uploaded. Admin will review.')),
                  );
                },
                icon: const Icon(Uicons.check),
                label: const Text('Ready for Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(
    BuildContext context,
    List<SellerKycDocumentModel> documents,
    SellerKycStatusModel kyc,
  ) {
    final docTypes = ['tin', 'business_registration', 'business_profile'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KYC Documents', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...docTypes.map((docType) {
          final doc = documents.where((d) => d.documentType == docType).toList();
          final hasDoc = doc.isNotEmpty;
          final status = hasDoc ? doc.first.status : 'not_uploaded';
          return _buildDocumentTile(context, docType, hasDoc, status, () => _uploadDocument(context, docType));
        }),
      ],
    );
  }

  Widget _buildDocumentTile(
    BuildContext context,
    String docType,
    bool hasDoc,
    String status,
    VoidCallback onUpload,
  ) {
    final statusColor = _getDocStatusColor(status);
    final label = _formatDocType(docType);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(hasDoc ? Uicons.file : Uicons.upload, color: statusColor),
        title: Text(label),
        subtitle: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11)),
        trailing: hasDoc
            ? const Icon(Uicons.checkCircle, color: Colors.green, size: 20)
            : ElevatedButton(
                onPressed: onUpload,
                child: const Text('Upload'),
              ),
      ),
    );
  }

  Widget _buildPayoutAccountsSection(BuildContext context, List<PayoutAccountModel> accounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payout Accounts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Uicons.plus),
              onPressed: () => _showAddPayoutDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (accounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No payout accounts yet. Add one to receive payouts.', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...accounts.map((account) => _buildPayoutAccountCard(context, account)),
      ],
    );
  }

  Widget _buildPayoutAccountCard(BuildContext context, PayoutAccountModel account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(account.accountType == 'bank' ? Uicons.bank : Uicons.smartphone, color: Theme.of(context).colorScheme.primary),
        title: Text(account.accountName),
        subtitle: Text('${account.provider} - ${account.accountNumber}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: const Text('DEFAULT', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
              ),
            IconButton(
              icon: const Icon(Uicons.trash, size: 18, color: Colors.red),
              onPressed: () => _confirmDelete(context, account.id),
            ),
          ],
        ),
      ),
    );
  }

  void _uploadDocument(BuildContext context, String docType) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      if (context.mounted) {
        await context.read<SellerCubit>().uploadKycDocument(
              documentType: docType,
              filePath: image.path,
              fileName: image.name,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddPayoutDialog(BuildContext context) {
    final accountType = ValueNotifier('bank');
    final providerController = TextEditingController();
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payout Account'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: accountType,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Bank'),
                            value: 'bank',
                            groupValue: value,
                            onChanged: (v) => accountType.value = v!,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Mobile Money'),
                            value: 'mobile_money',
                            groupValue: value,
                            onChanged: (v) => accountType.value = v!,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: providerController,
                  decoration: const InputDecoration(labelText: 'Provider *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account Name *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Account Number *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                context.read<SellerCubit>().createPayoutAccount({
                  'account_type': accountType.value,
                  'provider': providerController.text.trim(),
                  'account_name': nameController.text.trim(),
                  'account_number': numberController.text.trim(),
                  'currency': 'TZS',
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payout Account?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerCubit>().deletePayoutAccount(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.amber;
      case 'under_review': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getDocStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.amber;
      case 'under_review': return Colors.blue;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDocType(String type) {
    switch (type) {
      case 'tin': return 'TIN Certificate';
      case 'business_registration': return 'Business Registration';
      case 'business_profile': return 'Business Profile';
      default: return type;
    }
  }
}
