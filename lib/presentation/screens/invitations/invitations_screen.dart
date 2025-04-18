import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/presentation/bloc/invitation/invitation_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    // Отправляем событие LoadInvitations при открытии экрана
    GetIt.instance<InvitationBloc>().add(LoadInvitations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запросы в друзья'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: BlocListener<InvitationBloc, InvitationState>(
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
          child: BlocBuilder<InvitationBloc, InvitationState>(
            bloc: GetIt.instance<InvitationBloc>(),
            builder: (context, state) {
              if (state is InvitationLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is InvitationLoaded) {
                final friendRequests = state.friendRequests
                    .where((req) => req.status == 'pending')
                    .toList();
                if (friendRequests.isEmpty) {
                  return const Center(child: Text('Нет запросов в друзья'));
                }
                return ListView.builder(
                  itemCount: friendRequests.length,
                  itemBuilder: (context, index) {
                    final request = friendRequests[index];
                    final requesterId = request.userId1;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('public_profiles')
                          .doc(requesterId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            title: Text('Загрузка...'),
                          );
                        }
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final username = userData['username'] as String;
                        final name = userData['name'] as String;
                        return ListTile(
                          title: Text(username),
                          subtitle: Text(name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  GetIt.instance<InvitationBloc>().add(
                                    AcceptFriendRequest(request.id),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  GetIt.instance<InvitationBloc>().add(
                                    RejectFriendRequest(request.id),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              } else if (state is InvitationError) {
                return Center(child: Text('Ошибка: ${state.message}'));
              }
              return const Center(child: Text('Нет запросов в друзья'));
            },
          ),
        ),
      ),
    );
  }
}