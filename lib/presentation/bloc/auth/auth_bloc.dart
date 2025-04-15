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
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      await userCredential.user?.updateDisplayName(event.name);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': event.name,
        'username': event.username,
        'email': event.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      emit(AuthSuccess(userCredential.user, isSignUp: true));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Ошибка регистрации'));
    } catch (e) {
      emit(AuthFailure('Произошла ошибка: $e'));
    }
  }

  Future<void> _onLogInRequested(LogInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(userCredential.user, isSignUp: false));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Ошибка входа'));
    } catch (e) {
      emit(AuthFailure('Произошла ошибка: $e'));
    }
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email);
      emit(ResetPasswordSuccess());
    } on FirebaseAuthException catch (e) {
      emit(ResetPasswordFailure(e.message ?? 'Ошибка при сбросе пароля'));
    } catch (e) {
      emit(ResetPasswordFailure('Произошла ошибка: $e'));
    }
  }

  void _onResetAuthState(ResetAuthState event, Emitter<AuthState> emit) {
    emit(AuthInitial());
  }
}