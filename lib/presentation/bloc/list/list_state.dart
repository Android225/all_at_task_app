part of 'list_bloc.dart';

abstract class ListState {}

class ListInitial extends ListState {}

class ListLoading extends ListState {}

class ListLoaded extends ListState {
  final List<TaskList> lists;
  final String? selectedListId; // Изменили на String?

  ListLoaded(this.lists, this.selectedListId);
}

class ListError extends ListState {
  final String message;

  ListError(this.message);
}