import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';

class SearchResult {
  final String id;
  final String listId;
  final String name;
  final String path;
  final bool isTask;

  SearchResult({
    required this.id,
    required this.listId,
    required this.name,
    required this.path,
    required this.isTask,
  });
}

class ListHomeScreen extends StatefulWidget {
  final String userId;

  const ListHomeScreen({super.key, required this.userId});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  List<Map<String, dynamic>>? _cachedFriends;
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  List<SearchResult> _searchResults = [];
  bool _isSearchVisible = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    print('ListHomeScreen: Loading lists for user ${widget.userId}');
    context.read<ListBloc>().add(LoadLists(userId: widget.userId));
    _searchSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((query) async {
      print('ListHomeScreen: Search query: $query');
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        try {
          final results = await _searchListsAndTasks(query);
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        } catch (e) {
          print('ListHomeScreen: Search error: $e');
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка поиска: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  Future<List<SearchResult>> _searchListsAndTasks(String query) async {
    final lowercaseQuery = query.toLowerCase();
    final results = <SearchResult>[];

    // Получаем списки из ListBloc
    final listState = context.read<ListBloc>().state;
    if (listState is! ListLoaded) return [];

    final lists = listState.lists;
    for (var list in lists) {
      if (list.name.toLowerCase().contains(lowercaseQuery)) {
        results.add(SearchResult(
          id: list.id,
          listId: list.id,
          name: list.name,
          path: '/${list.name}',
          isTask: false,
        ));
      }
    }

    // Поиск задач
    final listIds = lists.map((list) => list.id).toList();
    if (listIds.isEmpty) return results;

    final snapshots = await _getTasksInBatches(listIds);
    for (var snapshot in snapshots) {
      for (var doc in snapshot.docs) {
        final taskData = doc.data() as Map<String, dynamic>?;
        // Проверяем, что taskData не null и содержит необходимые поля
        if (taskData == null) continue;
        final taskTitle = taskData['title'] as String?;
        final listId = taskData['listId'] as String?;
        // Пропускаем, если title или listId отсутствуют
        if (taskTitle == null || listId == null) continue;
        if (taskTitle.toLowerCase().contains(lowercaseQuery)) {
          final list = lists.firstWhere((l) => l.id == listId);
          results.add(SearchResult(
            id: doc.id,
            listId: listId,
            name: taskTitle,
            path: '/${list.name}/$taskTitle',
            isTask: true,
          ));
        }
      }
    }

    return results;
  }

  Future<List<QuerySnapshot>> _getTasksInBatches(List<String> listIds) async {
    const batchSize = 10;
    final batches = <List<String>>[];
    for (var i = 0; i < listIds.length; i += batchSize) {
      batches.add(listIds.sublist(i, i + batchSize > listIds.length ? listIds.length : i + batchSize));
    }

    final firestore = FirebaseFirestore.instance;
    final snapshots = <QuerySnapshot>[];
    for (var batch in batches) {
      final snapshot = await firestore
          .collection('tasks')
          .where('listId', whereIn: batch)
          .get();
      snapshots.add(snapshot);
    }
    return snapshots;
  }

  void _search(String query) {
    _searchSubject.add(query.trim());
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

    Future<List<Map<String, dynamic>>> loadFriends() async {
      if (_cachedFriends != null) {
        return _cachedFriends!;
      }
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isEmpty) {
          throw Exception('User not authenticated');
        }

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
        _cachedFriends = friendProfiles;
        return friendProfiles;
      } catch (e) {
        print('Error loading friends: $e');
        return [];
      }
    }

    Future<List<Map<String, dynamic>>> searchUsers(String query) async {
      try {
        if (query.isEmpty) {
          return [];
        }

        final profilesSnapshot = await FirebaseFirestore.instance
            .collection('public_profiles')
            .get();
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final results = profilesSnapshot.docs
            .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final username = data['username'] as String? ?? '';
          final name = data['name'] as String? ?? '';
          return doc.id != userId &&
              !selectedMemberIds.contains(doc.id) &&
              (username.toLowerCase().contains(query.toLowerCase()) ||
                  name.toLowerCase().contains(query.toLowerCase()));
        })
            .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final isFriend = friends.any((friend) => friend['uid'] == doc.id);
          return {
            'uid': doc.id,
            'username': data['username'] as String,
            'name': data['name'] as String,
            'isFriend': isFriend,
          };
        })
            .toList();
        return results;
      } catch (e) {
        print('Error searching users: $e');
        return [];
      }
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            if (friends.isEmpty && !isSearching) {
              loadFriends().then((loadedFriends) {
                if (!dialogContext.mounted) return;
                setState(() {
                  friends = loadedFriends;
                });
              });
            }

            return AlertDialog(
              title: const Text('Создать список'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
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
                        onChanged: (query) {
                          searchUsers(query).then((results) {
                            if (!dialogContext.mounted) return;
                            setState(() {
                              searchResults = results;
                              isSearching = query.isNotEmpty;
                            });
                          });
                          if (query.isEmpty) {
                            FocusScope.of(dialogContext).unfocus();
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      if (friends.isNotEmpty && !isSearching) ...[
                        const Text(
                          'Друзья',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: friends.map((friend) {
                            return ListTile(
                              title: Text(friend['username']),
                              subtitle: Text(friend['name']),
                              onTap: () {
                                setState(() {
                                  selectedMemberIds.add(friend['uid']);
                                  friends.remove(friend);
                                  searchController.clear();
                                  searchResults.clear();
                                  isSearching = false;
                                  FocusScope.of(dialogContext).unfocus();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      if (isSearching && searchResults.isNotEmpty) ...[
                        const Text(
                          'Результаты поиска',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: searchResults.map((user) {
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
                                  searchResults.remove(user);
                                  friends
                                      .removeWhere((f) => f['uid'] == user['uid']);
                                  searchController.clear();
                                  searchResults.clear();
                                  isSearching = false;
                                  FocusScope.of(dialogContext).unfocus();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (selectedMemberIds.isNotEmpty) ...[
                        const Text(
                          'Выбранные участники',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: selectedMemberIds.map((memberId) {
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
                                if (snapshot.hasError) {
                                  return const ListTile(
                                    title: Text('Ошибка загрузки профиля'),
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
                                        loadFriends().then((loadedFriends) {
                                          if (!dialogContext.mounted) return;
                                          setState(() {
                                            friends = loadedFriends;
                                            searchController.clear();
                                            searchResults.clear();
                                            isSearching = false;
                                            FocusScope.of(dialogContext).unfocus();
                                          });
                                        });
                                      });
                                    },
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
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

                      try {
                        final listBloc = parentContext.read<ListBloc>();
                        listBloc.add(AddList(newList));
                        await listBloc.stream.firstWhere(
                                (state) => state is ListLoaded || state is ListError);

                        final currentState = listBloc.state;
                        if (currentState is ListError) {
                          throw Exception(currentState.message);
                        }

                        if (selectedMemberIds.isNotEmpty) {
                          listBloc
                              .add(AddMembersToList(newList.id, selectedMemberIds));
                          await listBloc.stream.firstWhere(
                                  (state) => state is ListLoaded || state is ListError);

                          final updatedState = listBloc.state;
                          if (updatedState is ListError) {
                            throw Exception(updatedState.message);
                          }
                        }

                        if (connectToMain) {
                          listBloc.add(ConnectListToMain(newList.id, true));
                          await listBloc.stream.firstWhere(
                                  (state) => state is ListLoaded || state is ListError);

                          final finalState = listBloc.state;
                          if (finalState is ListError) {
                            throw Exception(finalState.message);
                          }
                        }

                        if (dialogContext.mounted) {
                          FocusScope.of(dialogContext).unfocus();
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        if (parentContext.mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                                content: Text('Ошибка при создании списка: $e')),
                          );
                        }
                      }
                    } else {
                      if (parentContext.mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Введите название списка')),
                        );
                      }
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
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                _searchController.clear();
                _searchResults = [];
                _isSearching = false;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocConsumer<ListBloc, ListState>(
            listener: (context, state) {
              if (state is ListError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              print('ListHomeScreen: Current state: $state');
              if (_isSearchVisible) {
                return Container(
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.defaultPadding),
                        child: AppTextField(
                          controller: _searchController,
                          labelText: 'Поиск списков и задач',
                          onChanged: _search,
                        ),
                      ),
                      Expanded(
                        child: _isSearching
                            ? const Center(child: CircularProgressIndicator())
                            : _searchResults.isNotEmpty
                            ? ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return Card(
                              child: ListTile(
                                title: Text(result.name),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(result.path),
                                    Text(result.isTask
                                        ? 'Задача'
                                        : 'Список'),
                                  ],
                                ),
                                onTap: () {
                                  print(
                                      'ListHomeScreen: Selected search result: ${result.id}, isTask: ${result.isTask}');
                                  context
                                      .read<ListBloc>()
                                      .add(UpdateListLastUsed(result.listId));
                                  context
                                      .read<ListBloc>()
                                      .add(SelectList(result.listId));
                                  setState(() {
                                    _isSearchVisible = false;
                                    _searchController.clear();
                                    _searchResults = [];
                                  });
                                  Navigator.pushNamed(context, '/home',
                                      arguments: result.listId);
                                },
                              ),
                            );
                          },
                        )
                            : _searchController.text.isNotEmpty
                            ? const Center(child: Text('Ничего не найдено'))
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              }
              if (state is ListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ListLoaded) {
                print('ListHomeScreen: Loaded ${state.lists.length} lists');
                if (state.lists.isEmpty) {
                  return const Center(child: Text('Нет списков'));
                }

                final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                final myLists =
                state.lists.where((list) => list.ownerId == userId).toList();
                final sharedLists = state.lists
                    .where((list) =>
                list.ownerId != userId && list.members.containsKey(userId))
                    .toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (myLists.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.defaultPadding),
                          child: Text(
                            'Мои списки',
                            style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: myLists.length,
                          itemBuilder: (context, index) {
                            final list = myLists[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: list.color != null
                                    ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(list.color!),
                                  ),
                                )
                                    : const Icon(Icons.list),
                                title: Text(
                                  list.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  list.description ?? 'Без описания',
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
                                        context
                                            .read<ListBloc>()
                                            .add(DeleteList(list.id));
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  print('ListHomeScreen: Selecting list: ${list.id}');
                                  context.read<ListBloc>().add(SelectList(list.id));
                                  Navigator.pushNamed(context, '/home',
                                      arguments: list.id);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      if (sharedLists.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.defaultPadding),
                          child: Text(
                            'Списки, где я участник',
                            style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sharedLists.length,
                          itemBuilder: (context, index) {
                            final list = sharedLists[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: list.color != null
                                    ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(list.color!),
                                  ),
                                )
                                    : const Icon(Icons.list),
                                title: Text(
                                  list.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('public_profiles')
                                      .doc(list.ownerId)
                                      .get(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Text('Загрузка владельца...');
                                    }
                                    final ownerData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                    return Text(
                                      'Владелец: ${ownerData['username'] ?? 'Неизвестный'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        print(
                                            'ListHomeScreen: Editing shared list: ${list.id}');
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
                                  ],
                                ),
                                onTap: () {
                                  print(
                                      'ListHomeScreen: Selecting shared list: ${list.id}');
                                  context.read<ListBloc>().add(SelectList(list.id));
                                  Navigator.pushNamed(context, '/home',
                                      arguments: list.id);
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              } else if (state is ListError) {
                print('ListHomeScreen: Error: ${state.message}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Произошла ошибка: ${state.message}'),
                      if (state.message.contains('permission-denied'))
                        const Text(
                          'Проверьте права доступа. Возможно, вам нужно обновить сессию.',
                          style: TextStyle(color: Colors.red),
                        ),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}