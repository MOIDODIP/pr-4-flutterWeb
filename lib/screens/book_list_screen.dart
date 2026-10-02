import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/book_query.dart';
import '../models/catalog_data.dart';
import '../state/book_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/status_view.dart';

class BookListScreen extends StatefulWidget {
  final BookQuery initialQuery;

  const BookListScreen({required this.initialQuery, super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _searchController = TextEditingController();
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  Timer? _searchTimer;
  int? _genreId;
  int? _publisherId;
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _setControllers(widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BookListNotifier>().syncQuery(widget.initialQuery);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BookListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery.toQueryString() !=
        widget.initialQuery.toQueryString()) {
      _setControllers(widget.initialQuery);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BookListNotifier>().syncQuery(widget.initialQuery);
        }
      });
    }
  }

  void _setControllers(BookQuery query) {
    _searchController.text = query.search;
    _yearFromController.text = query.yearFrom?.toString() ?? '';
    _yearToController.text = query.yearTo?.toString() ?? '';
    _genreId = query.genreId;
    _publisherId = query.publisherId;
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _navigate(BookQuery query) {
    context.go('/books${query.toQueryString()}');
    context.read<BookListNotifier>().applyQuery(query);
  }

  void _searchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _navigate(context.read<BookListNotifier>().query.copyWith(search: value));
    });
  }

  void _applyFilters() {
    final current = context.read<BookListNotifier>().query;
    _navigate(
      current.copyWith(
        genreId: _genreId,
        publisherId: _publisherId,
        yearFrom: int.tryParse(_yearFromController.text),
        yearTo: int.tryParse(_yearToController.text),
      ),
    );
  }

  void _sort(String field) {
    final current = context.read<BookListNotifier>().query;
    _navigate(
      current.copyWith(
        sortField: field,
        sortAscending:
            current.sortField == field ? !current.sortAscending : true,
      ),
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('Книга «${book.title}» будет скрыта из списка.'),
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
      await context.read<BookListNotifier>().deleteOne(book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Книги'),
        leading: IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
              onPressed: () => context.go('/authors'),
              tooltip: 'Авторы',
              icon: const Icon(Icons.people_outline)),
          IconButton(
              onPressed: () => context.go('/books/new'),
              tooltip: 'Добавить книгу',
              icon: const Icon(Icons.add)),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(notifier),
          Expanded(child: _buildContent(notifier)),
        ],
      ),
    );
  }

  Widget _buildToolbar(BookListNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchChanged,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по названию или ISBN',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Фильтры',
                onPressed: () =>
                    setState(() => _filtersVisible = !_filtersVisible),
                icon: Icon(_filtersVisible
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined),
              ),
            ],
          ),
          if (_filtersVisible) _buildFilters(),
          if (notifier.hasSelection)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: notifier.deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  label:
                      Text('Удалить выбранные (${notifier.selected.length})'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          DropdownButton<int?>(
            value: _genreId,
            hint: const Text('Жанр'),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('Все жанры')),
              ...genres.entries.map((entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value))),
            ],
            onChanged: (value) => setState(() => _genreId = value),
          ),
          DropdownButton<int?>(
            value: _publisherId,
            hint: const Text('Издательство'),
            items: [
              const DropdownMenuItem<int?>(
                  value: null, child: Text('Все издательства')),
              ...publishers.entries.map((entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value))),
            ],
            onChanged: (value) => setState(() => _publisherId = value),
          ),
          SizedBox(
              width: 120,
              child: TextField(
                  controller: _yearFromController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Год от'))),
          SizedBox(
              width: 120,
              child: TextField(
                  controller: _yearToController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Год до'))),
          FilledButton(
              onPressed: _applyFilters, child: const Text('Применить')),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _genreId = null;
                _publisherId = null;
                _yearFromController.clear();
                _yearToController.clear();
              });
              _navigate(const BookQuery());
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BookListNotifier notifier) {
    return switch (notifier.status) {
      LoadStatus.idle ||
      LoadStatus.loading =>
        const Center(child: CircularProgressIndicator()),
      LoadStatus.error => ErrorView(
          message: notifier.error ?? 'Ошибка', onRetry: notifier.refresh),
      LoadStatus.success when notifier.result.items.isEmpty =>
        const EmptyView(message: 'По заданным условиям книги не найдены'),
      LoadStatus.success => LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                child: constraints.maxWidth < 700
                    ? _buildCards(notifier)
                    : _buildTable(notifier),
              ),
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

  Widget _buildTable(BookListNotifier notifier) {
    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (book) => book.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.query.sortField,
      sortAscending: notifier.query.sortAscending,
      onSort: _sort,
      columns: [
        TableColumnSpec(
            label: 'Название',
            sortField: 'title',
            build: (book) => Text(book.title)),
        TableColumnSpec(label: 'ISBN', build: (book) => Text(book.isbn)),
        TableColumnSpec(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (book) => Text('${book.year}')),
        TableColumnSpec(
            label: 'Страниц',
            sortField: 'pages',
            numeric: true,
            build: (book) => Text('${book.pages}')),
        TableColumnSpec(
            label: 'Доступно',
            sortField: 'copies',
            numeric: true,
            build: (book) =>
                Text('${book.copiesAvailable}/${book.copiesTotal}')),
      ],
      actions: _actions,
    );
  }

  Widget _buildCards(BookListNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final book = notifier.result.items[index];
        return Card(
          child: ListTile(
            leading: Checkbox(
                value: notifier.selected.contains(book.id),
                onChanged: (_) => notifier.toggleSelection(book.id)),
            title: Text(book.title),
            subtitle: Text(
                '${book.isbn}\n${book.year} год · ${book.pages} стр. · доступно ${book.copiesAvailable}/${book.copiesTotal}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value, book),
              itemBuilder: (context) => _menuItems(book),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _actions(Book book) {
    return [
      IconButton(
          onPressed: () => context.go('/books/${book.id}'),
          tooltip: 'Открыть',
          icon: const Icon(Icons.visibility_outlined)),
      if (!book.isDeleted)
        IconButton(
            onPressed: () => context.go('/books/${book.id}/edit'),
            tooltip: 'Изменить',
            icon: const Icon(Icons.edit_outlined)),
      if (!book.isDeleted)
        IconButton(
            onPressed: () => _confirmDelete(book),
            tooltip: 'Удалить',
            icon: const Icon(Icons.delete_outline)),
      if (book.isDeleted)
        IconButton(
            onPressed: () =>
                context.read<BookListNotifier>().restoreOne(book.id),
            tooltip: 'Восстановить',
            icon: const Icon(Icons.restore)),
    ];
  }

  List<PopupMenuEntry<String>> _menuItems(Book book) => [
        const PopupMenuItem(value: 'view', child: Text('Открыть')),
        if (!book.isDeleted)
          const PopupMenuItem(value: 'edit', child: Text('Изменить')),
        if (!book.isDeleted)
          const PopupMenuItem(value: 'delete', child: Text('Удалить')),
        if (book.isDeleted)
          const PopupMenuItem(value: 'restore', child: Text('Восстановить')),
      ];

  void _handleAction(String value, Book book) {
    switch (value) {
      case 'view':
        context.go('/books/${book.id}');
      case 'edit':
        context.go('/books/${book.id}/edit');
      case 'delete':
        _confirmDelete(book);
      case 'restore':
        context.read<BookListNotifier>().restoreOne(book.id);
    }
  }
}
