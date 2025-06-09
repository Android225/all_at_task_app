import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    final taskBloc = context.read<TaskBloc>();
    // Убеждаемся, что задачи загружаются при открытии экрана
    if (taskBloc.state is! TaskLoaded) {
      taskBloc.add(const LoadFavoriteTasks());
    } else {
      // Перезагружаем, чтобы гарантировать актуальные данные
      taskBloc.add(const LoadFavoriteTasks());
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Избранные задачи'),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TaskBloc>().add(const LoadFavoriteTasks()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is TaskLoaded) {
            final favoriteTasks = state.tasks.where((task) => task.isFavorite && task.ownerId == userId).toList();
            print('FavoritesScreen: Found ${favoriteTasks.length} favorite tasks for user $userId');
            if (favoriteTasks.isEmpty) {
              return const Center(child: Text('Нет избранных задач'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<TaskBloc>().add(const LoadFavoriteTasks());
              },
              child: ListView.builder(
                itemCount: favoriteTasks.length,
                itemBuilder: (context, index) {
                  final task = favoriteTasks[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Slidable(
                      key: Key(task.id),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) {
                              print('FavoritesScreen: Toggling favorite for task: ${task.id}');
                              context.read<TaskBloc>().add(
                                  UpdateTask(task.copyWith(isFavorite: !task.isFavorite)));
                            },
                            backgroundColor: Colors.yellow,
                            foregroundColor: Colors.white,
                            icon: Icons.star,
                            label: 'Избранное',
                          ),
                          SlidableAction(
                            onPressed: (_) async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: task.deadline?.toDate() ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (date != null) {
                                print('FavoritesScreen: Updating deadline for task: ${task.id}');
                                context.read<TaskBloc>().add(
                                    UpdateTask(task.copyWith(deadline: Timestamp.fromDate(date))));
                              }
                            },
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.calendar_today,
                            label: 'Дедлайн',
                          ),
                          SlidableAction(
                            onPressed: (_) {
                              print('FavoritesScreen: Deleting task: ${task.id}');
                              context.read<TaskBloc>().add(DeleteTask(task.id, task.listId));
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Удалить',
                          ),
                        ],
                      ),
                      child: Card(
                        elevation: 2,
                        color: task.isCompleted ? Colors.grey[300] : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (value) {
                                  print('FavoritesScreen: Updating completion for task: ${task.id}');
                                  context.read<TaskBloc>().add(
                                      UpdateTask(task.copyWith(isCompleted: value ?? false)));
                                },
                              ),
                              const CircleAvatar(
                                backgroundImage: AssetImage('assets/images/cat1.jpg'),
                              ),
                            ],
                          ),
                          title: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.ownerId == userId ? 'Вы' : task.ownerUsername ?? 'Неизвестный'),
                              if (task.priority != null) Text('Приоритет: ${task.priority}'),
                              if (task.deadline != null)
                                Text(
                                  'Дедлайн: ${DateFormat('dd.MM.yyyy').format(task.deadline!.toDate())}',
                                ),
                            ],
                          ),
                          trailing: Text(
                            task.deadline != null
                                ? DateFormat('dd.MM').format(task.deadline!.toDate())
                                : '',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const Center(child: Text('Нет данных'));
        },
      ),
    );
  }
}