import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_state.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_event.dart';
import 'package:all_at_task/config/theme/app_theme.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'all-at_task',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Восстановление пароля',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Image.asset('assets/images/cat1.jpg', height: 200),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите email, и мы отправим вам письмо для восстановления пароля.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is ResetPasswordSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Письмо для сброса пароля отправлено!')),
                    );
                    getIt<AppRouter>().pop();
                  } else if (state is ResetPasswordFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text.trim();

                      if (email.isNotEmpty) {
                        context.read<AuthBloc>().add(ResetPasswordRequested(email));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Введите email')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Отправить письмо'),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => getIt<AppRouter>().pop(),
                child: const Text('Вернуться к входу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}