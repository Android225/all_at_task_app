import 'package:all_at_task/presentation/screens/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:all_at_task/config/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    setState(() {
      _emailError = _emailController.text.isEmpty ? 'Введите данные в поле' : null;
      _passwordError = _passwordController.text.isEmpty ? 'Введите данные в поле' : null;
    });

    if (_emailError == null && _passwordError == null) {
      final email = _emailController.text;
      final password = _passwordController.text;
      print('Email: $email, Password: $password');
      // TODO: Реализация входа
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'all-at_task',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Добро пожаловать!',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // 👉 Вот здесь картинка
              Image.asset(
                'assets/images/cat1.jpg',
                height: 200,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              // Уменьшил отступ до "Забыли пароль?"
              const SizedBox(height: 8),
              // Текст "Забыли пароль?" перед кнопкой
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Реализовать переход на экран восстановления пароля
                    // TODO: Переход к экрану восстановления пароля
                  },
                  child: Text(
                    'Забыли пароль?',
                    style: TextStyle(
                      color: theme.colorScheme.primary, // Используем цвет из схемы приложения
                    ),
                  ),
                ),
              ),
              // Уменьшил отступ между "Забыли пароль?" и кнопкой "Войти"
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48), // Размер кнопки (ширина 100%, высота 48)
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  backgroundColor: theme.primaryColor, // Цвет фона кнопки
                  foregroundColor: Colors.white, // Цвет текста кнопки
                ),
                child: const Text('Войти'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
