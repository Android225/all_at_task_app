import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/screens/auth/home_screen.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/repositories/auth_repository.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:all_at_task/presentation/screens/auth/signup_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
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
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: MaterialApp(
        title: 'All At Task',
        navigatorKey: getIt<AppRouter>().navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}