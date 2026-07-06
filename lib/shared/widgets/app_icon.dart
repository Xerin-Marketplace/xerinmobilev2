import 'package:flutter/material.dart';

/// Standard icon sizes used across the app.
abstract class AppIconSize {
  static const double xs = 14;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 48;
  static const double display = 72;
}

/// Standard icon container — a rounded box with a tinted background
/// that wraps an icon. Used for back buttons, list-tile icons, etc.
class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;
  final Color? backgroundColor;

  const IconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = AppIconSize.lg,
    this.borderRadius = 12,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Tappable back button with consistent styling.
class BackIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const BackIconButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap ?? () => Navigator.maybePop(context),
      behavior: HitTestBehavior.opaque,
      child: IconContainer(
        icon: Icons.arrow_back_rounded,
        color: c,
        iconSize: AppIconSize.lg,
        borderRadius: 12,
      ),
    );
  }
}

/// Standard trailing chevron used in list tiles.
class TrailingChevron extends StatelessWidget {
  final Color? color;

  const TrailingChevron({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: AppIconSize.xs,
      color: color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
    );
  }
}

/// Empty-state icon — large, muted, centred.
class EmptyStateIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const EmptyStateIcon({
    super.key,
    required this.icon,
    this.size = AppIconSize.display,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
    );
  }
}
