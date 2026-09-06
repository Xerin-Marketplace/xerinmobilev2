import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_icon.dart';
import '../../../../core/theme/uicons.dart';

class CustomerReviewsPage extends StatefulWidget {
  const CustomerReviewsPage({super.key});

  @override
  State<CustomerReviewsPage> createState() => _CustomerReviewsPageState();
}

class _CustomerReviewsPageState extends State<CustomerReviewsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
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
          BackIconButton(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            color: cs.primary,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
            const Color(0xFFF59E0B).withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('5.0',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFF59E0B),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(Uicons.star, size: 14, color: const Color(0xFFF59E0B)),
                  )),
                ],
              ),
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
              Container(width: 1, height: 30, color: cs.onSurface.withValues(alpha: 0.08)),
              _buildStatItem(cs, '0', 'Rated 5★'),
              Container(width: 1, height: 30, color: cs.onSurface.withValues(alpha: 0.08)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Uicons.star, size: 28, color: cs.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePreview(ColorScheme cs, bool isDark) {
    final features = [
      {'icon': Uicons.star, 'label': 'Track ratings', 'color': const Color(0xFFF59E0B)},
      {'icon': Uicons.comment, 'label': 'Seller replies', 'color': const Color(0xFF3B82F6)},
      {'icon': Uicons.badgeCheck, 'label': 'Verified tags', 'color': const Color(0xFF22C55E)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: features.map((f) {
          final color = f['color'] as Color;
          return Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(f['icon'] as IconData, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(f['label'] as String,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
