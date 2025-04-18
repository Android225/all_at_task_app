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
    on<LoadTasksForList>(_onLoadTasksForList);
    on<ConnectListToMain>(_onConnectListToMain);
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
      final ownerSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      final ownerLists = ownerSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      final userListsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lists')
          .orderBy('addedAt', descending: true)
          .get();
      final listIds = userListsSnapshot.docs
          .map((doc) => doc.data()['listId'] as String)
          .toList();

      final memberLists = <TaskList>[];
      if (listIds.isNotEmpty) {
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
        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: currentState.tasks,
        ));
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
      // Удаляем из sharedLists "Основного" списка
      final mainListSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .where('name', isEqualTo: 'Основной')
          .get();
      if (mainListSnapshot.docs.isNotEmpty) {
        final mainList = mainListSnapshot.docs.first;
        final mainListData = TaskList.fromMap(mainList.data()..['id'] = mainList.id);
        if (mainListData.sharedLists.contains(event.listId)) {
          final updatedSharedLists = List<String>.from(mainListData.sharedLists)
            ..remove(event.listId);
          await FirebaseFirestore.instance
              .collection('lists')
              .doc(mainList.id)
              .update({'sharedLists': updatedSharedLists});
        }
      }
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .delete();
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
        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: currentState.tasks,
        ));
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
        tasks: currentState.tasks,
      ));
      add(LoadTasksForList(event.listId));
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
          tasks: currentState.tasks,
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
          tasks: currentState.tasks,
        ));
      }
    } catch (e) {
      print('ListBloc: Error updating member role: $e');
      emit(ListError('Не удалось обновить роль участника: $e'));
    }
  }

  Future<void> _onLoadTasksForList(LoadTasksForList event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Loading tasks for list: ${event.listId}');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Находим список
      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final list = TaskList.fromMap(listSnapshot.data()!..['id'] = listSnapshot.id);

      // Загружаем задачи для текущего списка
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('listId', isEqualTo: event.listId)
          .get();
      final tasks = tasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      // Если список "Основной", загружаем задачи из sharedLists
      List<Task> sharedTasks = [];
      if (list.name.toLowerCase() == 'основной' && list.sharedLists.isNotEmpty) {
        const batchSize = 10;
        for (var i = 0; i < list.sharedLists.length; i += batchSize) {
          final batchIds = list.sharedLists.sublist(
              i, i + batchSize > list.sharedLists.length ? list.sharedLists.length : i + batchSize);
          final sharedTasksSnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('listId', whereIn: batchIds)
              .get();
          sharedTasks.addAll(sharedTasksSnapshot.docs
              .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id)));
        }
      }

      final allTasks = [...tasks, ...sharedTasks];
      print('ListBloc: Loaded ${allTasks.length} tasks for list ${event.listId}');
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        emit(ListLoaded(
          lists: currentState.lists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: allTasks,
        ));
      }
    } catch (e) {
      print('ListBloc: Error loading tasks: $e');
      emit(ListError('Не удалось загрузить задачи: $e'));
    }
  }

  Future<void> _onConnectListToMain(ConnectListToMain event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Connecting list ${event.listId} to main list');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Находим "Основной" список
      final mainListSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .where('name', isEqualTo: 'Основной')
          .get();
      if (mainListSnapshot.docs.isEmpty) {
        emit(ListError('Основной список не найден'));
        return;
      }
      final mainList = mainListSnapshot.docs.first;
      final mainListData = TaskList.fromMap(mainList.data()..['id'] = mainList.id);

      // Обновляем sharedLists
      final updatedSharedLists = List<String>.from(mainListData.sharedLists);
      if (event.connect && !updatedSharedLists.contains(event.listId)) {
        updatedSharedLists.add(event.listId);
      } else if (!event.connect && updatedSharedLists.contains(event.listId)) {
        updatedSharedLists.remove(event.listId);
      } else {
        return; // Ничего не изменилось
      }

      await FirebaseFirestore.instance
          .collection('lists')
          .doc(mainList.id)
          .update({'sharedLists': updatedSharedLists});

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == mainList.id) {
            return list.copyWith(sharedLists: updatedSharedLists);
          }
          return list;
        }).toList();
        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: currentState.tasks,
        ));
        // Перезагружаем задачи, если выбран "Основной" список
        if (currentState.selectedListId == mainList.id) {
          add(LoadTasksForList(mainList.id));
        }
      }
    } catch (e) {
      print('ListBloc: Error connecting list to main: $e');
      emit(ListError('Не удалось подключить список: $e'));
    }
  }
}