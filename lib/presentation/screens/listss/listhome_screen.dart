import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ListHomeScreen extends StatefulWidget {
  final String userId;

  const ListHomeScreen({super.key, required this.userId});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  @override
  void initState() {
    super.initState();
    print('ListHomeScreen: Loading lists for user ${widget.userId}');
    context.read<ListBloc>().add(LoadLists(userId: widget.userId));
  }

  void _showCreateListDialog(BuildContext parentContext) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int? selectedColor;

    const colorNames = {
      0xFFFF0000: 'Red',
      0xFF0000FF: 'Blue',
      0xFF00FF00: 'Green',
      0xFFFFFF00: 'Yellow',
    };

    const availableColors = [
      0xFFFF0000, // Red
      0xFF0000FF, // Blue
      0xFF00FF00, // Green
      0xFFFFFF00, // Yellow
    ];

    selectedColor = availableColors[0]; // Цвет по умолчанию

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Создать список'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название списка',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: selectedColor,
                      decoration: const InputDecoration(
                        labelText: 'Цвет',
                        border: OutlineInputBorder(),
                      ),
                      items: availableColors
                          .map((color) => DropdownMenuItem(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              color: Color(color),
                            ),
                            const SizedBox(width: 8),
                            Text(colorNames[color] ?? 'Custom'),
                          ],
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final newList = TaskList(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        ownerId: widget.userId,
                        description: descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                        color: selectedColor ?? 0xFF2196F3,
                        createdAt: DateTime.now(),
                        members: {widget.userId: 'owner'},
                        sharedLists: [],
                      );
                      print('ListHomeScreen: Adding list: ${newList.name}');
                      parentContext.read<ListBloc>().add(AddList(newList));
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Мои списки'),
      ),
      body: BlocBuilder<ListBloc, ListState>(
        builder: (context, state) {
          print('ListHomeScreen: Current state: $state');
          if (state is ListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ListLoaded) {
            print('ListHomeScreen: Loaded ${state.lists.length} lists');
            return ListView.builder(
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                final list = state.lists[index];
                return ListTile(
                  title: Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          print('ListHomeScreen: Editing list: ${list.id}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ListBloc>(),
                                child: ListEditScreen(list: list),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          print('ListHomeScreen: Deleting list: ${list.id}');
                          context.read<ListBloc>().add(DeleteList(list.id));
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    print('ListHomeScreen: Selecting list: ${list.id}');
                    context.read<ListBloc>().add(SelectList(list.id));
                    Navigator.pushNamed(context, '/home', arguments: list.id);
                  },
                );
              },
            );
          } else if (state is ListError) {
            print('ListHomeScreen: Error: ${state.message}');
            return Center(child: Text('Ошибка: ${state.message}'));
          }
          return const Center(child: Text('Нет списков'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}