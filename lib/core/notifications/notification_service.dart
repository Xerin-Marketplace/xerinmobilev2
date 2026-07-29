import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  OverlayEntry? _currentEntry;

  void show({
    required String message,
    NotificationType type = NotificationType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    _dismiss();

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        title: title,
        onTap: () {
          _dismiss();
          onTap?.call();
        },
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_currentEntry!);

    Future.delayed(duration, () {
      _dismiss();
    });
  }

  void success(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: NotificationType.success,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void error(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: NotificationType.error,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  void warning(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: NotificationType.warning,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void info(String message, {String? title, Duration? duration}) {
    show(
      message: message,
      type: NotificationType.info,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void _dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final String? title;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    required this.type,
    this.title,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    );
    _slideController.forward();
  }

  Future<void> _exit() async {
    if (_isExiting) return;
    _isExiting = true;
    await _slideController.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _getColors(widget.type);
    final icon = _getIcon(widget.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: GestureDetector(
              onTap: widget.onTap,
              onHorizontalDragEnd: (details) {
                if ((details.primaryVelocity?.abs() ?? 0) > 200) {
                  _exit();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors['border']!,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors['shadow']!,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors['bg'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: colors['icon'],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors['icon'],
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: widget.title != null
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _exit,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'icon': const Color(0xFF16A34A),
          'bg': const Color(0xFF16A34A).withValues(alpha: 0.1),
          'border': const Color(0xFF16A34A).withValues(alpha: 0.25),
          'shadow': const Color(0xFF16A34A).withValues(alpha: 0.15),
        };
      case NotificationType.error:
        return {
          'icon': const Color(0xFFDC2626),
          'bg': const Color(0xFFDC2626).withValues(alpha: 0.1),
          'border': const Color(0xFFDC2626).withValues(alpha: 0.25),
          'shadow': const Color(0xFFDC2626).withValues(alpha: 0.15),
        };
      case NotificationType.warning:
        return {
          'icon': const Color(0xFFF59E0B),
          'bg': const Color(0xFFF59E0B).withValues(alpha: 0.1),
          'border': const Color(0xFFF59E0B).withValues(alpha: 0.25),
          'shadow': const Color(0xFFF59E0B).withValues(alpha: 0.15),
        };
      case NotificationType.info:
        return {
          'icon': const Color(0xFF2563EB),
          'bg': const Color(0xFF2563EB).withValues(alpha: 0.1),
          'border': const Color(0xFF2563EB).withValues(alpha: 0.25),
          'shadow': const Color(0xFF2563EB).withValues(alpha: 0.15),
        };
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }
}
