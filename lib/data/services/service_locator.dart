import 'package:all_at_task/data/repositories/auth_repository.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<AppRouter>(AppRouter());
  getIt.registerSingleton<AuthRepository>(AuthRepository()); // Регистрируем AuthRepository
  getIt.registerFactory<AuthBloc>(() => AuthBloc(authRepository: getIt<AuthRepository>())); // Передаем AuthRepository
  getIt.registerFactory<TaskBloc>(() => TaskBloc());
  getIt.registerFactory<ListBloc>(() => ListBloc());
  getIt.registerFactory<InvitationBloc>(() => InvitationBloc(
    currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
  ));
}