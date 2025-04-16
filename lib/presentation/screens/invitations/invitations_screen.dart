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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Запросы в друзья',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvitationBloc, InvitationState>(
                  builder: (context, state) {
                    if (state is InvitationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InvitationLoaded) {
                      final friendRequests = state.friendRequests
                          .where((req) => req.status == 'pending' && req.userId2 == FirebaseAuth.instance.currentUser!.uid)
                          .toList();
                      if (friendRequests.isEmpty) {
                        return const Text('Нет запросов в друзья');
                      }
                      return ListView.builder(
                        itemCount: friendRequests.length,
                        itemBuilder: (context, index) {
                          final request = friendRequests[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(request.userId1).get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox();
                              final userData = snapshot.data!.data() as Map<String, dynamic>;
                              return Card(
                                child: ListTile(
                                  title: Text('Запрос от ${userData['name']}'),
                                  subtitle: const Text('Хотите добавить в друзья?'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () {
                                          context.read<InvitationBloc>().add(AcceptFriendRequest(request.id));
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () {
                                          context.read<InvitationBloc>().add(RejectFriendRequest(request.id));
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
                    return const Text('Ошибка загрузки');
                  },
                ),
              ),
              const Divider(),
              const Text(
                'Приглашения в списки',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<InvitationBloc, InvitationState>(
                  builder: (context, state) {
                    if (state is InvitationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InvitationLoaded) {
                      final invitations = state.invitations
                          .where((inv) => inv.status == 'pending' && inv.inviteeId == FirebaseAuth.instance.currentUser!.uid)
                          .toList();
                      if (invitations.isEmpty) {
                        return const Text('Нет приглашений в списки');
                      }
                      return ListView.builder(
                        itemCount: invitations.length,
                        itemBuilder: (context, index) {
                          final invitation = invitations[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('lists').doc(invitation.listId).get(),
                            builder: (context, listSnapshot) {
                              if (!listSnapshot.hasData) return const SizedBox();
                              final listData = listSnapshot.data!.data() as Map<String, dynamic>;
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(invitation.inviterId).get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) return const SizedBox();
                                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                  return Card(
                                    child: ListTile(
                                      title: Text('Приглашение в "${listData['name']}"'),
                                      subtitle: Text(
                                          'От: ${userData['name']}\nОписание: ${listData['description'] ?? 'Нет описания'}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green),
                                            onPressed: () {
                                              context.read<InvitationBloc>().add(AcceptInvitation(invitation.id));
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red),
                                            onPressed: () {
                                              context.read<InvitationBloc>().add(RejectInvitation(invitation.id));
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