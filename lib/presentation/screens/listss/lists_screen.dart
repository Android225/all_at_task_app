import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListBloc>()..add(LoadLists()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Мои списки'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: BlocBuilder<ListBloc, ListState>(
            builder: (context, state) {
              if (state is ListLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ListLoaded) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: state.lists.length,
                  itemBuilder: (context, index) {
                    final list = state.lists[index];
                    return GestureDetector(
                      onTap: () {
                        context.read<ListBloc>().add(UpdateListLastUsed(list.id));
                        context.read<ListBloc>().add(SelectList(list.id));
                        Navigator.pushNamed(context, '/home', arguments: list.id);
                      },
                      child: Card(
                        elevation: 2,
                        color: Color(list.color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                list.name,
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton(
                                icon: const Icon(Icons.people, color: Colors.white),
                                onPressed: () {
                                  _showMembersDialog(context, list);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else if (state is ListError) {
                return Center(child: Text(state.message));
              }
              return const Center(child: Text('Нет списков'));
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () => Navigator.pushNamed(context, '/list_edit'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showMembersDialog(BuildContext context, TaskList list) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Участники: ${list.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: BlocBuilder<ListBloc, ListState>(
              builder: (context, state) {
                if (state is ListLoaded) {
                  final isAdmin = list.members[_auth.currentUser!.uid] == 'admin';
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: list.members.length,
                    itemBuilder: (context, index) {
                      final userId = list.members.keys.elementAt(index);
                      final role = list.members[userId]!;
                      return FutureBuilder<DocumentSnapshot>(
                        future: _firestore.collection('users').doc(userId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(userData['name'] ?? 'Unknown'),
                            subtitle: Text('Роль: $role'),
                            trailing: isAdmin && userId != _auth.currentUser!.uid
                                ? DropdownButton<String>(
                              value: role,
                              items: const [
                                DropdownMenuItem(value: 'viewer', child: Text('Просмотр')),
                                DropdownMenuItem(value: 'editor', child: Text('Редактор')),
                                DropdownMenuItem(value: 'manager', child: Text('Менеджер')),
                                DropdownMenuItem(value: 'admin', child: Text('Админ')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  context.read<ListBloc>().add(UpdateMemberRole(
                                    list.id,
                                    userId,
                                    value,
                                  ));
                                  Navigator.pop(dialogContext);
                                }
                              },
                            )
                                : null,
                          );
                        },
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}