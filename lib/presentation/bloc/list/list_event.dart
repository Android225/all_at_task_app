part of 'list_bloc.dart';

@immutable
abstract class ListEvent {}

class LoadLists extends ListEvent {}

class SelectList extends ListEvent {
  final String listId;

  SelectList(this.listId);
}

class AddList extends ListEvent {
  final String name;

  AddList(this.name);
}

class DeleteList extends ListEvent {
  final String listId;

  DeleteList(this.listId);
}