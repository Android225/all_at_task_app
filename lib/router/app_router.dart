import 'package:all_at_task/presentation/screens/auth/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:all_at_task/presentation/screens/auth/signup_screen.dart';

class AppRouter {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => navigatorKey.currentState!;

  void pop<T>([T? result]) {
    return _navigator.pop(result);
  }

  Future<T?> push<T>(Widget page) {
    return _navigator.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushReplacement<T>(Widget page) {
    return _navigator.pushReplacement<T, dynamic>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushAndRemoveUntil<T>(Widget page) {
    return _navigator.pushAndRemoveUntil<T>(
      MaterialPageRoute(builder: (_) => page),
          (route) => false,
    );
  }

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return _navigator.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen()); // Экран по умолчанию
    }
  }
}