part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {
  final String listId;

  const LoadTasks(this.listId);

  @override
  List<Object?> get props => [listId];
}

class AddTask extends TaskEvent {
  final String title;
  final String? description;
  final Timestamp? deadline;
  final String listId;
  final String? priority;
  final String ownerId;
  final String assignedTo;
  final bool isCompleted;
  final bool isFavorite;

  const AddTask({
    required this.title,
    this.description,
    this.deadline,
    required this.listId,
    this.priority,
    required this.ownerId,
    required this.assignedTo,
    required this.isCompleted,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    deadline,
    listId,
    priority,
    ownerId,
    assignedTo,
    isCompleted,
    isFavorite,
  ];
}

class UpdateTask extends TaskEvent {
  final Task task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TaskEvent {
  final String taskId;
  final String listId;

  const DeleteTask(this.taskId, this.listId);

  @override
  List<Object?> get props => [taskId, listId];
}