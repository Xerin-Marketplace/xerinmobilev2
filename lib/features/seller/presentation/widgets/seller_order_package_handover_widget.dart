import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/seller_models.dart';
import '../cubit/seller_cubit.dart';

class SellerOrderPackageHandoverWidget extends StatefulWidget {
  final String sellerOrderId;

  const SellerOrderPackageHandoverWidget({
    super.key,
    required this.sellerOrderId,
  });

  @override
  State<SellerOrderPackageHandoverWidget> createState() =>
      _SellerOrderPackageHandoverWidgetState();
}

class _SellerOrderPackageHandoverWidgetState
    extends State<SellerOrderPackageHandoverWidget> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<SellerCubit>();
    cubit.loadOrderPackage(widget.sellerOrderId);
    cubit.loadFulfillmentReadiness(widget.sellerOrderId);
    cubit.loadHandover(widget.sellerOrderId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerCubit, SellerState>(
      buildWhen: (prev, curr) =>
          curr is SellerOrderPackageLoaded ||
          curr is SellerOrderPackageSaved ||
          curr is SellerFulfillmentReadinessLoaded ||
          curr is SellerHandoverLoaded ||
          curr is SellerHandoverConfirmed ||
          curr is SellerLoading ||
          curr is SellerError,
      builder: (context, state) {
        return Column(
          children: [
            _PackageSection(sellerOrderId: widget.sellerOrderId),
            const SizedBox(height: 8),
            _ReadinessSection(sellerOrderId: widget.sellerOrderId),
            const SizedBox(height: 8),
            _HandoverSection(sellerOrderId: widget.sellerOrderId),
          ],
        );
      },
    );
  }
}

class _PackageSection extends StatefulWidget {
  final String sellerOrderId;

  const _PackageSection({required this.sellerOrderId});

  @override
  State<_PackageSection> createState() => _PackageSectionState();
}

class _PackageSectionState extends State<_PackageSection> {
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _packageCount = 1;
  bool _isReady = false;
  bool _initialized = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _syncFromPackage(SellerOrderPackageModel package) {
    if (_initialized) return;
    _initialized = true;
    _packageCount = package.packageCount;
    _isReady = package.isReady;
    if (package.weightKg != null) _weightCtrl.text = package.weightKg.toString();
    if (package.lengthCm != null) _lengthCtrl.text = package.lengthCm.toString();
    if (package.widthCm != null) _widthCtrl.text = package.widthCm.toString();
    if (package.heightCm != null) _heightCtrl.text = package.heightCm.toString();
    if (package.notes != null) _notesCtrl.text = package.notes!;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerCubit, SellerState>(
      buildWhen: (prev, curr) =>
          curr is SellerOrderPackageLoaded ||
          curr is SellerOrderPackageSaved ||
          curr is SellerLoading ||
          curr is SellerError,
      builder: (context, state) {
        if (state is SellerOrderPackageLoaded) {
          _syncFromPackage(state.package);
        }
        if (state is SellerOrderPackageSaved) {
          _syncFromPackage(state.package);
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Packaging',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const Spacer(),
                    if (_isReady)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'READY',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Text('Package count: ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _packageCount > 1
                          ? () => setState(() => _packageCount--)
                          : null,
                    ),
                    Text('$_packageCount',
                        style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _packageCount++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lengthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'L (cm)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _widthCtrl,
                        decoration: const InputDecoration(
                          labelText: 'W (cm)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        decoration: const InputDecoration(
                          labelText: 'H (cm)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Mark as ready'),
                  value: _isReady,
                  onChanged: (v) => setState(() => _isReady = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (state is SellerLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _savePackage(context),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Package'),
                    ),
                  ),
                if (state is SellerError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      (state is SellerError) ? state.message : 'An error occurred',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _savePackage(BuildContext context) {
    context.read<SellerCubit>().saveOrderPackage(
          widget.sellerOrderId,
          packageCount: _packageCount,
          isReady: _isReady,
          weightKg: double.tryParse(_weightCtrl.text),
          lengthCm: double.tryParse(_lengthCtrl.text),
          widthCm: double.tryParse(_widthCtrl.text),
          heightCm: double.tryParse(_heightCtrl.text),
          notes: _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        );
  }
}

class _ReadinessSection extends StatelessWidget {
  final String sellerOrderId;

  const _ReadinessSection({required this.sellerOrderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerCubit, SellerState>(
      buildWhen: (prev, curr) =>
          curr is SellerFulfillmentReadinessLoaded ||
          curr is SellerLoading,
      builder: (context, state) {
        if (state is SellerFulfillmentReadinessLoaded) {
          final readiness = state.readiness;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Fulfillment Readiness',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      if (readiness.readyToShip)
                        Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                      else
                        Icon(Icons.pending,
                            color: Theme.of(context).colorScheme.tertiary),
                    ],
                  ),
                  const Divider(height: 16),
                  if (readiness.blockers.isNotEmpty) ...[
                    Text('Blockers',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold)),
                    ...readiness.blockers.map((b) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.block,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 4),
                              Expanded(child: Text(b, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                  if (readiness.warnings.isNotEmpty) ...[
                    Text('Warnings',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold)),
                    ...readiness.warnings.map((w) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.tertiary),
                              const SizedBox(width: 4),
                              Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 8),
                  ],
                  ...readiness.checks.map((check) => _ReadinessCheckTile(check: check)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total weight: ${readiness.totalWeightKg} kg',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Packages: ${readiness.physicalPackageCount}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ReadinessCheckTile extends StatelessWidget {
  final FulfillmentReadinessCheck check;

  const _ReadinessCheckTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final color = check.ready
        ? Theme.of(context).colorScheme.primary
        : check.blocking
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.tertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            check.ready ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                if (check.detail != null)
                  Text(check.detail!,
                      style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoverSection extends StatelessWidget {
  final String sellerOrderId;

  const _HandoverSection({required this.sellerOrderId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerCubit, SellerState>(
      buildWhen: (prev, curr) =>
          curr is SellerHandoverLoaded ||
          curr is SellerHandoverConfirmed ||
          curr is SellerLoading ||
          curr is SellerError,
      builder: (context, state) {
        ShipmentHandoverModel? handover;
        if (state is SellerHandoverLoaded) handover = state.handover;
        if (state is SellerHandoverConfirmed) handover = state.handover;
        if (handover == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Courier Handover',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _HandoverRow(
                  label: 'Status',
                  value: handover.status.replaceAll('_', ' ').toUpperCase(),
                ),
                if (handover.courierArrivedAt != null)
                  _HandoverRow(
                    label: 'Courier arrived',
                    value: handover.courierArrivedAt!,
                  ),
                if (handover.courierArrivalNotes != null)
                  _HandoverRow(
                    label: 'Arrival notes',
                    value: handover.courierArrivalNotes!,
                  ),
                if (handover.sellerConfirmedAt != null)
                  _HandoverRow(
                    label: 'Confirmed at',
                    value: handover.sellerConfirmedAt!,
                  ),
                if (handover.sellerConfirmationNotes != null)
                  _HandoverRow(
                    label: 'Confirmation notes',
                    value: handover.sellerConfirmationNotes!,
                  ),
                if (handover.status == 'courier_arrived') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state is SellerLoading
                          ? null
                          : () => _showConfirmDialog(context),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Handover'),
                    ),
                  ),
                ],
                if (state is SellerError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      (state is SellerError) ? state.message : 'An error occurred',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Handover'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerCubit>().confirmHandover(
                    sellerOrderId,
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _HandoverRow extends StatelessWidget {
  final String label;
  final String value;

  const _HandoverRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
