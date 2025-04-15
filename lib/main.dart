import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/repositories/auth_repository.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator(); // Убрали await, так как функция синхронная
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Инициализация Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  final authRepository = AuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({Key? key, required this.authRepository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return BlocProvider(
      create: (_) => AuthBloc(),
      child: MaterialApp(
        title: 'All At Task',
        navigatorKey: appRouter.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        onGenerateRoute: appRouter.onGenerateRoute,
      ),
    );
  }
}