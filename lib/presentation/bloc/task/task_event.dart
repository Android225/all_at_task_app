part of 'task_bloc.dart';

@immutable
sealed class TaskEvent {}

final class LoadTasks extends TaskEvent {
  final String listId;
  LoadTasks(this.listId);
}

final class AddTask extends TaskEvent {
  final String title;
  final String? description;
  final Timestamp? deadline;
  final String listId;
  final String? priority;

  AddTask({
    required this.title,
    this.description,
    this.deadline,
    required this.listId,
    this.priority,
  });
}

final class UpdateTask extends TaskEvent {
  final Task task;
  UpdateTask(this.task);
}

final class DeleteTask extends TaskEvent {
  final String taskId;
  final String listId;
  DeleteTask(this.taskId, this.listId);
}