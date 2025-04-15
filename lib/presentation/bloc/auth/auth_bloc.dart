import 'package:all_at_task/presentation/bloc/auth/auth_event.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_state.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<LogInRequested>(_onLogInRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<ResetAuthState>(_onResetAuthState);
    on<LogOutRequested>(_onLogOutRequested);
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Проверяем входные данные
      if (event.email.isEmpty || event.password.isEmpty || event.name.isEmpty || event.username.isEmpty) {
        emit(AuthFailure('Заполните все поля'));
        return;
      }

      // Создаём пользователя
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Не удалось получить ID пользователя');
      }

      // Обновляем displayName
      await userCredential.user?.updateDisplayName(event.name);

      // Сохраняем данные пользователя
      await _firestore.collection('users').doc(userId).set({
        'name': event.name,
        'username': event.username,
        'email': event.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Создаём список "Основной"
      try {
        final parentListId = _firestore.collection('lists').doc().id;
        await _firestore.collection('lists').doc(parentListId).set({
          'id': parentListId,
          'name': 'Основной',
          'ownerId': userId,
          'participants': [],
          'roles': [],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Откат: удаляем пользователя
        await _auth.currentUser?.delete();
        emit(AuthFailure('Не удалось создать список: $e'));
        return;
      }

      emit(AuthSuccess(userCredential.user, isSignUp: true));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Ошибка регистрации'));
    } catch (e) {
      emit(AuthFailure('Ошибка: $e'));
    }
  }

  Future<void> _onLogInRequested(LogInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(userCredential.user, isSignUp: false));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Ошибка входа'));
    } catch (e) {
      emit(AuthFailure('Ошибка: $e'));
    }
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email);
      emit(ResetPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      emit(ResetPasswordFailure(e.message ?? 'Ошибка сброса пароля'));
    } catch (e) {
      emit(ResetPasswordFailure('Ошибка: $e'));
    }
  }

  void _onResetAuthState(ResetAuthState event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }

  Future<void> _onLogOutRequested(LogOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure('Ошибка выхода: $e'));
    }
  }
}