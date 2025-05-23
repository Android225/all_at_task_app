import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/list/list_state.dart';
import 'package:all_at_task/presentation/bloc/task/task_bloc.dart';
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
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSearchVisible = false;
  DateTime? _selectedDate;
  String _selectedPriority = 'medium';
  bool _isInitialSelectionDone = false;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskBottomSheet(BuildContext scaffoldContext, String listId) {
    _titleController.clear();
    _descriptionController.clear();
    _selectedDate = null;
    _selectedPriority = 'medium';

    showModalBottomSheet(
      context: scaffoldContext,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter bottomSheetSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
                left: AppTheme.defaultPadding * 1.5,
                right: AppTheme.defaultPadding * 1.5,
                top: AppTheme.defaultPadding * 2,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Новая задача',
                      style: Theme.of(bottomSheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Название',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) => bottomSheetSetState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      maxLines: 3,
                      onChanged: (value) => bottomSheetSetState(() {}),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Приоритет',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('low')),
                        DropdownMenuItem(value: 'medium', child: Text('medium')),
                        DropdownMenuItem(value: 'high', child: Text('high')),
                      ],
                      onChanged: (value) {
                        bottomSheetSetState(() {
                          _selectedPriority = value ?? 'medium';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: bottomSheetContext,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          bottomSheetSetState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? 'Выбрать дату'
                            : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _titleController.text.isEmpty
                          ? null
                          : () {
                        print('Adding task: title=${_titleController.text}, listId=$listId, deadline=$_selectedDate');
                        scaffoldContext.read<TaskBloc>().add(AddTask(
                          title: _titleController.text,
                          description: _descriptionController.text.isEmpty
                              ? null
                              : _descriptionController.text,
                          deadline: _selectedDate != null
                              ? Timestamp.fromDate(_selectedDate!)
                              : null,
                          listId: listId,
                          priority: _selectedPriority,
                        ));
                        Navigator.pop(bottomSheetContext);
                      },
                      child: const Text(
                        'Создать',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? selectedListId = ModalRoute.of(context)?.settings.arguments as String?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<TaskBloc>()),
        BlocProvider(create: (context) => getIt<ListBloc>()..add(LoadLists())),
      ],
      child: PopScope(
        canPop: false,
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
                print('HomeScreen AppBar ListBloc state: $state');
                if (state is ListLoaded) {
                  print('HomeScreen AppBar lists: ${state.lists.map((l) => l.name).toList()}');
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.lists.length,
                      itemBuilder: (context, index) {
                        final list = state.lists[index];
                        final isSelected = list.id == (selectedListId ?? state.selectedListId);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              context.read<ListBloc>().add(UpdateListLastUsed(list.id));
                              context.read<ListBloc>().add(SelectList(list.id));
                              context.read<TaskBloc>().add(LoadTasks(list.id));
                            },
                            child: Chip(
                              label: Text(list.name),
                              avatar: list.name.toLowerCase() == 'основной'
                                  ? const Icon(Icons.star, color: Colors.yellow)
                                  : null,
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
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                ListTile(
                  title: const Text('Друзья'),
                  onTap: () => Navigator.pushNamed(context, '/friends'),
                ),
                ListTile(
                  title: const Text('Приглашения'),
                  onTap: () => Navigator.pushNamed(context, '/invitations'),
                ),
                ListTile(
                  title: const Text('Настройки'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              MultiBlocListener(
                listeners: [
                  BlocListener<AuthBloc, AuthState>(
                    listener: (context, state) {
                      print('HomeScreen AuthBloc state: $state');
                      if (state is AuthSuccess && !_isInitialSelectionDone) {
                        context.read<ListBloc>().add(LoadLists());
                      }
                    },
                  ),
                  BlocListener<ListBloc, ListState>(
                    listener: (context, state) {
                      print('HomeScreen ListBloc listener state: $state');
                      if (state is ListLoaded && state.lists.isNotEmpty && !_isInitialSelectionDone) {
                        final mainList = state.lists.firstWhere(
                              (list) => list.name.toLowerCase().trim() == 'основной',
                          orElse: () => state.lists.first,
                        );
                        if (selectedListId == null) {
                          context.read<ListBloc>().add(SelectList(mainList.id));
                          context.read<TaskBloc>().add(LoadTasks(mainList.id));
                          print('HomeScreen: Автоматический выбор основного списка: ${mainList.id}');
                        }
                        _isInitialSelectionDone = true;
                      }
                    },
                  ),
                  BlocListener<TaskBloc, TaskState>(
                    listener: (context, state) {
                      print('HomeScreen TaskBloc state: $state');
                      if (state is TaskLoaded) {
                        print('HomeScreen: Tasks loaded: ${state.tasks.map((t) => t.title).toList()}');
                      } else if (state is TaskError) {
                        print('HomeScreen: Task error: ${state.message}');
                      }
                    },
                  ),
                ],
                child: BlocBuilder<ListBloc, ListState>(
                  builder: (context, listState) {
                    print('HomeScreen ListBloc builder state: $listState');
                    return BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, taskState) {
                        print('HomeScreen TaskBloc builder state: $taskState');
                        if (_isSearchVisible && _searchController.text.isNotEmpty) {
                          context.read<ListBloc>().add(SearchListsAndTasks(_searchController.text));
                          return BlocBuilder<ListBloc, ListState>(
                            builder: (context, searchState) {
                              print('HomeScreen Search ListBloc state: $searchState');
                              if (searchState is ListSearchResults) {
                                final results = [...searchState.listResults, ...searchState.taskResults];
                                return ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final result = results[index];
                                    if (result is TaskList) {
                                      return ListTile(
                                        title: Text(result.name),
                                        subtitle: Text('${result.name}/'),
                                        onTap: () {
                                          context.read<ListBloc>().add(UpdateListLastUsed(result.id));
                                          context.read<ListBloc>().add(SelectList(result.id));
                                          context.read<TaskBloc>().add(LoadTasks(result.id));
                                          setState(() {
                                            _isSearchVisible = false;
                                            _searchController.clear();
                                          });
                                        },
                                      );
                                    } else if (result is Task) {
                                      final list = searchState.allLists.firstWhere(
                                            (l) => l.id == result.listId,
                                        orElse: () => TaskList(
                                          id: '',
                                          name: 'Неизвестный список',
                                          ownerId: '',
                                          members: {},
                                          sharedLists: [],
                                          linkedLists: [],
                                          createdAt: null,
                                        ),
                                      );
                                      return ListTile(
                                        title: Text(result.title),
                                        subtitle: Text('${list.name}/${result.title}'),
                                        onTap: () {
                                          context.read<ListBloc>().add(UpdateListLastUsed(result.listId));
                                          context.read<ListBloc>().add(SelectList(result.listId));
                                          context.read<TaskBloc>().add(LoadTasks(result.listId));
                                          setState(() {
                                            _isSearchVisible = false;
                                            _searchController.clear();
                                          });
                                        },
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                );
                              }
                              return const SizedBox();
                            },
                          );
                        }
                        if (taskState is TaskLoading || listState is ListLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (listState is ListLoaded && listState.lists.isNotEmpty) {
                          if (taskState is TaskLoaded) {
                            final isMainList = listState.selectedListId != null &&
                                listState.lists
                                    .firstWhere((l) => l.id == listState.selectedListId!)
                                    .name
                                    .toLowerCase() ==
                                    'основной';
                            final displayTasks = isMainList
                                ? taskState.tasks
                                .where((task) => listState.lists.any((list) => list.id == task.listId))
                                .toList()
                                : taskState.tasks;
                            return RefreshIndicator(
                              onRefresh: () async {
                                if (listState.selectedListId != null) {
                                  context.read<TaskBloc>().add(LoadTasks(listState.selectedListId!));
                                }
                              },
                              child: displayTasks.isEmpty
                                  ? const Center(child: Text('Нет задач'))
                                  : ListView.builder(
                                itemCount: displayTasks.length,
                                itemBuilder: (context, index) {
                                  final task = displayTasks[index];
                                  final taskList = isMainList
                                      ? listState.lists.firstWhere((l) => l.id == task.listId)
                                      : null;
                                  return Slidable(
                                    key: ValueKey(task.id),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      children: [
                                        CustomSlidableAction(
                                          onPressed: (context) {
                                            context.read<TaskBloc>().add(UpdateTask(
                                              task.copyWith(isFavorite: !task.isFavorite),
                                            ));
                                          },
                                          backgroundColor: Colors.yellow,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.star, color: Colors.white),
                                              Text('Избранное', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        CustomSlidableAction(
                                          onPressed: (slidableContext) async {
                                            final date = await showDatePicker(
                                              context: slidableContext,
                                              initialDate: task.deadline?.toDate() ?? DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime(2030),
                                            );
                                            if (date != null) {
                                              slidableContext.read<TaskBloc>().add(UpdateTask(
                                                task.copyWith(deadline: Timestamp.fromDate(date)),
                                              ));
                                            }
                                          },
                                          backgroundColor: Colors.blue,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.calendar_today, color: Colors.white),
                                              Text('Дедлайн', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        CustomSlidableAction(
                                          onPressed: (context) {
                                            context.read<TaskBloc>().add(
                                              DeleteTask(task.id, task.listId),
                                            );
                                          },
                                          backgroundColor: Colors.red,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.delete, color: Colors.white),
                                              Text('Удалить', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
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
                                            if (isMainList && taskList != null)
                                              Text('Список: ${taskList.name}'),
                                            Text(task.ownerId == taskState.userId ? 'Вы' : 'Другой'),
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
                                  );
                                },
                              ),
                            );
                          } else if (taskState is TaskError) {
                            return Center(child: Text(taskState.message));
                          } else {
                            return const Center(child: Text('Ожидание загрузки задач'));
                          }
                        }
                        return const Center(child: Text('Нет доступных списков'));
                      },
                    );
                  },
                ),
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
                            labelText: 'Поиск задач и списков',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            context.read<ListBloc>().add(SearchListsAndTasks(value));
                          },
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
                  Navigator.pushNamed(navContext, '/lists_home');
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
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}