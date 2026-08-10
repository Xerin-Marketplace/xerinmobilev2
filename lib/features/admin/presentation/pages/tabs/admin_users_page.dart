import 'dart:async';
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
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await context.read<AdminCubit>().searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _hasSearched
                  ? _searchResults.isEmpty
                      ? _buildEmptyState('No users found for "${_searchCtrl.text}"')
                      : _buildUserList(_searchResults)
                  : BlocBuilder<AdminCubit, AdminState>(
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
                        if (state.users.isEmpty) {
                          return _buildEmptyState('No users found');
                        }
                        return _buildUserList(state.users);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users) {
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
        final accountType = user['account_type']?.toString() ?? 'customer';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: const TextStyle(fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
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
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 12, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Verified',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (status == 'active' ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: status == 'active'
                                  ? Colors.green
                                  : Colors.orange)),
                    ),
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
            Text('Failed to load users',
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
