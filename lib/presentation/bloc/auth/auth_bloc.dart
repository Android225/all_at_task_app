import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/task_list.dart';

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
        // Обновляем displayName в FirebaseAuth
        await user.updateDisplayName(event.name);

        // Сохраняем данные пользователя в Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'email': event.email,
          'name': event.name,
          'username': event.username,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Создаем список "Основной"
        final listId = const Uuid().v4();
        final mainList = TaskList(
          id: listId,
          name: 'Основной',
          ownerId: user.uid,
          createdAt: DateTime.now(),
          members: {user.uid: 'owner'},
          sharedLists: [],
          description: null,
          color: null,
          lastUsed: null,
        );
        await _firestore.collection('lists').doc(listId).set(mainList.toMap());

        // Добавляем список в users/{uid}/lists
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .doc(listId)
            .set({
          'listId': listId,
          'addedAt': FieldValue.serverTimestamp(),
        });

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