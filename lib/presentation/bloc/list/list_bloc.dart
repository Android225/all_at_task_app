import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:all_at_task/data/models/task_list.dart';

part 'list_event.dart';
part 'list_state.dart';

class ListBloc extends Bloc<ListEvent, ListState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ListBloc() : super(ListInitial()) {
    on<LoadLists>(_onLoadLists);
    on<SelectList>(_onSelectList);
    on<AddList>(_onAddList);
    on<DeleteList>(_onDeleteList);
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final query = _firestore
          .collection('lists')
          .where('ownerId', isEqualTo: _auth.currentUser!.uid);
      final snapshot = await query.get();
      final lists = snapshot.docs.map((doc) {
        try {
          return TaskList.fromMap(doc.data());
        } catch (e) {
          return null;
        }
      }).whereType<TaskList>().toList();
      emit(ListLoaded(lists, lists.isNotEmpty ? lists[0].id : null));
    } catch (e) {
      emit(ListError('Ошибка загрузки списков: $e'));
    }
  }

  void _onSelectList(SelectList event, Emitter<ListState> emit) {
    if (state is ListLoaded) {
      final currentState = state as ListLoaded;
      emit(ListLoaded(currentState.lists, event.listId));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      final listId = _firestore.collection('lists').doc().id;
      final newList = TaskList(
        id: listId,
        name: event.name,
        ownerId: _auth.currentUser!.uid,
        participants: [],
        roles: [],
        createdAt: DateTime.now(),
      );
      await _firestore.collection('lists').doc(listId).set(newList.toMap());
      add(LoadLists());
    } catch (e) {
      emit(ListError('Ошибка создания списка: $e'));
    }
  }

  Future<void> _onDeleteList(DeleteList event, Emitter<ListState> emit) async {
    try {
      final tasksQuery = _firestore
          .collection('tasks')
          .where('listId', isEqualTo: event.listId);
      final tasksSnapshot = await tasksQuery.get();
      for (var doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('lists').doc(event.listId).delete();
      add(LoadLists());
    } catch (e) {
      emit(ListError('Ошибка удаления списка: $e'));
    }
  }
}