import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/escrow_model.dart';
import '../../data/models/protection_claim_model.dart';
import '../cubit/customer_cubit.dart';
import '../cubit/customer_state.dart';

class EscrowProtectionWidget extends StatefulWidget {
  final String orderId;

  const EscrowProtectionWidget({super.key, required this.orderId});

  @override
  State<EscrowProtectionWidget> createState() => _EscrowProtectionWidgetState();
}

class _EscrowProtectionWidgetState extends State<EscrowProtectionWidget> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerCubit>().loadEscrowStatus(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      buildWhen: (prev, curr) =>
          curr is EscrowLoaded ||
          curr is EscrowItemAccepted ||
          curr is CustomerActionInProgress ||
          curr is CustomerActionError,
      builder: (context, state) {
        if (state is CustomerActionInProgress) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is CustomerActionError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        EscrowSummary? escrow;
        if (state is EscrowLoaded) escrow = state.escrow;
        if (state is EscrowItemAccepted) escrow = state.escrow;
        if (escrow == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Order Protection & Escrow',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _EscrowRow(
                  label: 'Status',
                  value: escrow.status.toUpperCase(),
                  highlight: escrow.status == 'held',
                ),
                _EscrowRow(
                  label: 'Seller Amount',
                  value: '${escrow.sellerAmount} ${escrow.currency}',
                ),
                _EscrowRow(
                  label: 'Released',
                  value: '${escrow.releasedAmount} ${escrow.currency}',
                ),
                _EscrowRow(
                  label: 'Remaining',
                  value: '${escrow.remainingAmount} ${escrow.currency}',
                ),
                if (escrow.releaseAfter != null)
                  _EscrowRow(
                    label: 'Auto-release',
                    value: escrow.releaseAfter!,
                  ),
                if (escrow.canCustomerApprove) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showApproveReceiptDialog(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve Receipt'),
                    ),
                  ),
                ],
                if (escrow.canReportProblem) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showProtectionClaimDialog(context),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Report a Problem'),
                    ),
                  ),
                ],
                if (escrow.items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...escrow.items.map((item) => _EscrowItemTile(
                        item: item,
                        onAccept: item.canCustomerAccept
                            ? () => _acceptItem(context, item.orderItemId)
                            : null,
                      )),
                ],
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _viewProtectionClaims(context),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View Protection Claims'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showApproveReceiptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Receipt'),
        content: const Text(
            'By approving, you confirm you have received the order in good condition. Funds will be released to the seller.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CustomerCubit>().approveReceipt(widget.orderId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showProtectionClaimDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ProtectionClaimDialog(),
    );
  }

  void _acceptItem(BuildContext context, String orderItemId) {
    context.read<CustomerCubit>().acceptEscrowItem(
          orderId: widget.orderId,
          orderItemId: orderItemId,
        );
  }

  void _viewProtectionClaims(BuildContext context) {
    context.read<CustomerCubit>().loadProtectionClaims(widget.orderId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProtectionClaimsSheet(orderId: widget.orderId),
    );
  }
}

class _EscrowRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _EscrowRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: highlight
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _EscrowItemTile extends StatelessWidget {
  final EscrowItemSummary item;
  final VoidCallback? onAccept;

  const _EscrowItemTile({required this.item, this.onAccept});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${item.orderItemId}',
                    style: Theme.of(context).textTheme.bodySmall),
                Text('Status: ${item.status}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),
          if (onAccept != null)
            TextButton(
              onPressed: onAccept,
              child: const Text('Accept'),
            ),
        ],
      ),
    );
  }
}

class _ProtectionClaimsSheet extends StatelessWidget {
  final String orderId;

  const _ProtectionClaimsSheet({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<CustomerCubit, CustomerState>(
          buildWhen: (prev, curr) =>
              curr is ProtectionClaimsLoaded ||
              curr is CustomerActionInProgress ||
              curr is CustomerActionError,
          builder: (context, state) {
            if (state is CustomerActionInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProtectionClaimsLoaded) {
              if (state.claims.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
          Text('Protection Claims',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text('No protection claims filed.'),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
          Text('Protection Claims (${state.claims.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.claims.length,
                      itemBuilder: (context, index) {
                        final claim = state.claims[index];
                        return _ProtectionClaimTile(claim: claim);
                      },
                    ),
                  ),
                ],
              );
            }
            return const Center(child: Text('Loading claims...'));
          },
        );
      },
    );
  }
}

class _ProtectionClaimTile extends StatelessWidget {
  final ProtectionClaim claim;

  const _ProtectionClaimTile({required this.claim});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(claim.reason,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (claim.notes != null) Text(claim.notes!),
            const SizedBox(height: 4),
            Row(
              children: [
                _ClaimChip(label: claim.status),
                const SizedBox(width: 8),
                if (claim.holdApplied)
                  _ClaimChip(
                    label: 'HOLD',
                    color: Theme.of(context).colorScheme.errorContainer,
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(claim.scope,
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _ClaimChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _ClaimChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ProtectionClaimDialog extends StatefulWidget {
  const _ProtectionClaimDialog();

  @override
  State<_ProtectionClaimDialog> createState() => _ProtectionClaimDialogState();
}

class _ProtectionClaimDialogState extends State<_ProtectionClaimDialog> {
  final _notesCtrl = TextEditingController();
  String _scope = 'order';
  String _reason = 'item_not_as_described';
  String _whenNoticed = 'on_opening';
  bool _packageDamaged = false;
  bool _productUsed = false;

  static const _reasons = [
    ('item_not_as_described', 'Item not as described'),
    ('item_damaged', 'Item damaged'),
    ('item_missing', 'Item missing'),
    ('wrong_item', 'Wrong item received'),
    ('quality_issue', 'Quality issue'),
    ('delivery_issue', 'Delivery issue'),
    ('other', 'Other'),
  ];

  static const _whenNoticedOptions = [
    ('before_acceptance', 'Before acceptance'),
    ('on_opening', 'On opening package'),
    ('after_initial_use', 'After initial use'),
    ('later_after_delivery', 'Later after delivery'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report a Problem'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _scope,
              decoration: const InputDecoration(labelText: 'Scope'),
              items: const [
                DropdownMenuItem(value: 'order', child: Text('Entire Order')),
                DropdownMenuItem(value: 'item', child: Text('Specific Item')),
              ],
              onChanged: (v) => setState(() => _scope = v ?? 'order'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'other'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _whenNoticed,
              decoration: const InputDecoration(labelText: 'When noticed'),
              items: _whenNoticedOptions
                  .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _whenNoticed = v ?? 'on_opening'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Describe the problem...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Package damaged'),
              value: _packageDamaged,
              onChanged: (v) => setState(() => _packageDamaged = v),
            ),
            SwitchListTile(
              title: const Text('Product used'),
              value: _productUsed,
              onChanged: (v) => setState(() => _productUsed = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<CustomerCubit>().createProtectionClaim(
                  orderId: context
                      .findAncestorWidgetOfExactType<EscrowProtectionWidget>()!
                      .orderId,
                  scope: _scope,
                  reason: _reason,
                  notes: _notesCtrl.text.trim(),
                  whenNoticed: _whenNoticed,
                  packageDamaged: _packageDamaged,
                  productUsed: _productUsed,
                );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
