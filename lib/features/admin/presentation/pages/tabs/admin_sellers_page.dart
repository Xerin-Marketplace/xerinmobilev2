import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';
import '../../cubit/admin_state.dart';

class AdminSellersPage extends StatelessWidget {
  const AdminSellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'All Sellers'),
              Tab(text: 'Pending Approval'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSellersList(context, isPending: false),
                _buildSellersList(context, isPending: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellersList(BuildContext context,
      {required bool isPending}) {
    return BlocBuilder<AdminCubit, AdminState>(
      builder: (context, state) {
        if (state is AdminError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<AdminCubit>().loadDashboard(),
          );
        }

        if (state is! AdminDashboardLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final sellers =
            isPending ? state.pendingSellers : state.sellers;

        if (sellers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPending ? Icons.pending_actions_outlined : Icons.store_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(isPending
                    ? 'No pending sellers'
                    : 'No sellers found',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                if (!isPending) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showRegisterSellerDialog(context),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Register Seller'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AdminCubit>().loadDashboard(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellers.length + (isPending ? 0 : 1),
            itemBuilder: (context, index) {
              if (!isPending && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _showRegisterSellerDialog(context),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Register New Seller'),
                    ),
                  ),
                );
              }
              final sellerIndex = isPending ? index : index - 1;
              final seller = sellers[sellerIndex];
              final name = seller['business_name']?.toString() ??
                  seller['seller_name']?.toString() ??
                  'Unknown Business';
              final email = seller['email']?.toString() ?? 'No email';
              final phone = seller['phone']?.toString() ?? 'No phone';
              final status = seller['status']?.toString() ?? 'unknown';
              final id = seller['id']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                    child: Icon(Icons.store_rounded,
                        color: _getStatusColor(status)),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: const TextStyle(fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(label: 'Phone', value: phone),
                          _InfoRow(
                              label: 'Seller ID', value: id.substring(0, id.length > 8 ? 8 : id.length)),
                          if (isPending) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Approve'),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.green),
                                    onPressed: () => context
                                        .read<AdminCubit>()
                                        .approveSeller(id),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    onPressed: () => _showRejectDialog(
                                        context, id),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showRejectDialog(BuildContext context, String id) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Seller'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<AdminCubit>()
                  .rejectSeller(id, reason: reasonCtrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showRegisterSellerDialog(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final businessNameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register Seller'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: businessNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                context.read<AdminCubit>().registerSeller(
                      firstName: firstNameCtrl.text.trim(),
                      lastName: lastNameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty
                          ? null
                          : phoneCtrl.text.trim(),
                      password: passwordCtrl.text,
                      businessName: businessNameCtrl.text.trim(),
                    );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text('Failed to load sellers',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
