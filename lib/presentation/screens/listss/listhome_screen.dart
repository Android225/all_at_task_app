import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/presentation/screens/listss/list_edit_screen.dart';
import 'package:all_at_task/router/app_router.dart';

class ListHomeScreen extends StatelessWidget {
  const ListHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListBloc>()..add(LoadLists()),
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
                'Последние списки',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ListBloc, ListState>(
                  builder: (context, state) {
                    if (state is ListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ListError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ListLoaded) {
                      final lists = state.lists;
                      if (lists.isEmpty) {
                        return const Center(child: Text('Нет списков'));
                      }
                      return ListView.builder(
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          return ListTile(
                            title: Text(list.name),
                            onTap: () {
                              context.read<ListBloc>().add(SelectList(list.id));
                              getIt<AppRouter>().push(ListEditScreen(list: list));
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
            getIt<AppRouter>().push(const ListEditScreen());
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}