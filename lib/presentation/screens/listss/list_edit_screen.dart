import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListEditScreen extends StatefulWidget {
  final TaskList list;

  const ListEditScreen({super.key, required this.list});

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int? _selectedColor;

  static const Map<int, String> colorNames = {
    0xFFFF0000: 'Red',
    0xFF0000FF: 'Blue',
    0xFF00FF00: 'Green',
    0xFFFFFF00: 'Yellow',
  };

  static const List<int> availableColors = [
    0xFFFF0000, // Red
    0xFF0000FF, // Blue
    0xFF00FF00, // Green
    0xFFFFFF00, // Yellow
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.name);
    _descriptionController = TextEditingController(text: widget.list.description);
    _selectedColor = widget.list.color ?? availableColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Редактировать список'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название списка',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedColor,
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
                  _selectedColor = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  final updatedList = widget.list.copyWith(
                    name: _nameController.text,
                    description: _descriptionController.text.isNotEmpty
                        ? _descriptionController.text
                        : null,
                    color: _selectedColor,
                  );
                  context.read<ListBloc>().add(UpdateList(updatedList));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}