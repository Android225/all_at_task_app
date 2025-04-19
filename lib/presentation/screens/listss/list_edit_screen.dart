import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';

class ListEditScreen extends StatefulWidget {
  final TaskList list;

  const ListEditScreen({super.key, required this.list});

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _searchController;
  int? _selectedColor;
  bool _connectToMain = false;
  bool _isLoadingMainList = true;
  String? _mainListId;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> searchResults = [];
  List<String> selectedMemberIds = [];
  bool isSearching = false;

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
    _searchController = TextEditingController();
    _selectedColor = widget.list.color != null && availableColors.contains(widget.list.color)
        ? widget.list.color
        : availableColors[0];
    _loadMainList();
    selectedMemberIds = widget.list.members.keys
        .where((key) => key != widget.list.ownerId)
        .toList();
    loadFriends();
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

  Future<void> loadFriends() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final acceptedFriendsSnapshot1 = await FirebaseFirestore.instance
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .where('userId1', isEqualTo: userId)
        .get();
    final acceptedFriendsSnapshot2 = await FirebaseFirestore.instance
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .where('userId2', isEqualTo: userId)
        .get();

    final friendIds = <String>{};
    for (var doc in acceptedFriendsSnapshot1.docs) {
      friendIds.add(doc.data()['userId2'] as String);
    }
    for (var doc in acceptedFriendsSnapshot2.docs) {
      friendIds.add(doc.data()['userId1'] as String);
    }

    final friendProfiles = <Map<String, dynamic>>[];
    for (var friendId in friendIds) {
      if (friendId != userId && !selectedMemberIds.contains(friendId)) {
        final profileDoc = await FirebaseFirestore.instance
            .collection('public_profiles')
            .doc(friendId)
            .get();
        if (profileDoc.exists) {
          friendProfiles.add({
            'uid': friendId,
            'username': profileDoc.data()!['username'] as String,
            'name': profileDoc.data()!['name'] as String,
            'isFriend': true,
          });
        }
      }
    }
    setState(() {
      friends = friendProfiles;
    });
  }

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    final profilesSnapshot = await FirebaseFirestore.instance
        .collection('public_profiles')
        .get();
    final results = profilesSnapshot.docs
        .where((doc) {
      final data = doc.data();
      final username = data['username'] as String? ?? '';
      final name = data['name'] as String? ?? '';
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      return doc.id != userId &&
          !selectedMemberIds.contains(doc.id) &&
          (username.toLowerCase().contains(query.toLowerCase()) ||
              name.toLowerCase().contains(query.toLowerCase()));
    })
        .map((doc) {
      final isFriend = friends.any((friend) => friend['uid'] == doc.id);
      return {
        'uid': doc.id,
        'username': doc.data()['username'] as String,
        'name': doc.data()['name'] as String,
        'isFriend': isFriend,
      };
    })
        .toList();

    setState(() {
      searchResults = results;
      isSearching = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
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
        child: _isLoadingMainList
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название списка',
                  border: OutlineInputBorder(),
                ),
                enabled: isOwner,
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                enabled: isOwner,
                maxLines: 3,
                onChanged: (value) => setState(() {}),
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
                onChanged: isOwner
                    ? (value) {
                  print('ListEditScreen: Selected color: $value');
                  setState(() {
                    _selectedColor = value;
                  });
                }
                    : null,
              ),
              const SizedBox(height: 16),
              if (!isMainList) ...[
                SwitchListTile(
                  title: const Text('Подключить к Основному списку'),
                  value: _connectToMain,
                  onChanged: (value) {
                    setState(() {
                      _connectToMain = value;
                    });
                  },
                ),
              ],
              if (isOwner) ...[
                const SizedBox(height: 16),
                const Text(
                  'Добавить участников',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                AppTextField(
                  controller: _searchController,
                  labelText: 'Поиск пользователей',
                  onChanged: searchUsers,
                ),
                const SizedBox(height: 8),
                if (friends.isNotEmpty && !isSearching) ...[
                  const Text(
                    'Друзья',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          title: Text(friend['username']),
                          subtitle: Text(friend['name']),
                          onTap: () {
                            setState(() {
                              selectedMemberIds.add(friend['uid']);
                              friends.removeAt(index);
                              _searchController.clear();
                              searchResults = [];
                              isSearching = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (isSearching && searchResults.isNotEmpty) ...[
                  const Text(
                    'Результаты поиска',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          title: Text(user['username']),
                          subtitle: Text(user['name']),
                          trailing: user['isFriend']
                              ? const Text(
                            'Друг',
                            style: TextStyle(color: Colors.green),
                          )
                              : null,
                          onTap: () {
                            setState(() {
                              selectedMemberIds.add(user['uid']);
                              searchResults.removeAt(index);
                              friends.removeWhere(
                                      (f) => f['uid'] == user['uid']);
                              _searchController.clear();
                              searchResults = [];
                              isSearching = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (selectedMemberIds.isNotEmpty) ...[
                  const Text(
                    'Участники',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: selectedMemberIds.length,
                      itemBuilder: (context, index) {
                        final memberId = selectedMemberIds[index];
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('public_profiles')
                              .doc(memberId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(
                                title: Text('Загрузка...'),
                              );
                            }
                            final userData = snapshot.data!.data()
                            as Map<String, dynamic>;
                            return ListTile(
                              title: Text(userData['username'] as String),
                              subtitle: Text(userData['name'] as String),
                              trailing: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    selectedMemberIds.remove(memberId);
                                    loadFriends();
                                    _searchController.clear();
                                    searchResults = [];
                                    isSearching = false;
                                  });
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              BlocBuilder<ListBloc, ListState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state is ListLoading ||
                        (_nameController.text.isEmpty && isOwner)
                        ? null
                        : () {
                      final updatedMembers = Map<String, String>.from(
                          widget.list.members);
                      for (var memberId in selectedMemberIds) {
                        if (!updatedMembers.containsKey(memberId)) {
                          updatedMembers[memberId] = 'viewer';
                        }
                      }
                      updatedMembers[userId] = 'admin';
                      final updatedList = widget.list.copyWith(
                        name: _nameController.text,
                        description:
                        _descriptionController.text.isNotEmpty
                            ? _descriptionController.text
                            : null,
                        color: _selectedColor,
                        members: updatedMembers,
                      );
                      context
                          .read<ListBloc>()
                          .add(UpdateList(updatedList));
                      final newMembers = selectedMemberIds
                          .where((id) => !widget.list.members
                          .containsKey(id))
                          .toList();
                      if (newMembers.isNotEmpty) {
                        context.read<ListBloc>().add(
                            AddMembersToList(
                                updatedList.id, newMembers));
                      }
                      if (!isMainList && _mainListId != null) {
                        context.read<ListBloc>().add(
                            ConnectListToMain(
                                widget.list.id, _connectToMain));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state is ListLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      'Сохранить',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}