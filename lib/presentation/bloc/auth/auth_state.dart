part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  final User user;

  AuthSuccess(this.user);
}

final class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}

final class AuthResetPasswordSuccess extends AuthState {}

final class AuthResetPasswordFailure extends AuthState {
  final String message;

  AuthResetPasswordFailure(this.message);
}