import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _connectToMain = false;
  bool _isLoadingMainList = true;
  String? _mainListId;

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
    _loadMainList();
  }

  Future<void> _loadMainList() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty || widget.list.name.toLowerCase() == 'основной') {
      setState(() {
        _isLoadingMainList = false;
      });
      return;
    }

    try {
      final mainListSnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('ownerId', isEqualTo: userId)
          .where('name', isEqualTo: 'Основной')
          .get();

      if (mainListSnapshot.docs.isNotEmpty) {
        final mainList = TaskList.fromMap(mainListSnapshot.docs.first.data()
          ..['id'] = mainListSnapshot.docs.first.id);
        _mainListId = mainList.id;
        _connectToMain = mainList.sharedLists.contains(widget.list.id);
      }
    } catch (e) {
      print('ListEditScreen: Error loading main list: $e');
    } finally {
      setState(() {
        _isLoadingMainList = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = widget.list.ownerId == userId;
    final isMainList = widget.list.name.toLowerCase() == 'основной';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Редактировать список'),
      ),
      body: BlocListener<ListBloc, ListState>(
        listener: (context, state) {
          if (state is ListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ListLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Список успешно обновлён')),
            );
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: _isLoadingMainList
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                if (isOwner && !isMainList) ...[
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Подключить к Основному списку'),
                    value: _connectToMain,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        _connectToMain = value ?? false;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                BlocBuilder<ListBloc, ListState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is ListLoading
                          ? null
                          : () {
                        if (_nameController.text.isNotEmpty) {
                          final updatedList = widget.list.copyWith(
                            name: _nameController.text,
                            description:
                            _descriptionController.text.isNotEmpty
                                ? _descriptionController.text
                                : null,
                            color: _selectedColor,
                          );
                          context
                              .read<ListBloc>()
                              .add(UpdateList(updatedList));
                          if (isOwner &&
                              !isMainList &&
                              _mainListId != null) {
                            context.read<ListBloc>().add(
                              ConnectListToMain(
                                widget.list.id,
                                _connectToMain,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state is ListLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text('Сохранить'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}