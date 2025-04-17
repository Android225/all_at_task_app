import 'package:all_at_task/presentation/bloc/list/list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';

class ListHomeScreen extends StatelessWidget {
  const ListHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ListBloc>()..add(LoadLists()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Списки'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск списков...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  context.read<ListBloc>().add(SearchListsAndTasks(value));
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Мои списки',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ListBloc, ListState>(
                  builder: (context, state) {
                    print('ListHomeScreen ListBloc state: $state');
                    if (state is ListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ListError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ListSearchResults) {
                      final results = [...state.listResults, ...state.taskResults];
                      return ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          if (result is TaskList) {
                            return ListTile(
                              title: Text(result.name),
                              trailing: result.name.toLowerCase() == 'основной'
                                  ? const Icon(Icons.star, color: Colors.yellow)
                                  : null,
                              onTap: () {
                                context.read<ListBloc>().add(SelectList(result.id));
                                context.read<ListBloc>().add(UpdateListLastUsed(result.id));
                                Navigator.pushNamed(context, '/home', arguments: result.id);
                              },
                              onLongPress: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<ListBloc>(),
                                      child: ListEditScreen(list: result),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else if (result is Task) {
                            final list = state.allLists.firstWhere(
                                  (l) => l.id == result.listId,
                              orElse: () => TaskList(
                                id: '',
                                name: 'Неизвестный список',
                                ownerId: '',
                                members: {},
                                sharedLists: [],
                                linkedLists: [],
                                createdAt: null,
                              ),
                            );
                            return ListTile(
                              title: Text(result.title),
                              subtitle: Text('${list.name}/${result.title}'),
                              onTap: () {
                                context.read<ListBloc>().add(SelectList(result.listId));
                                context.read<ListBloc>().add(UpdateListLastUsed(result.listId));
                                Navigator.pushNamed(context, '/home', arguments: result.listId);
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      );
                    }
                    if (state is ListLoaded) {
                      final lists = state.lists;
                      print('ListHomeScreen lists: ${lists.map((l) => l.name).toList()}');
                      if (lists.isEmpty) {
                        return const Center(child: Text('Нет списков'));
                      }
                      return ListView.builder(
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return ListTile(
                            title: Text(list.name),
                            trailing: list.name.toLowerCase() == 'основной'
                                ? const Icon(Icons.star, color: Colors.yellow)
                                : null,
                            onTap: () {
                              context.read<ListBloc>().add(SelectList(list.id));
                              context.read<ListBloc>().add(UpdateListLastUsed(list.id));
                              Navigator.pushNamed(context, '/home', arguments: list.id);
                            },
                            onLongPress: () {
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
                          );
                        },
                      );
                    }
                    return const Center(child: Text('Нет списков'));
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ListBloc>(),
                  child: const ListEditScreen(),
                ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}