import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:get_it/get_it.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:uuid/uuid.dart';

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
    on<AddMembersToList>(_onAddMembersToList);
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
      emit(ListLoaded(
        lists: allLists,
        userId: userId,
        selectedListId: '',
        tasks: [],
      ));
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
      // Устанавливаем роль admin для создателя
      final updatedMembers = Map<String, String>.from(event.list.members);
      updatedMembers[userId] = 'admin';
      final updatedList = event.list.copyWith(
        members: updatedMembers,
        lastUsed: null, // При создании списка lastUsed = null
      );

      print('ListBloc: Saving list to Firestore: ${updatedList.toMap()}');
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(updatedList.id)
          .set(updatedList.toMap());
      print('ListBloc: List saved successfully: ${updatedList.id}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('lists')
          .doc(updatedList.id)
          .set({
        'listId': updatedList.id,
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        emit(ListLoaded(
          lists: [...currentState.lists, updatedList],
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: currentState.tasks,
        ));
      } else {
        emit(ListLoaded(
          lists: [updatedList],
          userId: userId,
          selectedListId: '',
          tasks: [],
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
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.list.id)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final listData = listSnapshot.data();
      if (listData == null) {
        emit(ListError('Данные списка не найдены'));
        return;
      }
      final members = Map<String, String>.from(listData['members'] ?? {});
      if (listData['ownerId'] != userId &&
          (!members.containsKey(userId) || members[userId] != 'admin')) {
        emit(ListError('У вас нет прав для редактирования этого списка'));
        return;
      }

      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.list.id)
          .update(event.list.toMap());

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == event.list.id) {
            return event.list;
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

      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final listData = listSnapshot.data();
      if (listData == null) {
        emit(ListError('Данные списка не найдены'));
        return;
      }
      if (listData['ownerId'] != userId) {
        emit(ListError('Только владелец может удалить список'));
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
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final listData = listSnapshot.data();
      if (listData == null) {
        emit(ListError('Данные списка не найдены'));
        return;
      }
      final members = Map<String, String>.from(listData['members'] ?? {});
      if (!members.containsKey(userId)) {
        emit(ListError('У вас нет доступа к этому списку'));
        return;
      }

      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .update({'lastUsed': Timestamp.fromDate(now)});

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == event.listId) {
            return list.copyWith(lastUsed: now);
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
      final tasks = <Task>[];

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data()..['id'] = doc.id;
        var task = Task.fromMap(data);

        // Загружаем username владельца задачи
        if (task.ownerId.isNotEmpty) {
          final profileDoc = await FirebaseFirestore.instance
              .collection('public_profiles')
              .doc(task.ownerId)
              .get();
          if (profileDoc.exists) {
            final username = profileDoc.data()?['username'] as String? ?? 'Неизвестный';
            task = task.copyWith(ownerUsername: username);
          } else {
            task = task.copyWith(ownerUsername: 'Неизвестный');
          }
        } else {
          task = task.copyWith(ownerUsername: 'Неизвестный');
        }

        if (task.title.toLowerCase().contains(event.query.toLowerCase())) {
          tasks.add(task);
        }
      }

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
      print(
          'ListBloc: Updating member role for user ${event.userId} in list ${event.listId}');
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final listData = listSnapshot.data();
      if (listData == null) {
        emit(ListError('Данные списка не найдены'));
        return;
      }
      final members = Map<String, String>.from(listData['members'] ?? {});
      if (listData['ownerId'] != currentUserId &&
          (!members.containsKey(currentUserId) ||
              members[currentUserId] != 'admin')) {
        emit(ListError('У вас нет прав для изменения ролей'));
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

  Future<void> _onLoadTasksForList(
      LoadTasksForList event, Emitter<ListState> emit) async {
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
      final members = Map<String, String>.from(list.members);
      if (!members.containsKey(userId)) {
        emit(ListError('У вас нет доступа к этому списку'));
        return;
      }

      // Загружаем задачи для текущего списка
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('listId', isEqualTo: event.listId)
          .get();
      final tasks = <Task>[];
      for (var doc in tasksSnapshot.docs) {
        final data = doc.data()..['id'] = doc.id;
        var task = Task.fromMap(data);

        // Загружаем username владельца задачи
        if (task.ownerId.isNotEmpty) {
          final profileDoc = await FirebaseFirestore.instance
              .collection('public_profiles')
              .doc(task.ownerId)
              .get();
          if (profileDoc.exists) {
            final username = profileDoc.data()?['username'] as String? ?? 'Неизвестный';
            task = task.copyWith(ownerUsername: username);
          } else {
            task = task.copyWith(ownerUsername: 'Неизвестный');
          }
        } else {
          task = task.copyWith(ownerUsername: 'Неизвестный');
        }

        tasks.add(task);
      }

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
          for (var doc in sharedTasksSnapshot.docs) {
            final data = doc.data()..['id'] = doc.id;
            var task = Task.fromMap(data);

            // Загружаем username владельца задачи
            if (task.ownerId.isNotEmpty) {
              final profileDoc = await FirebaseFirestore.instance
                  .collection('public_profiles')
                  .doc(task.ownerId)
                  .get();
              if (profileDoc.exists) {
                final username = profileDoc.data()?['username'] as String? ?? 'Неизвестный';
                task = task.copyWith(ownerUsername: username);
              } else {
                task = task.copyWith(ownerUsername: 'Неизвестный');
              }
            } else {
              task = task.copyWith(ownerUsername: 'Неизвестный');
            }

            sharedTasks.add(task);
          }
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

  Future<void> _onConnectListToMain(
      ConnectListToMain event, Emitter<ListState> emit) async {
    try {
      print('ListBloc: Connecting list ${event.listId} to main list');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Проверяем, есть ли доступ к подключаемому списку
      final listToConnectSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listToConnectSnapshot.exists) {
        emit(ListError('Подключаемый список не найден'));
        return;
      }
      final listToConnectData = listToConnectSnapshot.data();
      if (listToConnectData == null) {
        emit(ListError('Данные подключаемого списка не найдены'));
        return;
      }
      final listToConnectMembers =
      Map<String, String>.from(listToConnectData['members'] ?? {});
      if (!listToConnectMembers.containsKey(userId)) {
        emit(ListError('У вас нет доступа к подключаемому списку'));
        return;
      }

      // Находим или создаем "Основной" список пользователя
      final mainListSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .where('name', isEqualTo: 'Основной')
          .get();

      String mainListId;
      TaskList mainList;

      if (mainListSnapshot.docs.isEmpty) {
        // Создаем "Основной" список, если его нет
        mainListId = const Uuid().v4();
        mainList = TaskList(
          id: mainListId,
          name: 'Основной',
          ownerId: userId,
          description: 'Основной список пользователя',
          color: 0xFF0000FF, // Синий цвет по умолчанию
          createdAt: DateTime.now(),
          lastUsed: null,
          members: {userId: 'admin'},
          sharedLists: event.connect ? [event.listId] : [],
        );
        await FirebaseFirestore.instance
            .collection('lists')
            .doc(mainListId)
            .set(mainList.toMap());

        // Добавляем список в коллекцию пользователя
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('lists')
            .doc(mainListId)
            .set({
          'listId': mainListId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Обновляем существующий "Основной" список
        mainListId = mainListSnapshot.docs.first.id;
        final mainListData = mainListSnapshot.docs.first.data();
        mainList = TaskList.fromMap(mainListData..['id'] = mainListId);

        final updatedSharedLists = List<String>.from(mainList.sharedLists);
        if (event.connect && !updatedSharedLists.contains(event.listId)) {
          updatedSharedLists.add(event.listId);
        } else if (!event.connect && updatedSharedLists.contains(event.listId)) {
          updatedSharedLists.remove(event.listId);
        } else {
          return; // Ничего не изменилось
        }

        await FirebaseFirestore.instance
            .collection('lists')
            .doc(mainListId)
            .update({'sharedLists': updatedSharedLists});
        mainList = mainList.copyWith(sharedLists: updatedSharedLists);
      }

      // Обновляем состояние
      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = List<TaskList>.from(currentState.lists);
        final mainListIndex =
        updatedLists.indexWhere((list) => list.id == mainListId);
        if (mainListIndex != -1) {
          updatedLists[mainListIndex] = mainList;
        } else {
          updatedLists.add(mainList);
        }

        emit(ListLoaded(
          lists: updatedLists,
          userId: currentState.userId,
          selectedListId: currentState.selectedListId,
          tasks: currentState.tasks,
        ));

        // Перезагружаем задачи, если выбран "Основной" список
        if (currentState.selectedListId == mainListId) {
          add(LoadTasksForList(mainListId));
        }
      } else {
        emit(ListLoaded(
          lists: [mainList],
          userId: userId,
          selectedListId: '',
          tasks: [],
        ));
      }
    } catch (e) {
      print('ListBloc: Error connecting list to main: $e');
      emit(ListError('Не удалось подключить список: $e'));
    }
  }

  Future<void> _onAddMembersToList(
      AddMembersToList event, Emitter<ListState> emit) async {
    try {
      print(
          'ListBloc: Adding members to list: ${event.listId}, members: ${event.memberIds}');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(ListError('Пользователь не авторизован'));
        return;
      }

      // Проверяем токен авторизации
      await FirebaseAuth.instance.currentUser?.reload();

      // Загружаем текущий список
      final listSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.listId)
          .get();
      if (!listSnapshot.exists) {
        emit(ListError('Список не найден'));
        return;
      }
      final listData = listSnapshot.data();
      if (listData == null) {
        emit(ListError('Данные списка не найдены'));
        return;
      }
      print('ListBloc: List data: $listData');
      final list = TaskList.fromMap(listData..['id'] = listSnapshot.id);

      // Проверяем права
      final members = Map<String, String>.from(list.members);
      if (list.ownerId != userId &&
          (!members.containsKey(userId) || members[userId] != 'admin')) {
        emit(ListError('У вас нет прав для добавления участников'));
        return;
      }

      // Проверяем, существуют ли пользователи
      for (var memberId in event.memberIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('public_profiles')
            .doc(memberId)
            .get();
        if (!userDoc.exists) {
          emit(ListError('Пользователь $memberId не найден'));
          return;
        }

        // Проверяем, не является ли пользователь уже участником
        if (members.containsKey(memberId)) {
          print('ListBloc: User $memberId is already a member of list ${event.listId}');
          continue; // Пропускаем, если пользователь уже в списке
        }

        // Отправляем приглашение
        print('ListBloc: Sending invitation to $memberId for list ${event.listId}');
        GetIt.instance<InvitationBloc>()
            .add(SendInvitation(event.listId, memberId));
      }

      // Не обновляем members здесь, это произойдет после принятия приглашения
      emit(state); // Состояние не меняется, так как мы только отправили приглашение
    } catch (e) {
      print('ListBloc: Error adding members to list: $e');
      emit(ListError('Не удалось добавить участников: $e'));
    }
  }
}