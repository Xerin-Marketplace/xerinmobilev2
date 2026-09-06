import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../config/di/service_locator.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../../data/models/category_model.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final ProductsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ProductsCubit>()..loadCategories();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocProvider.value(
        value: _cubit,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppConstants.homeRoute);
                        }
                      },
                      child: Icon(Icons.arrow_back, size: 22, color: colorScheme.onSurface),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse products by category',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 24),
              BlocBuilder<ProductsCubit, ProductsState>(
                builder: (context, state) {
                  if (state is ProductsLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (state is ProductsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    );
                  }
                  final categories = state is ProductsLoaded ? state.categories : <CategoryModel>[];
                  if (categories.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No categories available'),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return GestureDetector(
                        onTap: () => context.go(
                          AppConstants.categoryProductsRoute,
                          extra: {'category': cat.name, 'categoryId': cat.id},
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
