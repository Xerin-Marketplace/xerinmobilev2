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
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Product Categories'),
              Tab(text: 'Business Categories'),
              Tab(text: 'Brands'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductCategoriesTab(),
            _BusinessCategoriesTab(),
            _BrandsTab(),
          ],
        ),
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
                  ? const Center(child: Text('No categories found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final name = cat['name']?.toString() ?? 'Unknown';
                        final desc = cat['description']?.toString() ?? '';
                        final id = cat['id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.category_rounded),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
                  ? const Center(child: Text('No business categories found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final name = cat['name']?.toString() ?? 'Unknown';
                        final desc = cat['description']?.toString() ?? '';
                        final id = cat['id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.business_rounded),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
                  ? const Center(child: Text('No brands found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: brands.length,
                      itemBuilder: (context, index) {
                        final brand = brands[index];
                        final name = brand['name']?.toString() ?? 'Unknown';
                        final id = brand['id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.branding_watermark_rounded),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
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
