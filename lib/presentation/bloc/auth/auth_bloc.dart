import 'package:all_at_task/data/repositories/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository _authRepository; // Добавляем AuthRepository

  AuthBloc({AuthRepository? authRepository}) // В конструкторе принимаем AuthRepository
      : _authRepository = authRepository ?? AuthRepository(),
        super(AuthInitial()) {
    on<AuthCheck>(_onCheckAuth);
    on<AuthSignIn>(_onSignIn);
    on<AuthSignUp>(_onSignUp);
    on<AuthSignOut>(_onSignOut);
    on<AuthResetPassword>(_onResetPassword);
  }

  Future<void> _onCheckAuth(AuthCheck event, Emitter<AuthState> emit) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final user = userCredential.user;
      if (user != null) {
        emit(AuthSuccess(user));
      } else {
        emit(const AuthError('Ошибка входа: пользователь не найден'));
      }
    } catch (e) {
      emit(AuthError('Ошибка входа: $e'));
    }
  }

  Future<void> _onSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Вызываем AuthRepository.signUp вместо дублирования логики
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        username: event.username,
        name: event.name,
      );
      emit(AuthSignUpSuccess());
    } catch (e) {
      emit(AuthError('Ошибка регистрации: $e'));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(AuthInitial());
  }

  Future<void> _onResetPassword(AuthResetPassword event, Emitter<AuthState> emit) async {
    try {
      await _auth.sendPasswordResetEmail(email: event.email);
      emit(const AuthMessage('Письмо для сброса пароля отправлено'));
    } catch (e) {
      emit(AuthError('Ошибка сброса пароля: $e'));
    }
  }
}