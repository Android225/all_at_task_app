import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      return;
    }

    // Загружаем все списки пользователя
    final userListsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .get();
    final listIds = userListsSnapshot.docs
        .map((doc) => doc.data()['listId'] as String)
        .toList();

    if (listIds.isEmpty) {
      return;
    }

    // Загружаем задачи из всех списков
    final tasks = <Task>[];
    const batchSize = 10;
    for (var i = 0; i < listIds.length; i += batchSize) {
      final batchIds = listIds.sublist(
          i, i + batchSize > listIds.length ? listIds.length : i + batchSize);
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('listId', whereIn: batchIds)
          .get();

      for (var doc in tasksSnapshot.docs) {
        final data = doc.data()..['id'] = doc.id;
        var task = Task.fromMap(data);
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
    }

    setState(() {
      _allTasks = tasks;
    });
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      if (task.deadline == null) return false;
      final taskDate = task.deadline!.toDate();
      return taskDate.year == day.year &&
          taskDate.month == day.month &&
          taskDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не авторизован')),
      );
    }

    return BlocProvider(
      create: (_) => getIt<TaskBloc>(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Календарь'),
        ),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: (day) => _getTasksForDay(day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const Divider(),
            Expanded(
              child: _buildTasksForSelectedDay(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksForSelectedDay(BuildContext context) {
    final tasks = _getTasksForDay(_selectedDay!);
    if (tasks.isEmpty) {
      return const Center(child: Text('Нет задач на эту дату'));
    }

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    context.read<TaskBloc>().add(
                      UpdateTask(task.copyWith(isCompleted: value ?? false)),
                    );
                  },
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.ownerUsername ?? 'Неизвестный'),
                    if (task.priority != null) Text('Приоритет: ${task.priority}'),
                    if (task.deadline != null)
                      Text(
                        'Дедлайн: ${DateFormat('dd.MM.yyyy').format(task.deadline!.toDate())}',
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}