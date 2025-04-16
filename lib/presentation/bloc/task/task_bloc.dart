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
      final query = _firestore
          .collection('tasks')
          .where('listId', isEqualTo: event.listId);
      final snapshot = await query.get();
      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
      emit(TaskLoaded(tasks, userId));
    } catch (e) {
      emit(TaskError('Не удалось загрузить задачи: попробуйте позже'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      final userId = _auth.currentUser!.uid;
      final task = Task(
        id: const Uuid().v4(),
        title: event.title,
        description: event.description,
        listId: event.listId,
        deadline: event.deadline != null ? Timestamp.fromDate(event.deadline!) : null,
        priority: event.priority,
        ownerId: userId,
        assignedTo: userId,
        createdAt: Timestamp.now(),
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