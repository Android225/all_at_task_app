import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:all_at_task/presentation/widgets/app_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    GetIt.instance<InvitationBloc>().add(LoadInvitations());
    _searchSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((query) async {
      print('Search query: $query');
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
        });
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('public_profiles')
              .where('username', isGreaterThanOrEqualTo: query)
              .limit(10)
              .get();
          final filteredDocs = snapshot.docs.where((doc) {
            final username = (doc.data() as Map<String, dynamic>)['username'] as String;
            return username.toLowerCase().contains(query.toLowerCase());
          }).toList();
          print('Search results: ${filteredDocs.length} users found after filtering');
          setState(() {
            _searchResults = filteredDocs;
            _isSearching = false;
          });
        } catch (e) {
          print('Search error: $e');
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

  void _searchUser(String query) {
    _searchSubject.add(query.trim());
  }

  void _sendFriendRequest(String userId, String username) {
    print('Sending friend request to userId: $userId, username: $username');
    final invitationBloc = GetIt.instance<InvitationBloc>();
    invitationBloc.add(SendFriendRequest(userId));
    print('Friend request event sent to InvitationBloc');
  }

  void _removeFriend(String requestId, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить друга'),
        content: Text('Вы точно хотите удалить $username из друзей?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              GetIt.instance<InvitationBloc>().add(RemoveFriend(requestId));
              Navigator.pop(context);
            },
            child: const Text('Да'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Друзья'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  BlocListener<InvitationBloc, InvitationState>(
                    bloc: GetIt.instance<InvitationBloc>(),
                    listener: (context, state) {
                      if (state is InvitationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      } else if (state is InvitationError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: AppTextField(
                      controller: _searchController,
                      labelText: 'Поиск пользователей',
                      onChanged: _searchUser,
                    ),
                  ),
                  const SizedBox(height: AppTheme.defaultPadding),
                  if (_isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (_searchResults.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final userData = _searchResults[index].data() as Map<String, dynamic>;
                          final userId = _searchResults[index].id;
                          final username = userData['username'] as String;
                          final name = userData['name'] as String;
                          return ListTile(
                            title: Text(username),
                            subtitle: Text(name),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add),
                              onPressed: () => _sendFriendRequest(userId, username),
                            ),
                          );
                        },
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                      const Center(child: Text('Пользователи не найдены')),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: BlocBuilder<InvitationBloc, InvitationState>(
                bloc: GetIt.instance<InvitationBloc>(),
                builder: (context, state) {
                  if (state is InvitationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is InvitationLoaded) {
                    final friends = state.acceptedFriends; // Уже отфильтрованы
                    if (friends.isEmpty) {
                      return const Center(child: Text('Нет друзей'));
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final friendId = friend.userId1 == GetIt.instance<InvitationBloc>().currentUserId
                            ? friend.userId2
                            : friend.userId1;
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('public_profiles')
                              .doc(friendId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const ListTile(
                                title: Text('Загрузка...'),
                              );
                            }
                            final friendData = snapshot.data!.data() as Map<String, dynamic>;
                            final username = friendData['username'] as String;
                            final name = friendData['name'] as String;
                            return ListTile(
                              title: Text(username),
                              subtitle: Text(name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeFriend(friend.id, username),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else if (state is InvitationError) {
                    return Center(child: Text('Ошибка: ${state.message}'));
                  }
                  return const Center(child: Text('Нет друзей'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}