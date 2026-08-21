import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../config/constants/app_constants.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart' show AuthPrimaryButton;
import '../../../../core/theme/uicons.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phone;
  final bool fromLogin;

  const VerifyOtpPage({
    super.key,
    required this.phone,
    this.fromLogin = false,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpCtls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _autoFilledCode = '';

  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _focusNodes[0].requestFocus();
    _startCountdown();
    _listenForSmsCode();
  }

  Future<void> _listenForSmsCode() async {
    try {
      await SmsAutoFill().listenForCode;
      SmsAutoFill().code.listen((code) {
        if (code.length == 6 && mounted) {
          _autoFilledCode = code;
          for (int i = 0; i < 6; i++) {
            _otpCtls[i].text = code[i];
          }
          setState(() {});
          _autoVerify();
        }
      });
    } catch (_) {}
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SmsAutoFill().unregisterListener();
    for (final c in _otpCtls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _animCtrl.dispose();
    super.dispose();
  }

  void _onOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    _checkAutoVerify();
  }

  void _checkAutoVerify() {
    final otp = _otpCtls.map((c) => c.text).join();
    if (otp.length == 6 && !otp.contains(' ')) {
      _autoVerify();
    }
  }

  void _autoVerify() {
    final otp = _otpCtls.map((c) => c.text).join();
    if (otp.length == 6) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().verifyOtp(
            phone: widget.phone,
            otpCode: otp,
          );
    }
  }

  void _onVerify() {
    final otp = _otpCtls.map((c) => c.text).join();
    if (otp.length == 6) {
      context.read<AuthCubit>().verifyOtp(
            phone: widget.phone,
            otpCode: otp,
          );
    } else {
      NotificationService().warning('Please enter the 6-digit OTP code');
    }
  }

  void _pasteOtp(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpCtls[i].text = digits[i];
      }
      setState(() {});
      _checkAutoVerify();
    }
  }

  void _onResend() {
    if (_secondsLeft > 0) return;
    context.read<AuthCubit>().sendOtp(phone: widget.phone);
  }

  void _onStateChange(BuildContext context, AuthState state) {
    if (state is AuthOtpVerified) {
      NotificationService().success('Phone verified successfully!');
      if (widget.fromLogin) {
        NotificationService().info('Account verified! Please sign in again.');
        context.go(AppConstants.signInRoute);
      } else {
        context.go(AppConstants.homeRoute);
      }
    } else if (state is AuthOtpSent) {
      _startCountdown();
      NotificationService().info('OTP resent to ${state.phone}');
    } else if (state is AuthError) {
      NotificationService().error(state.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: _onStateChange,
      child: Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SingleChildScrollView(
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return Column(
                  children: [
                    const SizedBox(height: 16),
                  BackIconButton(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppConstants.registerRoute);
                      }
                    },
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  const AuthLogo(width: 180, height: 110),
                  const SizedBox(height: 28),
                  Text(
                    'Verify your number',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We sent a 6-digit code to ${widget.phone}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 44),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFocused = _focusNodes[index].hasFocus;
                      final hasValue = _otpCtls[index].text.isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 60,
                          decoration: BoxDecoration(
                            color: hasValue
                                ? colorScheme.primary.withValues(alpha: 0.06)
                                : (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFocused
                                  ? colorScheme.primary
                                  : hasValue
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.3)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.08),
                              width: isFocused ? 2 : 1.5,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: TextFormField(
                            controller: _otpCtls[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: hasValue
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              letterSpacing: 0,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            onChanged: (v) => _onOtpChange(index, v),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_autoFilledCode.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Uicons.autoAwesome, size: 14, color: colorScheme.primary.withValues(alpha: 0.6)),
                          const SizedBox(width: 6),
                          Text(
                            'Code detected from SMS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  GestureDetector(
                    onTap: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _pasteOtp(data!.text!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Uicons.paste, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 6),
                          Text(
                            'Paste code',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthPrimaryButton(
                    label: 'Verify & Continue',
                    onPressed: isLoading ? null : _onVerify,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: _secondsLeft == 0 ? _onResend : null,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _secondsLeft == 0
                                ? colorScheme.primary
                                : colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _secondsLeft > 0
                          ? '00:${_secondsLeft.toString().padLeft(2, '0')}'
                          : 'Ready to resend',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
