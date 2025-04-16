import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';
import 'package:all_at_task/presentation/widgets/auth_header.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateAndSignUp() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'Введите имя' : null;
      _usernameError = username.isEmpty ? 'Введите имя пользователя' : null;
      _emailError = email.isEmpty
          ? 'Введите email'
          : !_isValidEmail(email)
          ? 'Введите корректный email'
          : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
    });

    if (_nameError == null && _usernameError == null && _emailError == null && _passwordError == null) {
      context.read<AuthBloc>().add(AuthSignUp(
        email: email,
        password: password,
        username: username,
        name: name,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => getIt<AppRouter>().pop(),
                  ),
                ],
              ),
              const AuthHeader(subtitle: 'Давайте создадим аккаунт'),
              AppTextField(
                controller: _nameController,
                labelText: 'Name',
                errorText: _nameError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _usernameController,
                labelText: 'Username',
                errorText: _usernameError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: _obscurePassword,
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 24),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Успешная регистрация!')),
                    );
                    getIt<AppRouter>().pushReplacement(const LoginScreen());
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: _validateAndSignUp,
                    child: const Text('Зарегистрироваться'),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('У вас уже есть аккаунт? '),
                  TextButton(
                    onPressed: () => getIt<AppRouter>().push(const LoginScreen()),
                    child: const Text('Войти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}