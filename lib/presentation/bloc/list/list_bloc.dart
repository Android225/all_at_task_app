import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_state.dart';

part 'list_event.dart';

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
    on<LinkList>(_onLinkList);
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final listsSnapshot = await _firestore
          .collection('lists')
          .where('members.$userId', isNotEqualTo: null)
          .get();
      print('Firestore listsSnapshot docs: ${listsSnapshot.docs.length}');
      print('Firestore listsSnapshot data: ${listsSnapshot.docs.map((doc) => doc.data()).toList()}');
      final lists = listsSnapshot.docs
          .map((doc) => TaskList.fromMap(doc.data()))
          .toList();
      print('Загружено списков: ${lists.length}, имена: ${lists.map((l) => l.name).toList()}');
      lists.sort((a, b) {
        if (a.name.toLowerCase() == 'основной') return -1;
        if (b.name.toLowerCase() == 'основной') return 1;
        return 0;
      });
      emit(ListLoaded(lists, lists.isNotEmpty ? lists.first.id : null));
    } catch (e) {
      print('Ошибка загрузки списков: $e');
      emit(ListError('Не удалось загрузить списки: попробуйте позже'));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      final userId = _auth.currentUser!.uid;
      final listId = const Uuid().v4();
      final newList = TaskList(
        id: listId,
        name: event.name,
        description: event.description,
        color: event.color,
        ownerId: userId,
        members: {userId: 'admin'},
        sharedLists: event.sharedLists,
        linkedLists: event.linkedLists,
        createdAt: Timestamp.fromDate(DateTime.now()),
      );

      await _firestore.collection('lists').doc(listId).set(newList.toMap());

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = [...currentState.lists, newList];
        updatedLists.sort((a, b) {
          if (a.name.toLowerCase() == 'основной') return -1;
          if (b.name.toLowerCase() == 'основной') return 1;
          return 0;
        });
        emit(ListLoaded(updatedLists, currentState.selectedListId));
      } else {
        emit(ListLoaded([newList], newList.id));
      }
    } catch (e) {
      print('Ошибка создания списка: $e');
      emit(ListError('Не удалось создать список: $e'));
    }
  }

  Future<void> _onSelectList(SelectList event, Emitter<ListState> emit) async {
    if (state is ListLoaded) {
      final currentState = state as ListLoaded;
      emit(ListLoaded(currentState.lists, event.listId));
    }
  }

  Future<void> _onDeleteList(DeleteList event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).delete();

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.where((list) => list.id != event.listId).toList();
        final newSelectedListId = updatedLists.isNotEmpty
            ? (currentState.selectedListId == event.listId ? updatedLists.first.id : currentState.selectedListId)
            : null;
        emit(ListLoaded(updatedLists, newSelectedListId));
      }
    } catch (e) {
      print('Ошибка удаления списка: $e');
      emit(ListError('Не удалось удалить список: $e'));
    }
  }

  Future<void> _onSearchListsAndTasks(SearchListsAndTasks event, Emitter<ListState> emit) async {
    if (state is ListLoaded) {
      final currentState = state as ListLoaded;
      final query = event.query.toLowerCase();
      final listResults = <TaskList>[];
      final taskResults = <Task>[];

      for (final list in currentState.lists) {
        if (list.name.toLowerCase().contains(query)) {
          listResults.add(list);
        }
      }

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('listId', whereIn: currentState.lists.map((l) => l.id).toList())
          .get();

      final tasks = tasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .where((task) => task.title.toLowerCase().contains(query))
          .toList();

      taskResults.addAll(tasks);
      emit(ListSearchResults(listResults, taskResults, currentState.lists));
    }
  }

  Future<void> _onUpdateListLastUsed(UpdateListLastUsed event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).update({
        'lastUsed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Ошибка обновления lastUsed: $e');
    }
  }

  Future<void> _onUpdateList(UpdateList event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.list.id).update(event.list.toMap());

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists
            .map((list) => list.id == event.list.id ? event.list : list)
            .toList();
        emit(ListLoaded(updatedLists, currentState.selectedListId));
      }
    } catch (e) {
      print('Ошибка обновления списка: $e');
      emit(ListError('Не удалось обновить список: $e'));
    }
  }

  Future<void> _onInviteToList(InviteToList event, Emitter<ListState> emit) async {
    try {
      final invitationId = const Uuid().v4();
      await _firestore.collection('invitations').doc(invitationId).set({
        'id': invitationId,
        'listId': event.listId,
        'inviterId': _auth.currentUser!.uid,
        'inviteeId': event.inviteeId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('Ошибка отправки приглашения: $e');
      emit(ListError('Не удалось отправить приглашение: $e'));
    }
  }

  Future<void> _onUpdateMemberRole(UpdateMemberRole event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).update({
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
        emit(ListLoaded(updatedLists, currentState.selectedListId));
      }
    } catch (e) {
      print('Ошибка обновления роли: $e');
      emit(ListError('Не удалось обновить роль: $e'));
    }
  }

  Future<void> _onLinkList(LinkList event, Emitter<ListState> emit) async {
    try {
      await _firestore.collection('lists').doc(event.listId).update({
        'linkedLists': FieldValue.arrayUnion([event.linkedListId]),
      });

      if (state is ListLoaded) {
        final currentState = state as ListLoaded;
        final updatedLists = currentState.lists.map((list) {
          if (list.id == event.listId) {
            return list.copyWith(linkedLists: [...list.linkedLists, event.linkedListId]);
          }
          return list;
        }).toList();
        emit(ListLoaded(updatedLists, currentState.selectedListId));
      }
    } catch (e) {
      print('Ошибка связывания списков: $e');
      emit(ListError('Не удалось связать списки: $e'));
    }
  }
}