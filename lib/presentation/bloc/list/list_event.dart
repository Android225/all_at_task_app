part of 'list_bloc.dart';

abstract class ListEvent extends Equatable {
  const ListEvent();

  @override
  List<Object> get props => [];
}

class LoadLists extends ListEvent {
  final String userId;

  const LoadLists({this.userId = ''});

  @override
  List<Object> get props => [userId];
}

class AddList extends ListEvent {
  final TaskList list;

  const AddList(this.list);

  @override
  List<Object> get props => [list];
}

class UpdateList extends ListEvent {
  final TaskList list;

  const UpdateList(this.list);

  @override
  List<Object> get props => [list];
}

class DeleteList extends ListEvent {
  final String listId;

  const DeleteList(this.listId);

  @override
  List<Object> get props => [listId];
}

class SelectList extends ListEvent {
  final String listId;

  const SelectList(this.listId);

  @override
  List<Object> get props => [listId];
}

class UpdateListLastUsed extends ListEvent {
  final String listId;

  const UpdateListLastUsed(this.listId);

  @override
  List<Object> get props => [listId];
}

class SearchListsAndTasks extends ListEvent {
  final String query;

  const SearchListsAndTasks(this.query);

  @override
  List<Object> get props => [query];
}

class UpdateMemberRole extends ListEvent {
  final String listId;
  final String userId;
  final String role;

  const UpdateMemberRole(this.listId, this.userId, this.role);

  @override
  List<Object> get props => [listId, userId, role];
}