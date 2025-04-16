import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
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
      emit(ListLoaded(lists, lists.isNotEmpty ? lists.first.id : null));
    } catch (e) {
      emit(ListError('Не удалось загрузить списки: попробуйте позже'));
    }
  }

  Future<void> _onAddList(AddList event, Emitter<ListState> emit) async {
    try {
      final userId = _auth.currentUser!.uid;
      final list = TaskList(
        id: const Uuid().v4(),
        name: event.name,
        ownerId: userId,
      );
      await _firestore.collection('lists').doc(list.id).set(list.toMap());
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
}