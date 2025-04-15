import 'package:all_at_task/data/models/task.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

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
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final query = _firestore
          .collection('tasks')
          .where('listId', isEqualTo: event.listId)
          .where('deadline',
          isGreaterThanOrEqualTo: now.toIso8601String(),
          isLessThanOrEqualTo: tomorrow.toIso8601String());

      final snapshot = await query.get();
      final tasks = snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

      emit(TaskLoaded(tasks, userId));
    } catch (e) {
      emit(TaskError('Ошибка загрузки задач: $e'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      final userId = _auth.currentUser!.uid;
      final task = Task(
        id: _firestore.collection('tasks').doc().id,
        title: event.title,
        description: event.description,
        deadline: event.deadline,
        listId: event.listId,
        assignedTo: userId,
        createdBy: userId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
      add(LoadTasks(event.listId)); // Перезагружаем задачи
    } catch (e) {
      emit(TaskError('Ошибка создания задачи: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      await _firestore.collection('tasks').doc(event.task.id).update(event.task.toMap());
      add(LoadTasks(event.task.listId)); // Перезагружаем задачи
    } catch (e) {
      emit(TaskError('Ошибка обновления задачи: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await _firestore.collection('tasks').doc(event.taskId).delete();
      add(LoadTasks(event.listId)); // Перезагружаем задачи
    } catch (e) {
      emit(TaskError('Ошибка удаления задачи: $e'));
    }
  }
}