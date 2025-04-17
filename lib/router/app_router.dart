import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:all_at_task/presentation/screens/friends/friends_screen.dart';
import 'package:all_at_task/presentation/screens/home/home_screen.dart';
import 'package:all_at_task/presentation/screens/invitations/invitations_screen.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:all_at_task/presentation/screens/listss/listhome_screen.dart';
import 'package:all_at_task/presentation/screens/listss/lists_screen.dart';
import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:all_at_task/presentation/screens/profile/profile_screen.dart';
import 'package:all_at_task/presentation/screens/auth/forgot_password_screen.dart';
import 'package:all_at_task/presentation/screens/auth/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  final navigatorKey = GlobalKey<NavigatorState>();

  Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
        final listId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<TaskBloc>()),
              BlocProvider(
                create: (_) => getIt<ListBloc>()
                  ..add(LoadLists(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '')),
              ),
            ],
            child: const HomeScreen(),
          ),
          settings: settings,
        );
      case '/lists_home':
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ListBloc>()..add(LoadLists(userId: userId)),
            child: ListHomeScreen(userId: userId),
          ),
        );
      case '/lists':
        return MaterialPageRoute(builder: (_) => const ListsScreen());
      case '/list_edit':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ListBloc>(),
            child: ListEditScreen(
              list: args?['list'],
            ),
          ),
        );
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/friends':
        return MaterialPageRoute(builder: (_) => const FriendsScreen());
      case '/invitations':
        return MaterialPageRoute(builder: (_) => const InvitationsScreen());
      case '/forgot_password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  Future<T?> push<T>(Widget screen) {
    return navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<T?> pushReplacement<T, TO>(Widget screen) {
    return navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void pop<T>([T? result]) {
    navigatorKey.currentState!.pop(result);
  }
}