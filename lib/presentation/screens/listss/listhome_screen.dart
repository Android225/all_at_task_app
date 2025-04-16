import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/models/task.dart';
import 'package:all_at_task/data/models/task_list.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/lists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListHomeScreen extends StatefulWidget {
  const ListHomeScreen({super.key});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListBloc>()..add(LoadLists()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Списки'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Поиск задач и списков',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  context.read<ListBloc>().add(SearchListsAndTasks(value));
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<ListBloc, ListState>(
                builder: (context, state) {
                  if (_searchController.text.isNotEmpty && state is ListSearchResults) {
                    return Expanded(
                      child: ListView.builder(
                        itemCount: state.results.length,
                        itemBuilder: (context, index) {
                          final result = state.results[index];
                          if (result is TaskList) {
                            return ListTile(
                              title: Text(result.name),
                              subtitle: Text('${result.name}/'),
                              onTap: () {
                                context.read<ListBloc>().add(UpdateListLastUsed(result.id));
                                context.read<ListBloc>().add(SelectList(result.id));
                                Navigator.pushNamed(context, '/home', arguments: result.id);
                              },
                            );
                          } else if (result is Task) {
                            final list = state.lists.firstWhere((l) => l.id == result.listId);
                            return ListTile(
                              title: Text(result.title),
                              subtitle: Text('${list.name}/${result.title}'),
                              onTap: () {
                                context.read<ListBloc>().add(UpdateListLastUsed(result.listId));
                                context.read<ListBloc>().add(SelectList(result.listId));
                                Navigator.pushNamed(context, '/home', arguments: result.listId);
                              },
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/lists');
                        },
                        child: const Text('Мои списки', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Последние списки',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BlocBuilder<ListBloc, ListState>(
                          builder: (context, state) {
                            if (state is ListLoading) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (state is ListLoaded) {
                              final recentLists = state.lists
                                  .where((list) => list.lastUsed != null)
                                  .toList()
                                ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
                              final displayLists = recentLists.take(4).toList().length < 4
                                  ? List.generate(4, (index) => recentLists.length > index ? recentLists[index] : null)
                                  : recentLists.take(4).toList();
                              return GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.5,
                                ),
                                itemCount: 4,
                                itemBuilder: (context, index) {
                                  final list = displayLists[index];
                                  if (list == null) {
                                    return Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const SizedBox(),
                                    );
                                  }
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
                                      child: Center(
                                        child: Text(
                                          list.name,
                                          style: const TextStyle(fontSize: 16, color: Colors.white),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return const Center(child: Text('Нет списков'));
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}