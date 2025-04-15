part of 'task_bloc.dart';

@immutable
abstract class TaskEvent {}

class LoadTasks extends TaskEvent {
  final String listId;

  LoadTasks(this.listId);
}

class AddTask extends TaskEvent {
  final String title;
  final String? description;
  final DateTime? deadline;
  final String listId;

  AddTask(this.title, this.description, this.deadline, this.listId);
}

class UpdateTask extends TaskEvent {
  final Task task;

  UpdateTask(this.task);
}

class DeleteTask extends TaskEvent {
  final String taskId;
  final String listId;

  DeleteTask(this.taskId, this.listId);
}