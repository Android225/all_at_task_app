import 'package:all_at_task/config/theme/app_theme.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                        labelText: 'ID пользователя',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.isNotEmpty) {
                          final doc = await FirebaseFirestore.instance.collection('users').doc(value).get();
                          if (doc.exists) {
                            setState(() {
                              _foundUserName = (doc.data() as Map<String, dynamic>)['name'];
                            });
                          } else {
                            setState(() {
                              _foundUserName = null;
                            });
                          }
                        } else {
                          setState(() {
                            _foundUserName = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _foundUserName != null &&
                        _searchController.text != FirebaseAuth.instance.currentUser!.uid
                        ? () {
                      context.read<InvitationBloc>().add(SendFriendRequest(_searchController.text));
                      _searchController.clear();
                      setState(() {
                        _foundUserName = null;
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
              const SizedBox(height: 16),
              const Text(
                'Мои друзья',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvitationBloc, InvitationState>(
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
                        return const Text('Нет друзей');
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
                              if (!snapshot.hasData) return const SizedBox();
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              return Card(
                                child: ListTile(
                                  title: Text(userData['name']),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    return const Text('Ошибка загрузки');
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