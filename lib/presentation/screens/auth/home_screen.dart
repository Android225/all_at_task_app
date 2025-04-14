import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Center(
        child: Text(
          'Добро пожаловать!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
