import 'package:flutter/material.dart';
import 'package:all_at_task/config/theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String subtitle;

  const AuthHeader({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'all-at_task',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Image.asset('assets/images/cat1.jpg', height: 200),
        const SizedBox(height: 32),
      ],
    );
  }
}