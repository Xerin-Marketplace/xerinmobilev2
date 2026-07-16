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

  static IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('electron')) return Icons.devices_rounded;
    if (n.contains('fashion') || n.contains('cloth') || n.contains('wear')) return Icons.checkroom_rounded;
    if (n.contains('home') || n.contains('furniture')) return Icons.home_rounded;
    if (n.contains('auto') || n.contains('car') || n.contains('vehicle')) return Icons.directions_car_rounded;
    if (n.contains('sport') || n.contains('fitness')) return Icons.sports_soccer_rounded;
    if (n.contains('book') || n.contains('media')) return Icons.book_rounded;
    if (n.contains('health') || n.contains('beauty')) return Icons.health_and_safety_rounded;
    if (n.contains('food') || n.contains('beverage') || n.contains('grocery')) return Icons.restaurant_rounded;
    return Icons.category_rounded;
  }

  static Color _categoryColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('electron')) return const Color(0xFF3B82F6);
    if (n.contains('fashion')) return const Color(0xFFEC4899);
    if (n.contains('home')) return const Color(0xFFF59E0B);
    if (n.contains('auto')) return const Color(0xFF6366F1);
    if (n.contains('sport')) return const Color(0xFF22C55E);
    if (n.contains('book')) return const Color(0xFF8B5CF6);
    if (n.contains('health')) return const Color(0xFF14B8A6);
    if (n.contains('food')) return const Color(0xFFF97316);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'All Categories',
                    style: TextStyle(
                      fontSize: 24,
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
                  fontSize: 15,
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
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final color = _categoryColor(cat.name);
                      return GestureDetector(
                        onTap: () => context.go(
                          AppConstants.categoryProductsRoute,
                          extra: {'category': cat.name, 'categoryId': cat.id},
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(alpha: 0.15),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _categoryIcon(cat.name),
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
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
