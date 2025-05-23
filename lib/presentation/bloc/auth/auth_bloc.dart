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
      print('Ошибка входа: $e');
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
        await user.updateDisplayName(event.name);
        await _firestore.collection('users').doc(user.uid).set({
          'name': event.name,
          'username': event.username,
          'email': event.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        final lists = [
          {'name': 'Основной', 'id': const Uuid().v4()},
          {'name': 'Работа', 'id': const Uuid().v4()},
          {'name': 'Личное', 'id': const Uuid().v4()},
          {'name': 'Покупки', 'id': const Uuid().v4()},
        ];
        for (var list in lists) {
          try {
            await _firestore.collection('lists').doc(list['id']).set({
              'id': list['id'],
              'name': list['name'],
              'ownerId': user.uid,
              'members': {user.uid: 'admin'},
              'createdAt': FieldValue.serverTimestamp(),
              'linkedLists': [],
              'sharedLists': [],
              'color': '0xFF2196F3',
            });
            print('Список создан: ${list['name']} с ID: ${list['id']}');
          } catch (e) {
            print('Ошибка создания списка ${list['name']}: $e');
            emit(AuthError('Ошибка создания списка: $e'));
            return;
          }
        }
        emit(AuthSignUpSuccess());
      } else {
        emit(const AuthError('Ошибка регистрации: пользователь не создан'));
      }
    } catch (e) {
      print('Ошибка регистрации: $e');
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
      print('Ошибка сброса пароля: $e');
      emit(AuthError('Ошибка сброса пароля: $e'));
    }
  }
}