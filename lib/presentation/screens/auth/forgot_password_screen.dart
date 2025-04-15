import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_event.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_state.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';
import 'package:all_at_task/presentation/widgets/auth_header.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AuthHeader(subtitle: 'Восстановление пароля'),
              AppTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите email, и мы отправим вам письмо для восстановления пароля.',
                style: Theme.of(context).textTheme.labelMedium,
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
                      context.read<AuthBloc>().add(ResetPasswordRequested(
                        _emailController.text.trim(),
                      ));
                    },
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