import 'package:all_at_task/presentation/bloc/list/list_bloc.dart';
import 'package:all_at_task/config/theme/app_theme.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListHomeScreen extends StatefulWidget {
  const ListHomeScreen({super.key});

  @override
  State<ListHomeScreen> createState() => _ListHomeScreenState();
}

class _ListHomeScreenState extends State<ListHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ListBloc>()..add(LoadLists()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text('Мои списки'),
        ),
        body: BlocBuilder<ListBloc, ListState>(
          builder: (context, state) {
            if (state is ListLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ListLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.defaultPadding),
                itemCount: state.lists.length,
                itemBuilder: (context, index) {
                  final list = state.lists[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(list.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          context.read<ListBloc>().add(DeleteList(list.id));
                        },
                      ),
                      onTap: () {
                        context.read<ListBloc>().add(SelectList(list.id));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
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
        floatingActionButton: Builder(
          builder: (fabContext) {
            return FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () => _showAddListBottomSheet(fabContext),
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showAddListBottomSheet(BuildContext context) {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Новый список',
                style: Theme.of(bottomSheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название списка'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<ListBloc>().add(AddList(nameController.text));
                    Navigator.pop(bottomSheetContext);
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          ),
        );
      },
    );
  }
}