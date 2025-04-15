import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_event.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_state.dart';
import 'package:all_at_task/presentation/screens/auth/forgot_password_screen.dart';
import 'package:all_at_task/presentation/screens/auth/signup_screen.dart';
import 'package:all_at_task/presentation/screens/auth/home_screen.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';
import 'package:all_at_task/presentation/widgets/auth_header.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateAndLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? 'Введите email'
          : !_isValidEmail(email)
          ? 'Введите корректный email'
          : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
    });

    if (_emailError == null && _passwordError == null) {
      context.read<AuthBloc>().add(LogInRequested(email, password));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AuthHeader(subtitle: 'Добро пожаловать!'),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                labelText: 'Пароль',
                obscureText: true,
                errorText: _passwordError,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => getIt<AppRouter>().push(ForgotPasswordScreen()),
                  child: const Text('Забыли пароль?'),
                ),
              ),
              const SizedBox(height: 16),
              BlocConsumer<AuthBloc, AuthState>(
                listenWhen: (previous, current) =>
                current is AuthSuccess && !current.isSignUp || current is AuthFailure,
                listener: (context, state) {
                  if (state is AuthSuccess && !state.isSignUp) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Успешный вход!')),
                    );
                    context.read<AuthBloc>().add(ResetAuthState());
                    getIt<AppRouter>().pushReplacement(const HomeScreen());
                  } else if (state is AuthFailure) {
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                buildWhen: (previous, current) =>
                current is AuthLoading || current is AuthInitial,
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: _validateAndLogin,
                    child: const Text('Войти'),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => getIt<AppRouter>().push(const SignUpScreen()),
                child: const Text('Нет аккаунта? Зарегистрироваться'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}