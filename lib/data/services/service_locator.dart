import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:all_at_task/router/app_router.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerSingleton<AppRouter>(AppRouter());
  getIt.registerFactory<AuthBloc>(() => AuthBloc());
  getIt.registerFactory<TaskBloc>(() => TaskBloc());
  getIt.registerFactory<ListBloc>(() => ListBloc());
  getIt.registerFactory<InvitationBloc>(() => InvitationBloc());
}