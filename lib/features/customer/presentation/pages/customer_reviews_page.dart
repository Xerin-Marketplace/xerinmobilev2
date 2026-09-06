import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerReviewsPage extends StatefulWidget {
  const CustomerReviewsPage({super.key});

  @override
  State<CustomerReviewsPage> createState() => _CustomerReviewsPageState();
}

class _CustomerReviewsPageState extends State<CustomerReviewsPage> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildStatsCard(cs, isDark),
                    const SizedBox(height: 24),
                    Text('Review Highlights',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text('Your latest product reviews and ratings',
                      style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 16),
                    _buildReviewItems(cs, isDark),
                    const SizedBox(height: 24),
                    _buildFeaturePreview(cs, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
          ),
          const SizedBox(width: 16),
          Text('My Reviews',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('5.0',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.star, size: 24, color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Average Rating',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(cs, '0', 'Reviews'),
              _buildStatItem(cs, '0', 'Rated 5★'),
              _buildStatItem(cs, '0', 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ColorScheme cs, String value, String label) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
      ],
    );
  }

  Widget _buildReviewItems(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        Text('No Reviews Yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 6),
        Text('After receiving your orders, you can rate and review products here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Browse Products to Review',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePreview(ColorScheme cs, bool isDark) {
    final features = [
      {'icon': Icons.star, 'label': 'Track ratings', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.comment_outlined, 'label': 'Seller replies', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.verified_outlined, 'label': 'Verified tags', 'color': const Color(0xFF22C55E)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: features.map((f) {
        final color = f['color'] as Color;
        return Column(
          children: [
            Icon(f['icon'] as IconData, color: color, size: 22),
            const SizedBox(height: 8),
            Text(f['label'] as String,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
