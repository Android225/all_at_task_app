import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_at_task/data/models/task.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc() : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        print('TaskBloc: User not authenticated');
        emit(TaskError('Пользователь не авторизован'));
        return;
      }

      print('TaskBloc: Loading tasks for list ${event.listId}');
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('listId', isEqualTo: event.listId)
          .get();
      final tasks = tasksSnapshot.docs
          .map((doc) => Task.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      print('TaskBloc: Loaded ${tasks.length} tasks');
      emit(TaskLoaded(tasks: tasks, userId: userId));
    } catch (e) {
      print('TaskBloc: Error loading tasks: $e');
      emit(TaskError('Не удалось загрузить задачи: $e'));
    }
  }

  Future<void> _onAddTask(AddTask event, Emitter<TaskState> emit) async {
    try {
      print('TaskBloc: Adding task: ${event.title}');
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(TaskError('Пользователь не авторизован'));
        return;
      }
      final task = Task(
        title: event.title,
        description: event.description,
        listId: event.listId,
        ownerId: event.ownerId,
        deadline: event.deadline,
        priority: event.priority,
        assignedTo: event.assignedTo,
        isCompleted: event.isCompleted,
        isFavorite: event.isFavorite,
      );
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task.id)
          .set(task.toMap());
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        if (currentState.tasks.any((t) => t.listId == event.listId)) {
          emit(TaskLoaded(
            tasks: [...currentState.tasks, task],
            userId: currentState.userId,
          ));
        }
      }
    } catch (e) {
      print('TaskBloc: Error adding task: $e');
      emit(TaskError('Не удалось создать задачу: $e'));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    try {
      print('TaskBloc: Updating task: ${event.task.id}');
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(event.task.id)
          .update(event.task.toMap());
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final updatedTasks = currentState.tasks
            .map((task) => task.id == event.task.id ? event.task : task)
            .toList();
        emit(TaskLoaded(
          tasks: updatedTasks,
          userId: currentState.userId,
        ));
      }
    } catch (e) {
      print('TaskBloc: Error updating task: $e');
      emit(TaskError('Не удалось обновить задачу: $e'));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      print('TaskBloc: Deleting task: ${event.taskId}');
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(event.taskId)
          .delete();
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final updatedTasks =
        currentState.tasks.where((task) => task.id != event.taskId).toList();
        emit(TaskLoaded(
          tasks: updatedTasks,
          userId: currentState.userId,
        ));
      }
    } catch (e) {
      print('TaskBloc: Error deleting task: $e');
      emit(TaskError('Не удалось удалить задачу: $e'));
    }
  }
}