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
  final String priority;
  final String ownerId;
  final String assignedTo;
  final bool isCompleted;
  final bool isFavorite;

  AddTask({
    required this.title,
    this.description,
    this.deadline,
    required this.listId,
    required this.priority,
    required this.ownerId,
    required this.assignedTo,
    required this.isCompleted,
    required this.isFavorite,
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