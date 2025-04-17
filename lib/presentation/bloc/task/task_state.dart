part of 'task_bloc.dart';


@immutable
abstract class TaskState {
  const TaskState();
}

final class TaskInitial extends TaskState {}

final class TaskLoading extends TaskState {}

final class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final String userId;

  TaskLoaded(this.tasks, this.userId);
}

final class TaskError extends TaskState {
  final String message;

  TaskError(this.message);
}