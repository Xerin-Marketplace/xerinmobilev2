import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/security/security_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../widgets/auth_logo.dart';

class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key});

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage>
    with SingleTickerProviderStateMixin {
  final SecurityService _security = GetIt.instance<SecurityService>();
  String _enteredPin = '';
  String? _firstPin;
  String? _errorText;
  bool _isConfirming = false;

  late final AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorText = null;
    });
  }

  void _onPinComplete() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (!_isConfirming) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _isConfirming = true;
        });
      } else {
        if (_enteredPin == _firstPin) {
          _security.setPin(_enteredPin).then((_) {
            if (!mounted) return;
            NotificationService().success('PIN set successfully!');
            context.pop();
          });
        } else {
          setState(() {
            _enteredPin = '';
            _firstPin = null;
            _isConfirming = false;
            _errorText = 'PINs do not match. Try again.';
          });
          _shakeCtrl.forward(from: 0);
        }
      }
    });
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  BackIconButton(
                    onTap: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
            const AuthLogo(width: 140, height: 80),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'Confirm PIN' : 'Set Up PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Re-enter your 4-digit PIN to confirm'
                  : 'Enter a 4-digit PIN to lock your app',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (context, child) {
                final offset = _shakeCtrl.value * 10 * (_shakeCtrl.value < 0.5 ? 1 : -1);
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
                      color: isFilled ? colorScheme.primary : Colors.transparent,
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
                        Icons.backspace_outlined,
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
