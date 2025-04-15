import 'package:all_at_task/data/models/task_list.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'list_event.dart';
part 'list_state.dart';

class ListBloc extends Bloc<ListEvent, ListState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ListBloc() : super(ListInitial()) {
    on<LoadLists>(_onLoadLists);
    on<SelectList>(_onSelectList);
  }

  Future<void> _onLoadLists(LoadLists event, Emitter<ListState> emit) async {
    emit(ListLoading());
    try {
      final userId = _auth.currentUser!.uid;
      final query = _firestore
          .collection('lists')
          .where('ownerId', isEqualTo: userId);

      final snapshot = await query.get();
      final lists = snapshot.docs.map((doc) => TaskList.fromMap(doc.data())).toList();

      // Проверяем наличие родительского списка
      final parentListExists = lists.any((list) => list.name == 'Основной');
      if (!parentListExists) {
        final parentList = TaskList(
          id: _firestore.collection('lists').doc().id,
          name: 'Основной',
          ownerId: userId,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('lists').doc(parentList.id).set(parentList.toMap());
        lists.add(parentList);
      }

      emit(ListLoaded(lists, lists.first.id));
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
}