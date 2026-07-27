import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  final double width;
  final double height;

  const AuthLogo({
    super.key,
    this.width = 180,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
