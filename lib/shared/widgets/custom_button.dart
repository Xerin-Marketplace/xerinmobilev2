import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/app_constants.dart';

/// Reusable primary/secondary button with press animation.
class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isFullWidth;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSecondary = false,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = AppConstants.buttonHeight,
    this.borderRadius = 8,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.isLoading || widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor =
        widget.isSecondary ? colorScheme.primary : colorScheme.onPrimary;

    final child = widget.isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          )
        : Text(
            widget.label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          );

    final buttonStyle = widget.isSecondary
        ? OutlinedButton.styleFrom(
            minimumSize: widget.isFullWidth
                ? Size(double.infinity, widget.height)
                : Size(0, widget.height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            side: BorderSide(color: colorScheme.primary, width: 1.5),
          )
        : ElevatedButton.styleFrom(
            minimumSize: widget.isFullWidth
                ? Size(double.infinity, widget.height)
                : Size(0, widget.height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 2,
            shadowColor: colorScheme.primary.withValues(alpha: 0.35),
          );

    final button = widget.isSecondary
        ? OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: buttonStyle,
            child: child,
          );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.translucent,
        child: button,
      ),
    );
  }
}
