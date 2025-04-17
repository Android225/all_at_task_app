import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/bloc/list/list_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ListEditScreen extends StatefulWidget {
  final TaskList? list;

  const ListEditScreen({super.key, this.list});

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _inviteeIdController = TextEditingController();
  Color _selectedColor = const Color(0xFF2196F3);
  List<String> _sharedLists = [];
  List<String> _linkedLists = [];
  String? _inviteeName;

  @override
  void initState() {
    super.initState();
    if (widget.list != null) {
      _nameController.text = widget.list!.name;
      _descriptionController.text = widget.list!.description ?? '';
      _selectedColor = widget.list!.color != null
          ? Color(int.parse(widget.list!.color!, radix: 16))
          : const Color(0xFF2196F3);
      _sharedLists = List.from(widget.list!.sharedLists);
      _linkedLists = List.from(widget.list!.linkedLists);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _inviteeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(widget.list == null ? 'Создание списка' : 'Редактирование списка'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Название списка',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Выберите цвет'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: _selectedColor,
                          onColorChanged: (color) {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('ОК'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Выбрать цвет'),
              ),
              const SizedBox(height: 16),
              BlocBuilder<ListBloc, ListState>(
                builder: (context, state) {
                  print('ListEditScreen ListBloc state: $state');
                  if (state is ListLoaded) {
                    final userId = FirebaseAuth.instance.currentUser!.uid;
                    final availableLists = state.lists
                        .where((l) =>
                    l.id != widget.list?.id &&
                        l.ownerId == userId &&
                        l.name.toLowerCase() != 'основной')
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Подключить списки', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Выберите списки',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: availableLists
                              .map((list) => DropdownMenuItem(
                            value: list.id,
                            child: Text(list.name),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null && !_linkedLists.contains(value)) {
                              setState(() {
                                _linkedLists.add(value);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _linkedLists.map((listId) {
                            final list = availableLists.firstWhere((l) => l.id == listId);
                            return Chip(
                              label: Text(list.name),
                              onDeleted: () {
                                setState(() {
                                  _linkedLists.remove(listId);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Поделиться списками', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: availableLists.map((list) {
                            final isSelected = _sharedLists.contains(list.id);
                            return FilterChip(
                              label: Text(list.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _sharedLists.add(list.id);
                                  } else {
                                    _sharedLists.remove(list.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Добавить участника', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inviteeIdController,
                          decoration: InputDecoration(
                            labelText: 'ID пользователя',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) async {
                            if (value.isNotEmpty) {
                              final doc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(value)
                                  .get();
                              if (doc.exists) {
                                setState(() {
                                  _inviteeName = (doc.data() as Map<String, dynamic>)['name'];
                                });
                              } else {
                                setState(() {
                                  _inviteeName = null;
                                });
                              }
                            } else {
                              setState(() {
                                _inviteeName = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _inviteeName != null
                            ? () {
                          context.read<ListBloc>().add(InviteToList(
                            widget.list?.id ?? '',
                            _inviteeIdController.text,
                          ));
                          _inviteeIdController.clear();
                          setState(() {
                            _inviteeName = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Приглашение отправлено')),
                          );
                        }
                            : null,
                        child: const Text('Пригласить'),
                      ),
                    ],
                  ),
                  if (_inviteeName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Найден: $_inviteeName'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _nameController.text.isEmpty
                    ? null
                    : () {
                  final colorHex = '0x${_selectedColor.value.toRadixString(16).padLeft(8, '0')}';
                  if (widget.list == null) {
                    print('Creating list: name=${_nameController.text}, color=$colorHex');
                    context.read<ListBloc>().add(AddList(
                      _nameController.text,
                      description: _descriptionController.text.isEmpty
                          ? null
                          : _descriptionController.text,
                      color: colorHex,
                      sharedLists: _sharedLists,
                      linkedLists: _linkedLists,
                    ));
                  } else {
                    print('Updating list: id=${widget.list!.id}, name=${_nameController.text}, color=$colorHex');
                    context.read<ListBloc>().add(UpdateList(
                      widget.list!.copyWith(
                        name: _nameController.text,
                        description: _descriptionController.text.isEmpty
                            ? null
                            : _descriptionController.text,
                        color: colorHex,
                        sharedLists: _sharedLists,
                        linkedLists: _linkedLists,
                      ),
                    ));
                  }
                  Navigator.pop(context);
                },
                child: Text(widget.list == null ? 'Создать' : 'Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}