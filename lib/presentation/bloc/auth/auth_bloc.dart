import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'email': event.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Создаём список "Основной" для нового пользователя
        final listId = const Uuid().v4();
        await _firestore.collection('lists').doc(listId).set({
          'id': listId,
          'name': 'Основной',
          'ownerId': user.uid,
          'members': {user.uid: 'admin'},
          'createdAt': FieldValue.serverTimestamp(),
        });
        // После регистрации эмитим AuthSignUpSuccess вместо AuthSuccess
        emit(AuthSignUpSuccess());
      } else {
        emit(const AuthError('Ошибка регистрации: пользователь не создан'));
      }
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