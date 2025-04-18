import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/friend_request.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String? _foundUserName;
  String? _foundUserId;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUser(String query) async {
    if (query.isEmpty) {
      setState(() {
        _foundUserName = null;
        _foundUserId = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _foundUserName = null;
      _foundUserId = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: query)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data();
        setState(() {
          _foundUserName = userData['name'];
          _foundUserId = snapshot.docs.first.id;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка поиска: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _removeFriend(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('friends').doc(requestId).delete();
      context.read<InvitationBloc>().add(LoadInvitations());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Друг удален')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления друга: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InvitationBloc>()..add(LoadInvitations()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Друзья'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Поиск по имени пользователя',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _isSearching
                            ? const CircularProgressIndicator()
                            : null,
                      ),
                      onChanged: _searchUser,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _foundUserId != null &&
                        _foundUserId != FirebaseAuth.instance.currentUser!.uid
                        ? () {
                      context
                          .read<InvitationBloc>()
                          .add(SendFriendRequest(_foundUserId!));
                      _searchController.clear();
                      setState(() {
                        _foundUserName = null;
                        _foundUserId = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Запрос отправлен')),
                      );
                    }
                        : null,
                    child: const Text('Добавить'),
                  ),
                ],
              ),
              if (_foundUserName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Найден: $_foundUserName'),
                ),
              if (_foundUserName == null && _searchController.text.isNotEmpty && !_isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Пользователь не найден', style: TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              const Text(
                'Мои друзья',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocConsumer<InvitationBloc, InvitationState>(
                  listener: (context, state) {
                    if (state is InvitationError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is InvitationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InvitationLoaded) {
                      final friends = state.friendRequests
                          .where((req) =>
                      req.status == 'accepted' &&
                          (req.userId1 == FirebaseAuth.instance.currentUser!.uid ||
                              req.userId2 == FirebaseAuth.instance.currentUser!.uid))
                          .toList();
                      if (friends.isEmpty) {
                        return const Center(child: Text('Нет друзей'));
                      }
                      return ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final friendId = friend.userId1 == FirebaseAuth.instance.currentUser!.uid
                              ? friend.userId2
                              : friend.userId1;
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ListTile(
                                  title: Text('Загрузка...'),
                                  trailing: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return const ListTile(title: Text('Ошибка загрузки'));
                              }
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  title: Text(userData['name'] ?? 'Без имени'),
                                  subtitle: Text(userData['email'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeFriend(friend.id),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    return const Center(child: Text('Ошибка загрузки'));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}