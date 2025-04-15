part of 'list_bloc.dart';

@immutable
abstract class ListEvent {}

class LoadLists extends ListEvent {}

class SelectList extends ListEvent {
  final String listId;

  SelectList(this.listId);
}