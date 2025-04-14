import 'package:all_at_task/presentation/bloc/auth/login_event.dart';
import 'package:all_at_task/presentation/bloc/auth/login_state.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';


class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LoginBloc() : super(LoginInitial()) {
    on<LogInRequested>((event, emit) async {
      emit(LoginLoading());

      try {
        final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        if (userCredential.user != null) {
          emit(LoginSuccess(user: userCredential.user!));
        }
      } on FirebaseAuthException catch (e) {
        emit(LoginFailure(error: e.message ?? 'Неизвестная ошибка'));
      } catch (e) {
        emit(LoginFailure(error: 'Произошла ошибка: $e'));
      }
    });
  }
}