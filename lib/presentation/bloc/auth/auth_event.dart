part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String name;

  AuthSignUp({
    required this.email,
    required this.password,
    required this.username,
    required this.name,
  });
}

final class AuthSignIn extends AuthEvent {
  final String email;
  final String password;

  AuthSignIn({
    required this.email,
    required this.password,
  });
}

final class AuthSignOut extends AuthEvent {}

final class AuthCheck extends AuthEvent {}

final class AuthResetPassword extends AuthEvent {
  final String email;

  AuthResetPassword(this.email);
}