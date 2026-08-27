import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/theme/uicons.dart';
import '../../presentation/cubit/admin_cubit.dart';

class AdminAdvertisementsPage extends StatefulWidget {
  const AdminAdvertisementsPage({super.key});

  @override
  State<AdminAdvertisementsPage> createState() =>
      _AdminAdvertisementsPageState();
}

class _AdminAdvertisementsPageState extends State<AdminAdvertisementsPage> {
  bool _isReloading = false;
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadAdvertisements();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Uicons.angleLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Advertisements'),
      ),
      body: SafeArea(
        child: BlocConsumer<AdminCubit, AdminState>(
          listener: (context, state) {
            if (state is AdminError) {
              NotificationService().error(state.message);
            }
            if (state is AdminActionSuccess) {
              NotificationService().success(state.message);
            }
          },
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminAdvertisementsLoaded) {
              if (state.ads.isEmpty) {
                return _buildEmpty(cs);
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<AdminCubit>().loadAdvertisements(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.ads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _AdCard(ad: state.ads[index]),
                ),
              );
            }
            if (!_isReloading) {
              _isReloading = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AdminCubit>().loadAdvertisements();
                _isReloading = false;
              });
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Uicons.plus),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Uicons.picture,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text('No Advertisements',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Create banner ads and promotions for the marketplace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Uicons.plus),
              label: const Text('Create Ad'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AdForm(),
    );
  }
}

class _AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;

  const _AdCard({required this.ad});

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = ad['status']?.toString();
    final title = ad['title']?.toString() ?? 'Untitled';
    final placement = ad['placement']?.toString() ?? '';
    final startDate = ad['start_date']?.toString() ?? '';
    final endDate = ad['end_date']?.toString() ?? '';
    final adId = ad['id']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (status ?? 'unknown').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'pause') {
                      context.read<AdminCubit>().pauseAdvertisement(adId);
                    } else if (action == 'delete') {
                      context.read<AdminCubit>().deleteAdvertisement(adId);
                    }
                  },
                  itemBuilder: (_) => [
                    if (status == 'active')
                      const PopupMenuItem(value: 'pause', child: Text('Pause')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (placement.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Placement: $placement',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Uicons.clock,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  '$startDate → $endDate',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdForm extends StatefulWidget {
  const _AdForm();

  @override
  State<_AdForm> createState() => _AdFormState();
}

class _AdFormState extends State<_AdForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _placement = 'home_banner';
  DateTime? _startDate;
  DateTime? _endDate;

  static const _placements = [
    {'value': 'home_banner', 'label': 'Home Banner'},
    {'value': 'category_banner', 'label': 'Category Banner'},
    {'value': 'product_detail', 'label': 'Product Detail'},
    {'value': 'search_top', 'label': 'Search Top'},
    {'value': 'sidebar', 'label': 'Sidebar'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) return;

    context.read<AdminCubit>().createAdvertisement({
      'title': _titleCtrl.text.trim(),
      'placement': _placement,
      'target_url': _urlCtrl.text.trim(),
      'start_date': _startDate!.toIso8601String(),
      'end_date': _endDate!.toIso8601String(),
      'status': 'active',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Advertisement',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              const SizedBox(height: 20),
              _field(cs, 'Title', _titleCtrl, 'Summer Sale Banner'),
              const SizedBox(height: 12),
              _field(cs, 'Target URL', _urlCtrl, 'https://...'),
              const SizedBox(height: 12),
              Text('Placement',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.7))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _placement,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cs.onSurface.withValues(alpha: 0.04),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                  ),
                ),
                items: _placements
                    .map((p) => DropdownMenuItem(
                          value: p['value'],
                          child: Text(p['label']!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _placement = v ?? 'home_banner'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: 'Start Date',
                      date: _startDate,
                      onChanged: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: 'End Date',
                      date: _endDate,
                      onChanged: (d) => setState(() => _endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Create Ad'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(ColorScheme cs, String label, TextEditingController ctrl,
      String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Select date',
              style: TextStyle(
                fontSize: 14,
                color: date != null
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
