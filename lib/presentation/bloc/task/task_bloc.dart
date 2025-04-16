import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/data/models/task.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskBloc() : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final userId = _auth.currentUser!.uid;
      QuerySnapshot snapshot;
      if (event.listId == 'main') {
        final listsSnapshot = await _firestore
            .collection('lists')
            .where('members.$userId', isNotEqualTo: null)
            .get();
        final listIds = listsSnapshot.docs.map((doc) => doc.id).toList();
        snapshot = await _firestore
            .collection('tasks')
            .where('listId', whereIn: listIds.isNotEmpty ? listIds : ['dummy'])
            .orderBy('createdAt', descending: true)
            .get();
      } else {
        snapshot = await _firestore
            .collection('tasks')
            .where('listId', isEqualTo: event.listId)
            .orderBy('createdAt', descending: true)
            .get();
      }
      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>)).toList();
      emit(TaskLoaded(tasks, userId));
    } catch (e) {
      emit(TaskError('Не удалось загрузить задачи: попробуйте позже'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      final task = Task(
        id: const Uuid().v4(),
        title: event.title,
        description: event.description,
        listId: event.listId,
        ownerId: _auth.currentUser!.uid,
        createdAt: Timestamp.now(),
        deadline: event.deadline != null ? Timestamp.fromDate(event.deadline!) : null,
        priority: event.priority,
        assignedTo: _auth.currentUser!.uid,
        isCompleted: false,
        isFavorite: false,
      );
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      add(LoadTasks(event.listId));
    } catch (e) {
      emit(TaskError('Не удалось добавить задачу: попробуйте позже'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _firestore.collection('tasks').doc(event.task.id).update(event.task.toMap());
      add(LoadTasks(event.task.listId));
    } catch (e) {
      emit(TaskError('Не удалось обновить задачу: попробуйте позже'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _firestore.collection('tasks').doc(event.taskId).delete();
      add(LoadTasks(event.listId));
    } catch (e) {
      emit(TaskError('Не удалось удалить задачу: попробуйте позже'));
    }
  }
}