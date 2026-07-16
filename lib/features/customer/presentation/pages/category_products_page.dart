import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';

class CategoryProductsPage extends StatelessWidget {
  final String category;

  const CategoryProductsPage({
    super.key,
    required this.category,
  });

  final List<Map<String, dynamic>> _allProducts = const [
    {'name': 'Wireless Headphones', 'price': 'TSh 325,000', 'category': 'Electronics', 'region': 'Dar es Salaam', 'icon': Icons.headphones_rounded},
    {'name': 'Smart Watch Series 5', 'price': 'TSh 622,500', 'category': 'Electronics', 'region': 'Arusha', 'icon': Icons.watch_rounded},
    {'name': 'Running Shoes Pro', 'price': 'TSh 224,000', 'category': 'Sports', 'region': 'Mwanza', 'icon': Icons.directions_run_rounded},
    {'name': 'Laptop Stand', 'price': 'TSh 115,000', 'category': 'Electronics', 'region': 'Dar es Salaam', 'icon': Icons.laptop_rounded},
    {'name': 'Organic Coffee Beans', 'price': 'TSh 62,500', 'category': 'Food', 'region': 'Kilimanjaro', 'icon': Icons.coffee_rounded},
    {'name': 'Cotton T-Shirt', 'price': 'TSh 50,000', 'category': 'Fashion', 'region': 'Dar es Salaam', 'icon': Icons.checkroom_rounded},
    {'name': 'Bluetooth Speaker', 'price': 'TSh 200,000', 'category': 'Electronics', 'region': 'Arusha', 'icon': Icons.speaker_rounded},
    {'name': 'Yoga Mat', 'price': 'TSh 86,000', 'category': 'Sports', 'region': 'Mwanza', 'icon': Icons.self_improvement_rounded},
    {'name': 'Kitchen Blender', 'price': 'TSh 150,000', 'category': 'Home', 'region': 'Dar es Salaam', 'icon': Icons.blender_rounded},
    {'name': 'Car Phone Holder', 'price': 'TSh 40,000', 'category': 'Auto', 'region': 'Arusha', 'icon': Icons.directions_car_rounded},
    {'name': 'Novel Book', 'price': 'TSh 32,500', 'category': 'Books', 'region': 'Mwanza', 'icon': Icons.book_rounded},
    {'name': 'Sunscreen Lotion', 'price': 'TSh 46,000', 'category': 'Health', 'region': 'Dar es Salaam', 'icon': Icons.health_and_safety_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final products = _allProducts
        .where((p) => p['category'] == category)
        .toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppConstants.categoriesRoute);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${products.length} products',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        children: products.map((product) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.onSurface.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    product['icon'] as IconData,
                                    color: colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['region'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product['price'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: colorScheme.onPrimary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
