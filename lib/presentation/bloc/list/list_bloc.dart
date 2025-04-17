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
    on<LinkList>(_onLinkList); // Новое событие для связывания списков
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final listsSnapshot = await _firestore
          .collection('lists')
          .where('members.$userId', isNotEqualTo: null)
          .get();
      final lists = listsSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()))
          .toList();
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
        linkedLists: [], // Инициализируем пустой linkedLists
      );
      await _firestore.collection('lists').doc(listId).set(list.toMap());
      await _firestore
          .collection('lists')
          .doc(listId)
          .update({'members.$userId': 'admin'});
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
      final listsSnapshot = await _firestore
          .collection('lists')
          .where('members.$userId', isNotEqualTo: null)
          .get();
      final lists = listsSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()))
          .toList();
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
      print('Приглашение отправлено: $invitationId');
    } catch (e) {
      emit(ListError('Не удалось отправить приглашение: попробуйте позже'));
    }
  }

  Future<void> _onUpdateMemberRole(UpdateMemberRole event, Emitter<ListState> emit) async {
    try {
      await _firestore
          .collection('lists')
          .doc(event.listId)
          .update({'members.${event.userId}': event.role});
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось обновить роль: попробуйте позже'));
    }
  }

  Future<void> _onLinkList(LinkList event, Emitter<ListState> emit) async {
    try {
      final listDoc = await _firestore.collection('lists').doc(event.listId).get();
      final currentLinkedLists = List<String>.from(listDoc.data()?['linkedLists'] ?? []);
      if (!currentLinkedLists.contains(event.linkedListId)) {
        currentLinkedLists.add(event.linkedListId);
        await _firestore.collection('lists').doc(event.listId).update({
          'linkedLists': currentLinkedLists,
        });
        print('Список ${event.linkedListId} привязан к ${event.listId}');
      }
      add(LoadLists());
    } catch (e) {
      emit(ListError('Не удалось привязать список: попробуйте позже'));
    }
  }
}