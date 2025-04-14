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
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Регистрация пользователя
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // Обновление имени в профиле Firebase Authentication
        await userCredential.user?.updateDisplayName(event.name);

        // Запись данных пользователя в Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'name': event.name,
          'username': event.username,
          'email': event.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        emit(AuthSuccess(userCredential.user));
      } on FirebaseAuthException catch (e) {
        emit(AuthFailure(e.message ?? 'Ошибка регистрации'));
      } catch (e) {
        emit(AuthFailure('Произошла ошибка: $e'));
      }
    });

    on<LogInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(AuthSuccess(userCredential.user));
      } on FirebaseAuthException catch (e) {
        emit(AuthFailure(e.message ?? 'Ошибка входа'));
      } catch (e) {
        emit(AuthFailure('Произошла ошибка: $e'));
      }
    });
  }
}