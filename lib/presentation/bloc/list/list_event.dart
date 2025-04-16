part of 'list_bloc.dart';

@immutable
sealed class ListEvent {}

final class LoadLists extends ListEvent {}

final class AddList extends ListEvent {
  final String name;
  AddList(this.name);
}

final class SelectList extends ListEvent {
  final String listId;
  SelectList(this.listId);
}

final class DeleteList extends ListEvent {
  final String listId;
  DeleteList(this.listId);
}