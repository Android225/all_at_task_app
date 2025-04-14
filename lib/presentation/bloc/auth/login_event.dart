import 'package:meta/meta.dart';

@immutable
abstract class LoginEvent {}

class LogInRequested extends LoginEvent {
  final String email;
  final String password;

  LogInRequested(this.email, this.password);
}