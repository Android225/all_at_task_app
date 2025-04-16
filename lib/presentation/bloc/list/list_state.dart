part of 'list_bloc.dart';

@immutable
sealed class ListState {}

final class ListInitial extends ListState {}

final class ListLoading extends ListState {}

final class ListLoaded extends ListState {
  final List<TaskList> lists;
  final String? selectedListId;

  ListLoaded(this.lists, this.selectedListId);
}

final class ListSearchResults extends ListState {
  final List<TaskList> lists;
  final List<dynamic> results;

  ListSearchResults(this.lists, this.results);
}

final class ListError extends ListState {
  final String message;

  ListError(this.message);
}