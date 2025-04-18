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
        print('ListBloc: User not authenticated');
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      print('ListBloc: Loading lists for user $userId');
      // Запрос списков, где пользователь является владельцем
      final ownerSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final ownerLists = ownerSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      // Запрос идентификаторов списков из users/{uid}/lists
      final userListsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lists')
          .orderBy('addedAt', descending: true)
          .get();
      final listIds = userListsSnapshot.docs
          .map((doc) => doc.data()['listId'] as String)
          .toList();

      // Загружаем списки по идентификаторам
      final memberLists = <TaskList>[];
      if (listIds.isNotEmpty) {
        // Разбиваем listIds на группы по 10, так как whereIn поддерживает до 10 элементов
        const batchSize = 10;
        for (var i = 0; i < listIds.length; i += batchSize) {
          final batchIds = listIds.sublist(
              i, i + batchSize > listIds.length ? listIds.length : i + batchSize);
          final memberSnapshot = await FirebaseFirestore.instance
              .collection('lists')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          memberLists.addAll(memberSnapshot.docs
              .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id)));
        }
      }

      // Объединяем списки и убираем дубликаты
      final allListsMap = <String, TaskList>{};
      for (var list in [...ownerLists, ...memberLists]) {
        allListsMap[list.id] = list;
      }
      final allLists = allListsMap.values.toList();

      print('ListBloc: Loaded ${allLists.length} unique lists');
      emit(ListLoaded(lists: allLists, userId: userId));
    } catch (e) {
      print('ListBloc: Error loading lists: $e');
      emit(ListError('Не удалось загрузить списки: $e'));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Adding list: ${event.list.name}');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.list.id)
          .set(event.list.toMap());
      // Добавляем список в users/{uid}/lists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(event.list.id)
          .set({
        'listId': event.list.id,
        'addedAt': FieldValue.serverTimestamp(),
      });
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        emit(ListLoaded(
          lists: [...currentState.lists, event.list],
          userId: currentState.userId,
        ));
      }
    } catch (e) {
      print('ListBloc: Error adding list: $e');
      emit(ListError('Не удалось создать список: $e'));
    }
  }

  Future<void> _onUpdateList(UpdateList event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Updating list: ${event.list.id}');
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
      print('ListBloc: Error updating list: $e');
      emit(ListError('Не удалось обновить список: $e'));
    }
  }

  Future<void> _onDeleteList(DeleteList event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Deleting list: ${event.listId}');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .delete();
      // Удаляем из users/{uid}/lists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
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
      print('ListBloc: Error deleting list: $e');
      emit(ListError('Не удалось удалить список: $e'));
    }
  }

  Future<void> _onSelectList(SelectList event, Emitter<ListState> emit) async {
    print('ListBloc: Selecting list: ${event.listId}');
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
      print('ListBloc: Updating last used for list: ${event.listId}');
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
      print('ListBloc: Error updating last used: $e');
      emit(ListError('Не удалось обновить время использования: $e'));
    }
  }

  Future<void> _onSearchListsAndTasks(
      SearchListsAndTasks event, Emitter<ListState> emit) async {
    if (event.query.isEmpty) {
      if (state is ListLoaded) {
        print('ListBloc: Empty search query, restoring state');
        emit(state as ListLoaded);
      }
      return;
    }
    try {
      final userId = state.userId.isNotEmpty
          ? state.userId
          : FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        print('ListBloc: User not authenticated for search');
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      print('ListBloc: Searching for: ${event.query}');
      // Получаем списки из users/{uid}/lists
      final userListsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lists')
          .get();
      final listIds = userListsSnapshot.docs
          .map((doc) => doc.data()['listId'] as String)
          .toList();

      final allLists = <TaskList>[];
      if (listIds.isNotEmpty) {
        // Разбиваем listIds на группы по 10
        const batchSize = 10;
        for (var i = 0; i < listIds.length; i += batchSize) {
          final batchIds = listIds.sublist(
              i, i + batchSize > listIds.length ? listIds.length : i + batchSize);
          final listsSnapshot = await FirebaseFirestore.instance
              .collection('lists')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          allLists.addAll(listsSnapshot.docs
              .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id)));
        }
      }

      final matchingLists = allLists
          .where((list) =>
          list.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();

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
      print('ListBloc: Found ${results.length} search results');
      emit(ListSearchResults(
        results: results,
        lists: allLists,
        userId: userId,
      ));
    } catch (e) {
      print('ListBloc: Error searching: $e');
      emit(ListError('Не удалось выполнить поиск: $e'));
    }
  }

  Future<void> _onUpdateMemberRole(
      UpdateMemberRole event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Updating member role for user ${event.userId} in list ${event.listId}');
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .update({
        'members.${event.userId}': event.role,
      });
      // Добавляем или обновляем список в users/{uid}/lists для нового участника
      await FirebaseFirestore.instance
          .collection('users')
          .doc(event.userId)
          .collection('lists')
          .doc(event.listId)
          .set({
        'listId': event.listId,
        'addedAt': FieldValue.serverTimestamp(),
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
      print('ListBloc: Error updating member role: $e');
      emit(ListError('Не удалось обновить роль участника: $e'));
    }
  }
}