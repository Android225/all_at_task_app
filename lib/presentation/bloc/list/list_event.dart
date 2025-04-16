part of 'list_bloc.dart';

@immutable
sealed class ListEvent {}

final class LoadLists extends ListEvent {}

final class AddList extends ListEvent {
  final String name;
  final String? description;
  final int color;
  final List<String> sharedLists;

  AddList(this.name, {this.description, this.color = 0xFF2196F3, this.sharedLists = const []});
}

final class SelectList extends ListEvent {
  final String listId;
  SelectList(this.listId);
}

final class DeleteList extends ListEvent {
  final String listId;
  DeleteList(this.listId);
}

final class SearchListsAndTasks extends ListEvent {
  final String query;
  SearchListsAndTasks(this.query);
}

final class UpdateListLastUsed extends ListEvent {
  final String listId;
  UpdateListLastUsed(this.listId);
}

final class UpdateList extends ListEvent {
  final TaskList list;
  UpdateList(this.list);
}

final class InviteToList extends ListEvent {
  final String listId;
  final String inviteeId;
  InviteToList(this.listId, this.inviteeId);
}

final class UpdateMemberRole extends ListEvent {
  final String listId;
  final String userId;
  final String role;
  UpdateMemberRole(this.listId, this.userId, this.role);
}