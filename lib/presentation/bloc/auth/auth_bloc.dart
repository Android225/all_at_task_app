import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/task_list.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<AuthSignUp>(_onSignUp);
    on<AuthSignIn>(_onSignIn);
    on<AuthSignOut>(_onSignOut);
    on<AuthCheck>(_onCheckAuth);
    on<AuthResetPassword>(_onResetPassword);
  }

  Future<void> _onSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final user = userCredential.user;
      if (user == null) {
        emit(AuthFailure('Регистрация не удалась: пользователь не создан'));
        return;
      }

      await _firestore.collection('users').doc(user.uid).set({
        'email': event.email,
        'username': event.username,
        'name': event.name,
      }).catchError((e) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'write-failed',
          message: 'Ошибка при сохранении данных пользователя: $e',
        );
      });

      final defaultList = TaskList(
        id: const Uuid().v4(),
        name: 'Основной',
        ownerId: user.uid,
      );
      await _firestore.collection('lists').doc(defaultList.id).set(defaultList.toMap()).catchError((e) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'write-failed',
          message: 'Ошибка при создании списка: $e',
        );
      });

      emit(AuthSuccess(user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        emit(AuthFailure('Этот email уже используется'));
      } else {
        emit(AuthFailure('Не удалось зарегистрироваться: ${e.message}'));
      }
    } on FirebaseException catch (e) {
      emit(AuthFailure(e.message ?? 'Ошибка базы данных'));
    } catch (e) {
      emit(AuthFailure('Не удалось зарегистрироваться: $e'));
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
        emit(AuthFailure('Вход не удался: пользователь не найден'));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        emit(AuthFailure('Неверный email или пароль'));
      } else {
        emit(AuthFailure('Не удалось войти: ${e.message}'));
      }
    } catch (e) {
      emit(AuthFailure('Не удалось войти: $e'));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    try {
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure('Не удалось выйти: $e'));
    }
  }

  Future<void> _onCheckAuth(AuthCheck event, Emitter<AuthState> emit) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthSuccess(user));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onResetPassword(AuthResetPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email);
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      emit(AuthFailure('Не удалось отправить письмо: $e'));
    }
  }
}