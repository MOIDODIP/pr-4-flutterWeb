import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/catalog_data.dart';
import '../state/author_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/status_view.dart';

class AuthorListScreen extends StatefulWidget {
  final AuthorQuery initialQuery;

  const AuthorListScreen({required this.initialQuery, super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchTimer;
  String? _country;

  @override
  void initState() {
    super.initState();
    _setControllers(widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthorListNotifier>().syncQuery(widget.initialQuery);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AuthorListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery.toQueryString() !=
        widget.initialQuery.toQueryString()) {
      _setControllers(widget.initialQuery);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthorListNotifier>().syncQuery(widget.initialQuery);
        }
      });
    }
  }

  void _setControllers(AuthorQuery query) {
    _searchController.text = query.search;
    _country = query.country;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _navigate(AuthorQuery query) {
    context.go('/authors${query.toQueryString()}');
    context.read<AuthorListNotifier>().applyQuery(query);
  }

  void _searchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _navigate(
          context.read<AuthorListNotifier>().query.copyWith(search: value),
        );
      }
    });
  }

  void _sort(String field) {
    final current = context.read<AuthorListNotifier>().query;
    _navigate(current.copyWith(
      sortField: field,
      sortAscending: current.sortField == field ? !current.sortAscending : true,
    ));
  }

  Future<void> _confirmDelete(Author author) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content: Text('Автор «${author.fullName}» будет скрыт из списка.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthorListNotifier>().deleteOne(author.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авторы'),
        leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
              onPressed: () => context.go('/books'),
              tooltip: 'Книги',
              icon: const Icon(Icons.menu_book)),
          IconButton(
              onPressed: () => context.go('/authors/new'),
              tooltip: 'Добавить автора',
              icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchChanged,
                    decoration: const InputDecoration(
                      labelText: 'Поиск по имени и фамилии',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String?>(
                  value: _country,
                  hint: const Text('Страна'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Все страны')),
                    ...seedAuthors.map((a) => a.country).toSet().map(
                        (country) => DropdownMenuItem(
                            value: country, child: Text(country))),
                  ],
                  onChanged: (value) {
                    setState(() => _country = value);
                    _navigate(notifier.query.copyWith(country: value));
                  },
                ),
              ],
            ),
          ),
          if (notifier.hasSelection)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.tonalIcon(
                  onPressed: notifier.deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  label:
                      Text('Удалить выбранных (${notifier.selected.length})'),
                ),
              ),
            ),
          Expanded(child: _content(notifier)),
        ],
      ),
    );
  }

  Widget _content(AuthorListNotifier notifier) {
    return switch (notifier.status) {
      LoadStatus.idle ||
      LoadStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(
          message: notifier.error ?? 'Ошибка', onRetry: notifier.refresh),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyView(message: 'Авторы не найдены'),
      LoadStatus.success => LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                  child: constraints.maxWidth < 700
                      ? _cards(notifier)
                      : _table(notifier)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: PaginationBar(
                  page: notifier.result.page,
                  totalPages: notifier.result.totalPages,
                  onPageChanged: (page) =>
                      _navigate(notifier.query.pageChanged(page)),
                  size: notifier.query.size,
                  onSizeChanged: (size) =>
                      _navigate(notifier.query.copyWith(size: size)),
                ),
              ),
            ],
          ),
        ),
    };
  }

  Widget _table(AuthorListNotifier notifier) {
    return EntityTable<Author>(
      items: notifier.result.items,
      idOf: (author) => author.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: _sort,
      columns: [
        TableColumnSpec(
            label: 'Фамилия',
            sortField: 'lastName',
            build: (author) => Text(author.lastName)),
        TableColumnSpec(
            label: 'Имя', build: (author) => Text(author.firstName)),
        TableColumnSpec(
            label: 'Страна',
            sortField: 'country',
            build: (author) => Text(author.country)),
        TableColumnSpec(
            label: 'Год рождения',
            sortField: 'birthYear',
            numeric: true,
            build: (author) => Text('${author.birthYear}')),
      ],
      actions: _actions,
    );
  }

  Widget _cards(AuthorListNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final author = notifier.result.items[index];
        return Card(
          child: ListTile(
            leading: Checkbox(
                value: notifier.selected.contains(author.id),
                onChanged: (_) => notifier.toggleSelection(author.id)),
            title: Text(author.fullName),
            subtitle:
                Text('${author.country} · родился в ${author.birthYear} году'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view') context.go('/authors/${author.id}');
                if (value == 'edit') context.go('/authors/${author.id}/edit');
                if (value == 'delete') _confirmDelete(author);
                if (value == 'restore') notifier.restoreOne(author.id);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('Открыть')),
                if (!author.isDeleted)
                  const PopupMenuItem(value: 'edit', child: Text('Изменить')),
                if (!author.isDeleted)
                  const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                if (author.isDeleted)
                  const PopupMenuItem(
                      value: 'restore', child: Text('Восстановить')),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _actions(Author author) => [
        IconButton(
            onPressed: () => context.go('/authors/${author.id}'),
            tooltip: 'Открыть',
            icon: const Icon(Icons.visibility_outlined)),
        if (!author.isDeleted)
          IconButton(
              onPressed: () => context.go('/authors/${author.id}/edit'),
              tooltip: 'Изменить',
              icon: const Icon(Icons.edit_outlined)),
        if (!author.isDeleted)
          IconButton(
              onPressed: () => _confirmDelete(author),
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline)),
        if (author.isDeleted)
          IconButton(
              onPressed: () =>
                  context.read<AuthorListNotifier>().restoreOne(author.id),
              tooltip: 'Восстановить',
              icon: const Icon(Icons.restore)),
      ];
}
