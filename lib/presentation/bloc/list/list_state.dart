part of 'list_bloc.dart';

@immutable
abstract class ListState {}

class ListInitial extends ListState {}

class ListLoading extends ListState {}

class ListLoaded extends ListState {
  final List<TaskList> lists;
  final String selectedListId;

  ListLoaded(this.lists, this.selectedListId);
}

class ListError extends ListState {
  final String message;

  ListError(this.message);
}