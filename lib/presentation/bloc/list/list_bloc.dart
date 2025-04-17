import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/models/task.dart';

part 'list_event.dart';
part 'list_state.dart';

class ListBloc extends Bloc<ListEvent, ListState> {
  ListBloc() : super(const ListInitial(userId: '')) {
    on<LoadLists>(_onLoadLists);
    on<AddList>(_onAddList);
    on<UpdateList>(_onUpdateList);
    on<DeleteList>(_onDeleteList);
    on<SelectList>(_onSelectList);
    on<UpdateListLastUsed>(_onUpdateListLastUsed);
    on<SearchListsAndTasks>(_onSearchListsAndTasks);
    on<UpdateMemberRole>(_onUpdateMemberRole);
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final userId = event.userId.isNotEmpty
          ? event.userId
          : FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Загрузка списков, где пользователь является владельцем
      final ownerSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final ownerLists = ownerSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      // Загрузка списков, где пользователь является участником
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('members.$userId', isNotEqualTo: null)
          .orderBy('createdAt', descending: true)
          .get();
      final memberLists = memberSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      final allLists = [...ownerLists, ...memberLists];
      emit(ListLoaded(lists: allLists, userId: userId));
    } catch (e) {
      emit(ListError('Не удалось загрузить списки: $e'));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.list.id)
          .set(event.list.toMap());
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        emit(ListLoaded(
          lists: [...currentState.lists, event.list],
          userId: currentState.userId,
        ));
      }
    } catch (e) {
      emit(ListError('Не удалось создать список: $e'));
    }
  }

  Future<void> _onUpdateList(UpdateList event, Emitter<ListState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.list.id)
          .update(event.list.toMap());
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists
            .map((list) => list.id == event.list.id ? event.list : list)
            .toList();
        emit(ListLoaded(lists: updatedLists, userId: currentState.userId));
      }
    } catch (e) {
      emit(ListError('Не удалось обновить список: $e'));
    }
  }

  Future<void> _onDeleteList(DeleteList event, Emitter<ListState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .delete();
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists =
        currentState.lists.where((list) => list.id != event.listId).toList();
        emit(ListLoaded(lists: updatedLists, userId: currentState.userId));
      }
    } catch (e) {
      emit(ListError('Не удалось удалить список: $e'));
    }
  }

  Future<void> _onSelectList(SelectList event, Emitter<ListState> emit) async {
    if (state is ListLoaded) {
      final currentState = state as ListLoaded;
      emit(ListLoaded(
        lists: currentState.lists,
        userId: currentState.userId,
        selectedListId: event.listId,
      ));
    }
  }

  Future<void> _onUpdateListLastUsed(
      UpdateListLastUsed event, Emitter<ListState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .update({'lastUsed': Timestamp.fromDate(DateTime.now())});
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == event.listId) {
            return list.copyWith(lastUsed: DateTime.now());
          }
          return list;
        }).toList();
        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
        ));
      }
    } catch (e) {
      emit(ListError('Не удалось обновить время использования: $e'));
    }
  }

  Future<void> _onSearchListsAndTasks(
      SearchListsAndTasks event, Emitter<ListState> emit) async {
    if (event.query.isEmpty) {
      if (state is ListLoaded) {
        emit(state as ListLoaded);
      }
      return;
    }
    try {
      final userId = state.userId.isNotEmpty
          ? state.userId
          : FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Поиск списков
      final listsSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .get();
      final memberListsSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('members.$userId', isNotEqualTo: null)
          .get();
      final allLists = [...listsSnapshot.docs, ...memberListsSnapshot.docs]
          .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      final matchingLists = allLists
          .where((list) =>
          list.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      // Поиск задач
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('ownerId', isEqualTo: userId)
          .get();
      final tasks = tasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
          .where((task) =>
          task.title.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

      final results = [...matchingLists, ...tasks];
      emit(ListSearchResults(
        results: results,
        lists: allLists,
        userId: userId,
      ));
    } catch (e) {
      emit(ListError('Не удалось выполнить поиск: $e'));
    }
  }

  Future<void> _onUpdateMemberRole(
      UpdateMemberRole event, Emitter<ListState> emit) async {
    try {
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .update({
        'members.${event.userId}': event.role,
      });
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == event.listId) {
            final updatedMembers = Map<String, String>.from(list.members);
            updatedMembers[event.userId] = event.role;
            return list.copyWith(members: updatedMembers);
          }
          return list;
        }).toList();
        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
        ));
      }
    } catch (e) {
      emit(ListError('Не удалось обновить роль участника: $e'));
    }
  }
}