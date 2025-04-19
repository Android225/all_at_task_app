import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';

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
    final searchController = TextEditingController();
    int? selectedColor;
    bool connectToMain = false;
    List<Map<String, dynamic>> friends = [];
    List<Map<String, dynamic>> searchResults = [];
    List<String> selectedMemberIds = [];
    bool isSearching = false;

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

    // Загрузка списка друзей
    void loadFriends() async {
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

    // Поиск пользователей
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

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            if (friends.isEmpty && !isSearching) {
              loadFriends();
            }

            return AlertDialog(
              title: const Text('Создать список'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7, // Ограничиваем высоту диалога
                  maxWidth: MediaQuery.of(context).size.width * 0.9,   // Ограничиваем ширину диалога
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Подключить к Основному списку'),
                        value: connectToMain,
                        onChanged: (value) {
                          setState(() {
                            connectToMain = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Добавить участников',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      AppTextField(
                        controller: searchController,
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
                            shrinkWrap: true, // Указываем, что ListView должен сжиматься
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                    searchController.clear();
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
                            shrinkWrap: true, // Указываем, что ListView должен сжиматься
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                    friends
                                        .removeWhere((f) => f['uid'] == user['uid']);
                                    searchController.clear();
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
                          'Выбранные участники',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            shrinkWrap: true, // Указываем, что ListView должен сжиматься
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                  final userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                                  return ListTile(
                                    title: Text(userData['username'] as String),
                                    subtitle: Text(userData['name'] as String),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          selectedMemberIds.remove(memberId);
                                          loadFriends();
                                          searchController.clear();
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
                  ),
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
                        color: selectedColor,
                        createdAt: DateTime.now(),
                        lastUsed: null,
                        members: {widget.userId: 'admin'},
                        sharedLists: [],
                      );
                      print('ListHomeScreen: Adding list: ${newList.name}');
                      parentContext.read<ListBloc>().add(AddList(newList));
                      if (selectedMemberIds.isNotEmpty) {
                        parentContext
                            .read<ListBloc>()
                            .add(AddMembersToList(newList.id, selectedMemberIds));
                      }
                      if (connectToMain) {
                        parentContext
                            .read<ListBloc>()
                            .add(ConnectListToMain(newList.id, true));
                      }
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
            if (state.lists.isEmpty) {
              return const Center(child: Text('Нет списков'));
            }
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<ListBloc>()
                        .add(LoadLists(userId: widget.userId)),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
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