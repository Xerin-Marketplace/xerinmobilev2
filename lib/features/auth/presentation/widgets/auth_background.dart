import 'package:flutter/material.dart';

/// A decorative background widget for auth pages.
/// Shows an image at the top that fades into the scaffold background
/// at the bottom, creating a smooth blended look.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  static const _imagePath = 'assets/images/retro-style-organic-turing-lines-pattern-background-design.png';

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        // Full-screen background image
        Positioned.fill(
          child: Opacity(
            opacity: 0.08,
            child: Image.asset(
              _imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay — fades from scaffold background at top to
        // transparent at bottom
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.3, 0.65, 1.0],
                colors: [
                  scaffoldBg.withValues(alpha: 0.0),
                  scaffoldBg.withValues(alpha: 0.1),
                  scaffoldBg.withValues(alpha: 0.7),
                  scaffoldBg.withValues(alpha: 1.0),
                ],
              ),
            ),
          ),
        ),
        // Content on top
        Positioned.fill(child: child),
      ],
    );
  }
}
