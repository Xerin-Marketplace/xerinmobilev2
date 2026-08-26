import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/uicons.dart';
import '../cubit/admin_cubit.dart';
import '../../data/models/admin_models.dart';

class AdminSellersPage extends StatefulWidget {
  const AdminSellersPage({super.key});

  @override
  State<AdminSellersPage> createState() => _AdminSellersPageState();
}

class _AdminSellersPageState extends State<AdminSellersPage> {
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadSellers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Management'),
        actions: [
          IconButton(
            icon: const Icon(Uicons.refresh),
            onPressed: () => context.read<AdminCubit>().loadSellers(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('All', 'all'),
            _filterChip('Pending', 'pending'),
            _filterChip('Under Review', 'under_review'),
            _filterChip('Approved', 'approved'),
            _filterChip('Rejected', 'rejected'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _statusFilter == value,
        onSelected: (_) {
          setState(() => _statusFilter = value);
        },
      ),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<AdminCubit, AdminState>(
      listener: (context, state) {
        if (state is AdminActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
        }
        if (state is AdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is AdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminSellersLoaded) {
          final filtered = _statusFilter == 'all'
              ? state.sellers
              : state.sellers.where((s) => s.status == _statusFilter).toList();
          if (filtered.isEmpty) {
            return const Center(child: Text('No sellers found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _sellerCard(context, filtered[index]),
          );
        }
        if (state is AdminSellerDetailLoaded) {
          return _sellerDetail(context, state);
        }
        return const Center(child: Text('Loading...'));
      },
    );
  }

  Widget _sellerCard(BuildContext context, AdminSellerModel seller) {
    final color = _statusColor(seller.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Uicons.storeAlt, color: color),
        ),
        title: Text(seller.businessName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (seller.contactEmail != null)
              Text(seller.contactEmail!, style: const TextStyle(fontSize: 12)),
            if (seller.contactPhone != null)
              Text(seller.contactPhone!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(_humanize(seller.status),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
        trailing: const Icon(Uicons.angleRight),
        onTap: () => context.read<AdminCubit>().openSellerDetail(seller),
      ),
    );
  }

  Widget _sellerDetail(BuildContext context, AdminSellerDetailLoaded state) {
    final seller = state.seller;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _statusColor(seller.status).withValues(alpha: 0.1),
                      child: Icon(Uicons.storeAlt, color: _statusColor(seller.status)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(seller.businessName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_humanize(seller.status),
                              style: TextStyle(color: _statusColor(seller.status))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoRow('Email', seller.contactEmail ?? 'N/A'),
                _infoRow('Phone', seller.contactPhone ?? 'N/A'),
                _infoRow('Category', seller.businessCategory ?? 'N/A'),
                _infoRow('Address', seller.address ?? 'N/A'),
                if (seller.rejectionReason != null)
                  _infoRow('Rejection Reason', seller.rejectionReason!),
                _infoRow('Created', seller.createdAt ?? 'N/A'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('KYC Documents',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (state.documentsLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.documents.isEmpty)
          const Card(child: ListTile(title: Text('No documents uploaded')))
        else
          ...state.documents.map((doc) => _documentCard(context, doc)),
        const SizedBox(height: 16),
        if (seller.status == 'pending' || seller.status == 'under_review') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white),
                  icon: const Icon(Uicons.checkCircle, size: 18),
                  label: const Text('Approve'),
                  onPressed: () => _confirmApprove(context, seller.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                  icon: const Icon(Uicons.circleXmark, size: 18),
                  label: const Text('Reject'),
                  onPressed: () => _showRejectDialog(context, seller.id),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Uicons.angleLeft),
          label: const Text('Back to List'),
          onPressed: () => context.read<AdminCubit>().loadSellers(),
        ),
      ],
    );
  }

  Widget _documentCard(BuildContext context, AdminSellerDocumentModel doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Uicons.file, color: _statusColor(doc.status)),
        title: Text(_humanize(doc.documentType),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Status: ${_humanize(doc.status)}'),
        trailing: doc.fileUrl != null
            ? TextButton(
                onPressed: () {},
                child: const Text('View'),
              )
            : null,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext context, String sellerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Seller?'),
        content: const Text('This will activate the seller account on the marketplace.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminCubit>().approveSeller(sellerId);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String sellerId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Seller'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              context.read<AdminCubit>().rejectSeller(sellerId, reasonController.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _humanize(String s) => s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
