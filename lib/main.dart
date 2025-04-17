import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:all_at_task/presentation/blocs/list_bloc/list_bloc.dart';
import 'package:all_at_task/presentation/screens/home/home_screen.dart';
import 'package:all_at_task/presentation/screens/login/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // Use 'playIntegrity' for production
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthCheckEvent()),
        ),
        BlocProvider<ListBloc>(
          create: (context) => ListBloc()..add(LoadListEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'All At Task',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}