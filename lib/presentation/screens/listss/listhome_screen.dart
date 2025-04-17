import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ListHomeScreen extends StatelessWidget {
  const ListHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Мои списки'),
      ),
      body: BlocBuilder<ListBloc, ListState>(
        builder: (context, state) {
          if (state is ListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ListLoaded) {
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
                          context.read<ListBloc>().add(DeleteList(list.id));
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    context.read<ListBloc>().add(SelectList(list.id));
                    Navigator.pushNamed(context, '/home', arguments: list.id);
                  },
                );
              },
            );
          } else if (state is ListError) {
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

  void _showCreateListDialog(BuildContext context) {
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
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final newList = TaskList(
                        id: const Uuid().v4(), // Генерация уникального ID
                        name: nameController.text,
                        ownerId: context.read<ListBloc>().state.userId,
                        description: descriptionController.text.isNotEmpty
                            ? descriptionController.text
                            : null,
                        color: selectedColor ?? 0xFF2196F3,
                        createdAt: DateTime.now(),
                        members: {},
                        sharedLists: [],
                      );
                      context.read<ListBloc>().add(AddList(newList));
                      Navigator.pop(context);
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
}