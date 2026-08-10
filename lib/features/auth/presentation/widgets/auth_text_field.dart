import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int? maxLines;
  final void Function(String)? onChanged;
  final Widget? prefix;
  final BoxConstraints? prefixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;

  const AuthTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    this.icon = Icons.text_fields,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.onChanged,
    this.prefix,
    this.prefixIconConstraints,
    this.contentPadding,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _isFocused
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          obscureText: widget.obscureText,
          validator: widget.validator,
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            filled: true,
            fillColor: _isFocused
                ? colorScheme.primary.withValues(alpha: 0.03)
                : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA)),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: widget.prefix ??
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.35),
                ),
            prefixIconConstraints: widget.prefixIconConstraints,
            suffixIcon: widget.suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: widget.suffix,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1.5,
              ),
            ),
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            errorStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFDC2626).withValues(alpha: 0.12)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : const Color(0xFFFCA5A5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFDC2626), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
