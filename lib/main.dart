import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:all_at_task/presentation/screens/home/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Очищаем сессию, чтобы всегда начинать с LoginScreen
  await FirebaseAuth.instance.signOut();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(AuthCheck()),
      child: MaterialApp(
        title: 'All At Task',
        navigatorKey: getIt<AppRouter>().navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2196F3),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            color: Color(0xFF2196F3),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
            ),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(fontSize: 16),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              return const HomeScreen();
            }
            // После успешной регистрации показываем LoginScreen :)
            if (state is AuthSignUpSuccess) {
              return const LoginScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}