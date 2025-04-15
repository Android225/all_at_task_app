part of 'task_bloc.dart';

@immutable
abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final String userId;

  TaskLoaded(this.tasks, this.userId);
}

class TaskError extends TaskState {
  final String message;

  TaskError(this.message);
}