import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/friend_request.dart';
import 'package:all_at_task/data/models/invitation.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InvitationBloc>()..add(LoadInvitations()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Приглашения'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: BlocConsumer<InvitationBloc, InvitationState>(
            listener: (context, state) {
              if (state is InvitationError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is InvitationLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Список приглашений обновлен')),
                );
              }
            },
            builder: (context, state) {
              if (state is InvitationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InvitationLoaded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Запросы в друзья',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildFriendRequests(context, state.friendRequests),
                    ),
                    const Divider(),
                    const Text(
                      'Приглашения в списки',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildListInvitations(context, state.invitations),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Ошибка загрузки'));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequests(BuildContext context, List<FriendRequest> friendRequests) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final pendingRequests = friendRequests
        .where((req) => req.status == 'pending' && req.userId2 == currentUserId)
        .toList();

    if (pendingRequests.isEmpty) {
      return const Center(child: Text('Нет запросов в друзья'));
    }

    return ListView.builder(
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        final request = pendingRequests[index];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(request.userId1).get(),
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
                title: Text('Запрос от ${userData['name']}'),
                subtitle: Text(userData['email'] ?? 'Нет email'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () {
                        context.read<InvitationBloc>().add(AcceptFriendRequest(request.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Запрос от ${userData['name']} принят')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        context.read<InvitationBloc>().add(RejectFriendRequest(request.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Запрос от ${userData['name']} отклонен')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListInvitations(BuildContext context, List<Invitation> invitations) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final pendingInvitations = invitations
        .where((inv) => inv.status == 'pending' && inv.inviteeId == currentUserId)
        .toList();

    if (pendingInvitations.isEmpty) {
      return const Center(child: Text('Нет приглашений в списки'));
    }

    return ListView.builder(
      itemCount: pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = pendingInvitations[index];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('lists').doc(invitation.listId).get(),
          builder: (context, listSnapshot) {
            if (!listSnapshot.hasData) {
              return const ListTile(
                title: Text('Загрузка...'),
                trailing: CircularProgressIndicator(),
              );
            }
            if (listSnapshot.hasError) {
              return const ListTile(title: Text('Ошибка загрузки'));
            }
            final listData = listSnapshot.data!.data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(invitation.inviterId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('Загрузка...'),
                    trailing: CircularProgressIndicator(),
                  );
                }
                if (userSnapshot.hasError) {
                  return const ListTile(title: Text('Ошибка загрузки'));
                }
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text('Приглашение в "${listData['name']}"'),
                    subtitle: Text(
                      'От: ${userData['name']}\nОписание: ${listData['description'] ?? 'Нет описания'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            context.read<InvitationBloc>().add(AcceptInvitation(invitation.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Приглашение в "${listData['name']}" принято')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            context.read<InvitationBloc>().add(RejectInvitation(invitation.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Приглашение в "${listData['name']}" отклонено')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}