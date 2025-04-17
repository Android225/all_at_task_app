part of 'list_bloc.dart';

abstract class ListState extends Equatable {
  final String userId;

  const ListState(this.userId);

  @override
  List<Object> get props => [userId];
}

class ListInitial extends ListState {
  const ListInitial({required String userId}) : super(userId);

  @override
  List<Object> get props => [userId];
}

class ListLoading extends ListState {
  const ListLoading() : super('');
}

class ListLoaded extends ListState {
  final List<TaskList> lists;
  final String? selectedListId;

  const ListLoaded({
    required this.lists,
    required String userId,
    this.selectedListId,
  }) : super(userId);

  @override
  List<Object> get props => [lists, userId, selectedListId ?? ''];
}

class ListSearchResults extends ListState {
  final List<dynamic> results;
  final List<TaskList> lists;

  const ListSearchResults({
    required this.results,
    required this.lists,
    required String userId,
  }) : super(userId);

  @override
  List<Object> get props => [results, lists, userId];
}

class ListError extends ListState {
  final String message;

  ListError(this.message) : super('');

  @override
  List<Object> get props => [message];
}