import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        suffixIcon: suffixIcon,
        border: Theme.of(context).inputDecorationTheme.border,
        contentPadding: Theme.of(context).inputDecorationTheme.contentPadding,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}