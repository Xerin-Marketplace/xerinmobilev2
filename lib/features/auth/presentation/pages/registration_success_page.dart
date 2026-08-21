import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../widgets/auth_text_field.dart' show AuthPrimaryButton;

class RegistrationSuccessPage extends StatefulWidget {
  const RegistrationSuccessPage({super.key});

  @override
  State<RegistrationSuccessPage> createState() => _RegistrationSuccessPageState();
}

class _RegistrationSuccessPageState extends State<RegistrationSuccessPage>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _particleCtrl;
  late final Animation<double> _particleAnim;
  late final AnimationController _contentCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkAnim = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.easeOutCubic,
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl,
      curve: Curves.easeInOut,
    );

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _particleAnim = CurvedAnimation(
      parent: _particleCtrl,
      curve: Curves.easeInOut,
    );

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );

    _checkCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _contentCtrl.forward();
        setState(() => _showContent = true);
      }
    });

    _checkCtrl.forward();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Particle effects
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (context, child) => CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  animation: _particleAnim.value,
                  color: colorScheme.primary,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark circle
                  _buildCheckCircle(colorScheme),
                  const SizedBox(height: 48),
                  // Content (slides in after check)
                  if (_showContent)
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: ScaleTransition(
                          scale: _scaleAnim,
                          child: _buildContent(colorScheme),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckCircle(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => context.go(AppConstants.homeRoute),
      child: AnimatedBuilder(
        animation: _checkAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  final scale = 1.0 + _pulseAnim.value * 0.08;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(
                          alpha: 0.06 + _pulseAnim.value * 0.04,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Main circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _CheckmarkPainter(
                    progress: _checkAnim.value,
                    color: Colors.white,
                    strokeWidth: 5,
                  ),
                ),
              ),
              // Inner glow
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your account is ready. Let's start shopping!\nWelcome to XerinMarket.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          AuthPrimaryButton(
            label: 'Start Shopping',
            onPressed: () {
              context.go(AppConstants.homeRoute);
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              NotificationService().info(
                'Welcome to XerinMarket! Happy shopping.',
              );
            },
            child: Text(
              'Show Welcome Message',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Draw circle
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, circlePaint);

    // Draw checkmark
    final path = Path();
    final startX = center.dx - radius * 0.4;
    final startY = center.dy;
    final midX = center.dx - radius * 0.1;
    final midY = center.dy + radius * 0.35;
    final endX = center.dx + radius * 0.45;
    final endY = center.dy - radius * 0.3;

    path.moveTo(startX, startY);
    path.lineTo(midX, midY);
    path.lineTo(endX, endY);

    final metrics = path.computeMetrics();
    final totalLength = metrics.fold(0.0, (sum, m) => sum + m.length);

    final extractPath = Path();
    for (final metric in metrics) {
      final extracted = metric.extractPath(
        0,
        totalLength * progress,
      );
      extractPath.addPath(extracted, Offset.zero);
    }

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiPainter extends CustomPainter {
  final double animation;
  final Color color;

  _ConfettiPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final seed = i * 100;
      final rand = Random(seed);
      final x = size.width * rand.nextDouble();
      final yBase = size.height * (0.15 + rand.nextDouble() * 0.7);
      final yOffset = sin(animation * 2 * pi * 2 + i * 0.5) * 20;
      final y = yBase + yOffset * animation;

      final colors = [
        color,
        const Color(0xFF22C55E),
        const Color(0xFF3B82F6),
        const Color(0xFFF59E0B),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
      ];
      paint.color = colors[i % colors.length].withValues(
        alpha: (0.4 + sin(animation * pi * 2 + i) * 0.2).clamp(0.1, 0.6),
      );

      final width = 4.0 + rand.nextDouble() * 6;
      final height = 4.0 + rand.nextDouble() * 6;
      final rotation = animation * 2 * pi + i;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
