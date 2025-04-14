import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/repositories/auth_repository.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Убедитесь, что все инициализируется
  await setupServiceLocator();  // Регистрация всех зависимостей
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);  // Инициализация Firebase

  // Инициализация репозитория аутентификации
  final authRepository = AuthRepository();

  // Запуск приложения с переданным репозиторием
  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({Key? key, required this.authRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository),
      child: MaterialApp(
        title: 'All At Task',
        navigatorKey: getIt<AppRouter>().navigatorKey,  // Используем AppRouter из GetIt
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,  // Тема приложения
        home: const LoginScreen(),  // Экран логина по умолчанию
      ),
    );
  }
}
