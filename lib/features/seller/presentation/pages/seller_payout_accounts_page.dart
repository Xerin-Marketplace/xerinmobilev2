import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/seller_cubit.dart';
import '../../data/models/seller_models.dart';

class SellerPayoutAccountsPage extends StatefulWidget {
  const SellerPayoutAccountsPage({super.key});

  @override
  State<SellerPayoutAccountsPage> createState() => _SellerPayoutAccountsPageState();
}

class _SellerPayoutAccountsPageState extends State<SellerPayoutAccountsPage> {
  List<PayoutAccountModel> _accounts = [];

  @override
  void initState() {
    super.initState();
    context.read<SellerCubit>().loadPayoutAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Accounts')),
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
          if (state is SellerPayoutAccountsLoaded) {
            _accounts = state.accounts;
            return RefreshIndicator(
              onRefresh: () => context.read<SellerCubit>().loadPayoutAccounts(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _buildHeader(cs),
                  const SizedBox(height: 16),
                  _buildStats(cs),
                  const SizedBox(height: 16),
                  _buildInfoNote(cs),
                  const SizedBox(height: 24),
                  _buildAccountsSection(cs),
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
                    onPressed: () => context.read<SellerCubit>().loadPayoutAccounts(),
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
        Text('Seller Payout Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Add the bank or mobile-money account where Xerin can settle released marketplace earnings. New payout accounts require verification before they can be used for payout requests.',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
      ],
    );
  }

  Widget _buildStats(ColorScheme cs) {
    final verified = _accounts.where((a) => a.verificationStatus == 'verified').length;
    final pending = _accounts.where((a) => a.verificationStatus == 'pending').length;
    final rejected = _accounts.where((a) => a.verificationStatus == 'rejected').length;

    return Row(
      children: [
        _statCard(cs, '$verified', 'Verified', const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        _statCard(cs, '$pending', 'Pending', const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _statCard(cs, '$rejected', 'Rejected', const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _statCard(ColorScheme cs, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNote(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Uicons.circleInfo, size: 16, color: cs.primary.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('A payout request will only be accepted when the selected payout account is active and verified. Verification is performed by an authorized Xerin staff user.',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Registered accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            Text('${_accounts.length} payout ${_accounts.length == 1 ? 'account' : 'accounts'}',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 16),
        if (_accounts.isEmpty)
          _buildEmptyState(cs)
        else
          ..._accounts.map((a) => _buildAccountCard(cs, a)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _showAddForm(context),
            icon: const Icon(Uicons.plus, size: 18),
            label: const Text('Add payout account', style: TextStyle(fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Icon(Uicons.sackDollar, size: 48, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No payout accounts yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            Text('Add a bank or mobile-money account to receive payouts.',
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.3)),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(ColorScheme cs, PayoutAccountModel account) {
    final isBank = account.accountType == 'bank';
    final isVerified = account.verificationStatus == 'verified';
    final isPending = account.verificationStatus == 'pending';
    final isRejected = account.verificationStatus == 'rejected';
    final masked = account.accountNumber.length > 4
        ? '\u2022\u2022\u2022\u2022\u2022${account.accountNumber.substring(account.accountNumber.length - 4)}'
        : account.accountNumber;

    Color statusColor;
    String statusLabel;
    if (isVerified) { statusColor = const Color(0xFF22C55E); statusLabel = 'Verified'; }
    else if (isPending) { statusColor = const Color(0xFFF59E0B); statusLabel = 'Pending'; }
    else if (isRejected) { statusColor = const Color(0xFFEF4444); statusLabel = 'Rejected'; }
    else { statusColor = const Color(0xFF9CA3AF); statusLabel = 'Unverified'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: provider + default badge
          Row(
            children: [
              Icon(isBank ? Uicons.bank : Uicons.smartphone, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(account.provider, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
              ),
              if (account.isDefault) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // Account name
          Text(account.accountName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          // Masked number
          Text(masked, style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5), fontFamily: 'monospace')),
          const SizedBox(height: 8),
          // Type + currency
          Row(
            children: [
              Text(isBank ? 'Bank Account' : 'Mobile Money', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
              const SizedBox(width: 8),
              Text('\u00b7', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.3))),
              const SizedBox(width: 8),
              Text(account.currency, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
          const Divider(height: 20),
          // Status + dates + actions
          Row(
            children: [
              Icon(_statusIcon(account.verificationStatus), size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              if (account.verifiedAt != null) ...[
                const SizedBox(width: 8),
                Text('Verified ${_formatDate(account.verifiedAt!)}', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditForm(context, account),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(account),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444).withValues(alpha: 0.7))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'verified': return Uicons.circleCheck;
      case 'pending': return Uicons.clock;
      case 'rejected': return Uicons.circleExclamation;
      default: return Uicons.circleInfo;
    }
  }

  void _showAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PayoutAccountForm(
        onSaved: () { Navigator.pop(ctx); context.read<SellerCubit>().loadPayoutAccounts(); },
        onSubmit: (data) {
          context.read<SellerCubit>().createPayoutAccount(data);
        },
      ),
    );
  }

  void _showEditForm(BuildContext context, PayoutAccountModel account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _PayoutAccountForm(
        existing: account,
        onSaved: () { Navigator.pop(ctx); context.read<SellerCubit>().loadPayoutAccounts(); },
        onSubmit: (data) {
          context.read<SellerCubit>().updatePayoutAccount(id: account.id, data: data);
        },
      ),
    );
  }

  void _confirmDelete(PayoutAccountModel account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payout Account?'),
        content: Text('Delete ${account.provider} \u00b7 ${account.accountName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { Navigator.pop(ctx); context.read<SellerCubit>().deletePayoutAccount(account.id); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── Payout Account Form (Bottom Sheet) ───
class _PayoutAccountForm extends StatefulWidget {
  final PayoutAccountModel? existing;
  final VoidCallback onSaved;
  final void Function(Map<String, dynamic> data) onSubmit;

  const _PayoutAccountForm({this.existing, required this.onSaved, required this.onSubmit});

  @override
  State<_PayoutAccountForm> createState() => _PayoutAccountFormState();
}

class _PayoutAccountFormState extends State<_PayoutAccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _providerController;
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late String _accountType;
  late String _currency;
  late bool _isDefault;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _accountType = e?.accountType ?? 'bank';
    _currency = e?.currency ?? 'TZS';
    _isDefault = e?.isDefault ?? false;
    _providerController = TextEditingController(text: e?.provider ?? '');
    _nameController = TextEditingController(text: e?.accountName ?? '');
    _numberController = TextEditingController(text: e?.accountNumber ?? '');
  }

  @override
  void dispose() {
    _providerController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    widget.onSubmit({
      'account_type': _accountType,
      'provider': _providerController.text.trim(),
      'account_name': _nameController.text.trim(),
      'account_number': _numberController.text.trim(),
      'currency': _currency,
      'is_default': _isDefault,
    });
    widget.onSaved();
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEditing ? 'Edit Payout Account' : 'Add payout account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        const SizedBox(height: 2),
                        Text('Settlement destination for released seller earnings.',
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Uicons.crossSmall, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account type
                      _label(cs, 'Account type'),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = 'bank'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _accountType == 'bank' ? cs.primary.withValues(alpha: 0.08) : cs.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _accountType == 'bank' ? cs.primary : cs.onSurface.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Uicons.bank, size: 16, color: _accountType == 'bank' ? cs.primary : cs.onSurface.withValues(alpha: 0.4)),
                                    const SizedBox(width: 8),
                                    Text('Bank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _accountType == 'bank' ? cs.primary : cs.onSurface.withValues(alpha: 0.4))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _accountType = 'mobile_money'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _accountType == 'mobile_money' ? cs.primary.withValues(alpha: 0.08) : cs.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _accountType == 'mobile_money' ? cs.primary : cs.onSurface.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Uicons.smartphone, size: 16, color: _accountType == 'mobile_money' ? cs.primary : cs.onSurface.withValues(alpha: 0.4)),
                                    const SizedBox(width: 8),
                                    Text('Mobile Money', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _accountType == 'mobile_money' ? cs.primary : cs.onSurface.withValues(alpha: 0.4))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Provider / Bank name
                      _label(cs, _accountType == 'bank' ? 'Bank name *' : 'Provider *'),
                      TextFormField(
                        controller: _providerController,
                        decoration: _input(cs, _accountType == 'bank' ? 'e.g. CRDB Bank' : 'e.g. M-Pesa'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account holder name
                      _label(cs, 'Account holder name *'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _input(cs, 'Name registered on the payout account'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Account number
                      _label(cs, _accountType == 'bank' ? 'Bank account number *' : 'Mobile money number *'),
                      TextFormField(
                        controller: _numberController,
                        decoration: _input(cs, _accountType == 'bank' ? 'Enter bank account number' : 'Enter mobile money number'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Currency
                      _label(cs, 'Currency'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Text('TZS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface)),
                            const SizedBox(width: 8),
                            Text('\u2014 Tanzanian Shilling', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Default toggle
                      InkWell(
                        onTap: () => setState(() => _isDefault = !_isDefault),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Make this my default payout account',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                    const SizedBox(height: 2),
                                    Text('The backend will remove default status from your other payout accounts when this account is created as default.',
                                      style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
                                  ],
                                ),
                              ),
                              Switch(value: _isDefault, onChanged: (v) => setState(() => _isDefault = v)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                          : Text(isEditing ? 'Save Changes' : 'Add Payout Account', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Payout verification follows the Admin policy. In Automatic mode, new or materially edited accounts are verified automatically; in Manual mode they wait for Admin review.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(ColorScheme cs, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.7))),
    );
  }

  InputDecoration _input(ColorScheme cs, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
