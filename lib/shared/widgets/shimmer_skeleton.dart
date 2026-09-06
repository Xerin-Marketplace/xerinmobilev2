import 'package:flutter/material.dart';

/// A reusable shimmer skeleton loader for premium loading states.
/// Provides a smooth gradient sweep animation across placeholder boxes.

class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade300);
    final highlight = widget.highlightColor ??
        (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 0.3, 0),
              end: Alignment(_animation.value + 0.3, 0),
              colors: [base, highlight, base],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A skeleton card that mimics a product card layout.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: 10,
          ),
          const SizedBox(height: 10),
          const ShimmerSkeleton(width: 140, height: 14),
          const SizedBox(height: 6),
          const ShimmerSkeleton(width: 90, height: 12),
          const SizedBox(height: 10),
          const ShimmerSkeleton(width: 70, height: 16, borderRadius: 6),
        ],
      ),
    );
  }
}

/// A skeleton row that mimics a list item.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const ShimmerSkeleton(width: 52, height: 52, borderRadius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerSkeleton(width: 180, height: 14),
                const SizedBox(height: 6),
                const ShimmerSkeleton(width: 100, height: 12),
              ],
            ),
          ),
          const ShimmerSkeleton(width: 50, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

/// A skeleton block for category chips.
class CategoryChipSkeleton extends StatelessWidget {
  const CategoryChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          const ShimmerSkeleton(width: 60, height: 60, borderRadius: 30),
          const SizedBox(height: 8),
          ShimmerSkeleton(
            width: 50,
            height: 10,
            borderRadius: 4,
            baseColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ],
      ),
    );
  }
}

/// A full home page loading skeleton.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Header skeleton
          Row(
            children: [
              const ShimmerSkeleton(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerSkeleton(width: 100, height: 12),
                  SizedBox(height: 6),
                  ShimmerSkeleton(width: 140, height: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar skeleton
          const ShimmerSkeleton(height: 48, borderRadius: 14),
          const SizedBox(height: 16),
          // Hero banner skeleton
          const ShimmerSkeleton(height: 180, borderRadius: 16),
          const SizedBox(height: 24),
          // Section title skeleton
          const ShimmerSkeleton(width: 160, height: 18),
          const SizedBox(height: 14),
          // Category chips skeleton
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => const CategoryChipSkeleton(),
            ),
          ),
          const SizedBox(height: 28),
          // Section title
          const ShimmerSkeleton(width: 120, height: 18),
          const SizedBox(height: 14),
          // Product grid skeleton
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
            children: List.generate(4, (_) => const ProductCardSkeleton()),
          ),
        ],
      ),
    );
  }
}
