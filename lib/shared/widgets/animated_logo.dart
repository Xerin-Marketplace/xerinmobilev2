import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated logo that fades in, scales up with a gentle bounce,
/// and shows a subtle shimmer sweep across the SVG.
class AnimatedLogo extends StatefulWidget {
  final double width;
  final double height;
  final Duration duration;
  final bool showShimmer;

  const AnimatedLogo({
    super.key,
    this.width = 260,
    this.height = 180,
    this.duration = const Duration(milliseconds: 1400),
    this.showShimmer = true,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _shimmerController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );

    // Bounce curve: overshoot then settle
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    _scaleController.forward().whenComplete(() {
      if (widget.showShimmer && mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: _buildLogoWithShimmer(),
    );
  }

  Widget _buildLogoWithShimmer() {
    if (!widget.showShimmer) {
      return SvgPicture.asset(
        'assets/logo/full_named_logo.svg',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          SvgPicture.asset(
            'assets/logo/full_named_logo.svg',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
          Positioned.fill(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, _) {
                  final value = _shimmerController.value;
                  // Shimmer sweeps left to right
                  final dx = -widget.width + (value * widget.width * 2);

                  return CustomPaint(
                    painter: _ShimmerPainter(dx),
                    size: Size(widget.width, widget.height),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double dx;

  _ShimmerPainter(this.dx);

  @override
  void paint(Canvas canvas, Size size) {
    final shimmerWidth = size.width * 0.35;
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.35),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(dx, 0, shimmerWidth, size.height));

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(dx, 0, shimmerWidth, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) {
    return oldDelegate.dx != dx;
  }
}
