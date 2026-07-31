import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';
import '../../cubit/admin_state.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await context.read<AdminCubit>().searchUsers(query);
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Search users',
              hintText: 'Search by name or email...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _isSearching == false && _searchResults.isNotEmpty
                  ? _buildUserList(_searchResults)
                  : BlocBuilder<AdminCubit, AdminState>(
                      builder: (context, state) {
                        if (state is! AdminDashboardLoaded) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return _buildUserList(state.users);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No users found'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final name =
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        final email = user['email']?.toString() ?? 'No email';
        final isVerified = user['is_verified'] as bool? ?? false;
        final status = user['status']?.toString() ?? 'unknown';
        final roles = user['roles'];
        final accountType = user['account_type']?.toString() ?? 'customer';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRoleColor(accountType).withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: _getRoleColor(accountType),
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name.isEmpty ? 'Unknown' : name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: const TextStyle(fontSize: 13)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(accountType).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        accountType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(accountType),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isVerified)
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(status,
                        style: TextStyle(
                            fontSize: 11,
                            color: status == 'active'
                                ? Colors.green
                                : Colors.orange)),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                final id = user['id']?.toString() ?? '';
                if (value == 'verify') {
                  context.read<AdminCubit>().verifyUser(id);
                } else if (value == 'delete') {
                  _showDeleteConfirm(context, id, name);
                }
              },
              itemBuilder: (context) => [
                if (!isVerified)
                  const PopupMenuItem(
                    value: 'verify',
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Verify User'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String accountType) {
    switch (accountType) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.purple;
      case 'seller':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showDeleteConfirm(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AdminCubit>().deleteUser(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
