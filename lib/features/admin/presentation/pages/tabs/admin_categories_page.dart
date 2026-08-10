import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/admin_cubit.dart';
import '../../cubit/admin_state.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Business'),
              Tab(text: 'Brands'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ProductCategoriesTab(),
                _BusinessCategoriesTab(),
                _BrandsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCategoriesTab extends StatelessWidget {
  const _ProductCategoriesTab();

  @override
  Widget build(BuildContext context) {
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

        final categories = state.productCategories;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Product Category'),
                  onPressed: () => _showCreateDialog(
                    context,
                    title: 'Create Product Category',
                    onCreate: (name, desc) => context
                        .read<AdminCubit>()
                        .createProductCategory(name, description: desc),
                  ),
                ),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? _buildEmptyState(context, 'No product categories found')
                  : RefreshIndicator(
                      onRefresh: () => context.read<AdminCubit>().loadDashboard(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final name = cat['name']?.toString() ?? 'Unknown';
                          final desc = cat['description']?.toString() ?? '';
                          final id = cat['id']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.category_rounded),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: desc.isNotEmpty
                                  ? Text(desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13))
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirm(context, id, name, () {
                                  context
                                      .read<AdminCubit>()
                                      .deleteProductCategory(id);
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BusinessCategoriesTab extends StatelessWidget {
  const _BusinessCategoriesTab();

  @override
  Widget build(BuildContext context) {
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

        final categories = state.businessCategories;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Business Category'),
                  onPressed: () => _showCreateDialog(
                    context,
                    title: 'Create Business Category',
                    onCreate: (name, desc) => context
                        .read<AdminCubit>()
                        .createBusinessCategory(name, description: desc),
                  ),
                ),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? _buildEmptyState(context, 'No business categories found')
                  : RefreshIndicator(
                      onRefresh: () => context.read<AdminCubit>().loadDashboard(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final name = cat['name']?.toString() ?? 'Unknown';
                          final desc = cat['description']?.toString() ?? '';
                          final id = cat['id']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.business_rounded),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: desc.isNotEmpty
                                  ? Text(desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13))
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirm(context, id, name, () {
                                  context
                                      .read<AdminCubit>()
                                      .deleteBusinessCategory(id);
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BrandsTab extends StatelessWidget {
  const _BrandsTab();

  @override
  Widget build(BuildContext context) {
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

        final brands = state.brands;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Brand'),
                  onPressed: () => _showCreateDialog(
                    context,
                    title: 'Create Brand',
                    onCreate: (name, desc) => context
                        .read<AdminCubit>()
                        .createBrand(name, description: desc),
                  ),
                ),
              ),
            ),
            Expanded(
              child: brands.isEmpty
                  ? _buildEmptyState(context, 'No brands found')
                  : RefreshIndicator(
                      onRefresh: () => context.read<AdminCubit>().loadDashboard(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: brands.length,
                        itemBuilder: (context, index) {
                          final brand = brands[index];
                          final name = brand['name']?.toString() ?? 'Unknown';
                          final id = brand['id']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.branding_watermark_rounded),
                              ),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.red),
                                onPressed: () =>
                                    _showDeleteConfirm(context, id, name, () {
                                  context.read<AdminCubit>().deleteBrand(id);
                                }),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

void _showCreateDialog(
  BuildContext context, {
  required String title,
  required void Function(String name, String description) onCreate,
}) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
              onCreate(nameCtrl.text.trim(), descCtrl.text.trim());
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirm(
  BuildContext context,
  String id,
  String name,
  VoidCallback onConfirm,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Delete'),
      content: Text('Are you sure you want to delete "$name"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Widget _buildEmptyState(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(message,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    ),
  );
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
            Text('Failed to load',
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
