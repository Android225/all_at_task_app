import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';


@immutable
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User? user;
  final bool isSignUp;

  AuthSuccess(this.user, {this.isSignUp = false});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}

class ResetPasswordSuccess extends AuthState {}

class ResetPasswordFailure extends AuthState {
  final String message;

  ResetPasswordFailure(this.message);
}