import 'package:meta/meta.dart';

@immutable
abstract class AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String name;
  final String username;
  final String email;
  final String password;

  SignUpRequested(this.name, this.username, this.email, this.password);
}

class LogInRequested extends AuthEvent {
  final String email;
  final String password;

  LogInRequested(this.email, this.password);
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  ResetPasswordRequested(this.email);
}
class ResetAuthState extends AuthEvent {}