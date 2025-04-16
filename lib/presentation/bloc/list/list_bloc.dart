import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';

part 'list_event.dart';
part 'list_state.dart';

class ListBloc extends Bloc<ListEvent, ListState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ListBloc() : super(ListInitial()) {
    on<LoadLists>(_onLoadLists);
    on<AddList>(_onAddList);
    on<SelectList>(_onSelectList);
    on<DeleteList>(_onDeleteList);
    on<SearchListsAndTasks>(_onSearchListsAndTasks);
    on<UpdateListLastUsed>(_onUpdateListLastUsed);
    on<UpdateList>(_onUpdateList);
    on<InviteToList>(_onInviteToList);
    on<UpdateMemberRole>(_onUpdateMemberRole);
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final userId = _auth.currentUser!.uid;
      // Ищем списки, где пользователь есть в подколлекции members
      final membersSnapshot = await _firestore
          .collectionGroup('members')
          .where('role', isNotEqualTo: null)
          .get();
      final listIds = membersSnapshot.docs
          .where((doc) => doc.reference.parent.parent!.id != null)
          .map((doc) => doc.reference.parent.parent!.id)
          .toList();
      final lists = <TaskList>[];
      for (final listId in listIds) {
        final listDoc = await _firestore.collection('lists').doc(listId).get();
        if (listDoc.exists) {
          lists.add(TaskList.fromMap(listDoc.data()!));
        }
      }
      emit(ListLoaded(lists, lists.isNotEmpty ? lists.first.id : null));
    } catch (e) {
      emit(ListError('Не удалось загрузить списки: попробуйте позже'));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      final userId = _auth.currentUser!.uid;
      final listId = const Uuid().v4();
      final list = TaskList(
        id: listId,
        name: event.name,
        ownerId: userId,
        description: event.description,
        color: event.color,
        sharedLists: event.sharedLists,
      );
      await _firestore.collection('lists').doc(listId).set(list.toMap());
      await _firestore
          .collection('lists')
          .doc(listId)
          .collection('members')
          .doc(userId)
          .set({
        'role': 'admin',
      });
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось добавить список: попробуйте позже'));
    }
  }

  void _onSelectList(SelectList event, Emitter<ListState> emit) {
    if (state is ListLoaded) {
      final currentState = state as ListLoaded;
      emit(ListLoaded(currentState.lists, event.listId));
    }
  }

  Future<void> _onDeleteList(DeleteList event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).delete();
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось удалить список: попробуйте позже'));
    }
  }

  Future<void> _onSearchListsAndTasks(SearchListsAndTasks event, Emitter<ListState> emit) async {
    if (event.query.isEmpty) {
      add(LoadLists());
      return;
    }
    try {
      final userId = _auth.currentUser!.uid;
      final membersSnapshot = await _firestore
          .collectionGroup('members')
          .where('role', isNotEqualTo: null)
          .get();
      final listIds = membersSnapshot.docs
          .map((doc) => doc.reference.parent.parent!.id)
          .toList();
      final lists = <TaskList>[];
      for (final listId in listIds) {
        final listDoc = await _firestore.collection('lists').doc(listId).get();
        if (listDoc.exists) {
          lists.add(TaskList.fromMap(listDoc.data()!));
        }
      }
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('ownerId', isEqualTo: userId)
          .get();
      final tasks = tasksQuery.docs.map((doc) => Task.fromMap(doc.data())).toList();
      final results = <dynamic>[
        ...lists.where((list) => list.name.toLowerCase().contains(event.query.toLowerCase())),
        ...tasks.where((task) => task.title.toLowerCase().contains(event.query.toLowerCase())),
      ];
      emit(ListSearchResults(lists, results));
    } catch (e) {
      emit(ListError('Не удалось выполнить поиск: попробуйте позже'));
    }
  }

  Future<void> _onUpdateListLastUsed(UpdateListLastUsed event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).update({
        'lastUsed': FieldValue.serverTimestamp(),
      });
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось обновить список: попробуйте позже'));
    }
  }

  Future<void> _onUpdateList(UpdateList event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.list.id).update(event.list.toMap());
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось обновить список: попробуйте позже'));
    }
  }

  Future<void> _onInviteToList(InviteToList event, Emitter<ListState> emit) async {
    try {
      final invitationId = const Uuid().v4();
      await _firestore.collection('invitations').doc(invitationId).set({
        'id': invitationId,
        'listId': event.listId,
        'inviteeId': event.inviteeId,
        'inviterId': _auth.currentUser!.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      emit(ListError('Не удалось отправить приглашение: попробуйте позже'));
    }
  }

  Future<void> _onUpdateMemberRole(UpdateMemberRole event, Emitter<ListState> emit) async {
    try {
      await _firestore
          .collection('lists')
          .doc(event.listId)
          .collection('members')
          .doc(event.userId)
          .update({
        'role': event.role,
      });
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось обновить роль: попробуйте позже'));
    }
  }
}