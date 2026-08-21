import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/theme/uicons.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage>
    with SingleTickerProviderStateMixin {
  final SecurityService _security = GetIt.instance<SecurityService>();
  String _enteredPin = '';
  String? _errorText;
  int _attempts = 0;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onKeyTap(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _errorText = null;
    });
    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  void _verifyPin() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_security.verifyPin(_enteredPin)) {
        NotificationService().success('Welcome back!');
        context.go(AppConstants.homeRoute);
      } else {
        _attempts++;
        setState(() {
          _enteredPin = '';
          _errorText = 'Incorrect PIN. Try again.';
        });
        _shakeCtrl.forward(from: 0);
        if (_attempts >= 5) {
          _showTooManyAttemptsDialog();
        }
      }
    });
  }

  void _showTooManyAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Too Many Attempts'),
        content: const Text(
          'You have entered an incorrect PIN 5 times. Please sign in again.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppConstants.signInRoute);
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Uicons.lock,
                color: colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 4-digit PIN to unlock',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset = _shakeAnim.value * 10 * (_shakeAnim.value < 0.5 ? 1 : -1);
                return Transform.translate(
                  offset: Offset(offset.toDouble(), 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (_errorText != null)
              Text(
                _errorText!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Spacer(flex: 1),
            _buildKeypad(colorScheme, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(ColorScheme colorScheme, bool isDark) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return SizedBox(
      width: 280,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key.isEmpty) return const SizedBox();

          final isBackspace = key == '⌫';

          return GestureDetector(
            onTap: isBackspace ? _onBackspace : () => _onKeyTap(key),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? colorScheme.onSurface.withValues(alpha: 0.05)
                    : colorScheme.surface,
                border: Border.all(
                  color: colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: isBackspace
                    ? Icon(
                        Uicons.backspace,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 24,
                      )
                    : Text(
                        key,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
