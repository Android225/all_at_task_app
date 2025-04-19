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

      // Загружаем username владельца
      String ownerUsername = 'Неизвестный';
      final profileDoc = await FirebaseFirestore.instance
          .collection('public_profiles')
          .doc(event.ownerId)
          .get();
      if (profileDoc.exists) {
        ownerUsername = profileDoc.data()?['username'] as String? ?? 'Неизвестный';
      }

      final task = Task(
        title: event.title,
        description: event.description,
        listId: event.listId,
        ownerId: event.ownerId,
        ownerUsername: ownerUsername, // Сохраняем username
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
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        emit(TaskError('Пользователь не авторизован'));
        return;
      }

      // Проверяем доступ к списку задачи
      final listDoc = await FirebaseFirestore.instance
          .collection('lists')
          .doc(event.task.listId)
          .get();
      if (!listDoc.exists) {
        emit(TaskError('Список задачи не найден'));
        return;
      }
      final listData = listDoc.data();
      if (listData == null) {
        emit(TaskError('Данные списка не найдены'));
        return;
      }
      final members = Map<String, String>.from(listData['members'] ?? {});
      if (!members.containsKey(userId)) {
        emit(TaskError('У вас нет доступа к списку этой задачи'));
        return;
      }

      // Проверяем, что пользователь может обновить задачу
      if (event.task.ownerId != userId && members[userId] != 'admin') {
        // Если пользователь не владелец и не админ, проверяем, какие поля обновляются
        final currentTaskDoc = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(event.task.id)
            .get();
        if (!currentTaskDoc.exists) {
          emit(TaskError('Задача не найдена'));
          return;
        }
        final currentTask = Task.fromMap(currentTaskDoc.data()!..['id'] = currentTaskDoc.id);
        final updatedFields = <String, bool>{};
        if (event.task.isCompleted != currentTask.isCompleted) updatedFields['isCompleted'] = true;
        if (event.task.isFavorite != currentTask.isFavorite) updatedFields['isFavorite'] = true;
        if (event.task.deadline != currentTask.deadline) updatedFields['deadline'] = true;
        if (updatedFields.keys.length != (event.task.toMap()..remove('id')).length) {
          emit(TaskError('Вы можете обновлять только статус, избранное или дедлайн'));
          return;
        }
      }

      // При обновлении задачи сохраняем текущий ownerUsername
      var taskToUpdate = event.task;
      if (taskToUpdate.ownerUsername == null) {
        final profileDoc = await FirebaseFirestore.instance
            .collection('public_profiles')
            .doc(taskToUpdate.ownerId)
            .get();
        if (profileDoc.exists) {
          final username = profileDoc.data()?['username'] as String? ?? 'Неизвестный';
          taskToUpdate = taskToUpdate.copyWith(ownerUsername: username);
        } else {
          taskToUpdate = taskToUpdate.copyWith(ownerUsername: 'Неизвестный');
        }
      }

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskToUpdate.id)
          .update(taskToUpdate.toMap());
      if (state is TaskLoaded) {
        final currentState = state as TaskLoaded;
        final updatedTasks = currentState.tasks
            .map((task) => task.id == taskToUpdate.id ? taskToUpdate : task)
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