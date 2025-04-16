import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/listhome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    // Запускаем авто-выбор "Основной" после загрузки списков
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listBloc = context.read<ListBloc>();
      if (listBloc.state is ListLoaded) {
        final state = listBloc.state as ListLoaded;
        if (state.lists.isNotEmpty && state.selectedListId == null) {
          final mainList = state.lists.firstWhere(
                (list) => list.name.toLowerCase().contains('основной'),
            orElse: () => state.lists.first,
          );
          listBloc.add(SelectList(mainList.id));
          context.read<TaskBloc>().add(LoadTasks(mainList.id));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskBottomSheet(BuildContext scaffoldContext, String listId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    String selectedPriority = 'medium';

    showModalBottomSheet(
      context: scaffoldContext,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: AppTheme.defaultPadding,
            right: AppTheme.defaultPadding,
            top: AppTheme.defaultPadding,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Новая задача',
                  style: Theme.of(bottomSheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Приоритет'),
                  items: ['low', 'medium', 'high']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPriority = value ?? 'medium'),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: bottomSheetContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Выбрать дату'
                        : DateFormat('dd.MM.yyyy').format(selectedDate!),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      scaffoldContext.read<TaskBloc>().add(AddTask(
                        title: titleController.text,
                        description: descriptionController.text,
                        deadline: selectedDate,
                        listId: listId,
                        priority: selectedPriority,
                      ));
                      Navigator.pop(bottomSheetContext);
                    }
                  },
                  child: const Text('Создать'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TaskBloc>()),
        BlocProvider(create: (_) => getIt<ListBloc>()..add(LoadLists())),
      ],
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: BlocBuilder<ListBloc, ListState>(
              builder: (context, state) {
                if (state is ListLoaded) {
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.lists.length,
                      itemBuilder: (context, index) {
                        final list = state.lists[index];
                        final isSelected = list.id == state.selectedListId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              context.read<ListBloc>().add(SelectList(list.id));
                              context.read<TaskBloc>().add(LoadTasks(list.id));
                            },
                            child: Chip(
                              label: Text(list.name),
                              backgroundColor: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.7)
                                  : Colors.grey[300],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            actions: [
              IconButton(
                icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearchVisible = !_isSearchVisible;
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: AppTheme.primaryColor),
                  child: Text(
                    'Меню',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                ListTile(
                  title: const Text('Профиль'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Друзья'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Избранное'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Настройки'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Приглашения'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              BlocBuilder<TaskBloc, TaskState>(
                builder: (context, state) {
                  if (state is TaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaskLoaded) {
                    return ListView.builder(
                      itemCount: state.tasks.length,
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Slidable(
                            key: Key(task.id),
                            startActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) {
                                    context.read<TaskBloc>().add(UpdateTask(
                                      task.copyWith(isFavorite: !task.isFavorite),
                                    ));
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
                                      context.read<TaskBloc>().add(UpdateTask(
                                        task.copyWith(deadline: Timestamp.fromDate(date)),
                                      ));
                                    }
                                  },
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.calendar_today,
                                  label: 'Дедлайн',
                                ),
                                SlidableAction(
                                  onPressed: (_) {
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
                                        context.read<TaskBloc>().add(UpdateTask(
                                          task.copyWith(isCompleted: value ?? false),
                                        ));
                                      },
                                    ),
                                    const CircleAvatar(
                                      backgroundImage: AssetImage('assets/cat.png'),
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
                                    Text(task.ownerId == state.userId ? 'Вы' : 'Другой'),
                                    if (task.priority != null) Text('Приоритет: ${task.priority}'),
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
                    );
                  } else if (state is TaskError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text('Выберите список'));
                },
              ),
              if (_isSearchVisible)
                Container(
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.defaultPadding),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Поиск задач',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: Builder(
            builder: (navContext) => BottomNavigationBar(
              backgroundColor: AppTheme.primaryColor,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white70,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Списки',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: 'Задача',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Календарь',
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    navContext,
                    MaterialPageRoute(builder: (_) => const ListHomeScreen()),
                  );
                } else if (index == 1) {
                  final state = navContext.read<ListBloc>().state;
                  if (state is ListLoaded && state.lists.isNotEmpty) {
                    final listId = state.selectedListId ?? state.lists.first.id;
                    _showAddTaskBottomSheet(navContext, listId);
                  } else {
                    ScaffoldMessenger.of(navContext).showSnackBar(
                      const SnackBar(content: Text('Сначала создайте или выберите список')),
                    );
                  }
                } else if (index == 2) {
                  // Заглушка для calendar_screen
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}