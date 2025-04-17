import 'package:equatable/equatable.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';

abstract class ListState extends Equatable {
  const ListState();

  @override
  List<Object?> get props => [];
}

class ListInitial extends ListState {}

class ListLoading extends ListState {}

class ListLoaded extends ListState {
  final List<TaskList> lists;
  final String? selectedListId;

  const ListLoaded(this.lists, this.selectedListId);

  @override
  List<Object?> get props => [lists, selectedListId];
}

class ListSearchResults extends ListState {
  final List<TaskList> listResults;
  final List<Task> taskResults;
  final List<TaskList> allLists;

  const ListSearchResults(this.listResults, this.taskResults, this.allLists);

  @override
  List<Object?> get props => [listResults, taskResults, allLists];
}

class ListError extends ListState {
  final String message;

  const ListError(this.message);

  @override
  List<Object?> get props => [message];
}