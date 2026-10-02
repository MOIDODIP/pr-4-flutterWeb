import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../models/catalog_data.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../state/book_list_notifier.dart';
import '../validation/validators.dart';

class BookFormScreen extends StatefulWidget {
  final int? bookId;
  final bool readOnly;

  const BookFormScreen({this.bookId, this.readOnly = false, super.key});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _totalController = TextEditingController();
  final _availableController = TextEditingController();
  late Future<Book?> _bookFuture;
  int _publisherId = 1;
  Set<int> _authorIds = {1};
  Set<int> _genreIds = {1};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bookFuture = _loadBook();
  }

  Future<Book?> _loadBook() async {
    if (widget.bookId == null) {
      _yearController.text = '2024';
      _pagesController.text = '300';
      _totalController.text = '1';
      _availableController.text = '1';
      return null;
    }
    final book = await context.read<BookRepository>().findById(widget.bookId!);
    if (book != null) {
      _titleController.text = book.title;
      _isbnController.text = book.isbn;
      _yearController.text = '${book.year}';
      _pagesController.text = '${book.pages}';
      _totalController.text = '${book.copiesTotal}';
      _availableController.text = '${book.copiesAvailable}';
      _publisherId = book.publisherId;
      _authorIds = {...book.authorIds};
      _genreIds = {...book.genreIds};
    }
    return book;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _totalController.dispose();
    _availableController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final value = Book(
      id: widget.bookId ?? 0,
      title: _titleController.text.trim(),
      isbn: _isbnController.text.trim(),
      year: int.parse(_yearController.text),
      pages: int.parse(_pagesController.text),
      publisherId: _publisherId,
      authorIds: _authorIds.toList(),
      genreIds: _genreIds.toList(),
      copiesTotal: int.parse(_totalController.text),
      copiesAvailable: int.parse(_availableController.text),
    );
    final repository = context.read<BookRepository>();
    if (widget.bookId == null) {
      await repository.create(value);
    } else {
      await repository.update(value);
    }
    if (!mounted) return;
    await context.read<BookListNotifier>().refresh();
    if (!mounted) return;
    context.go('/books');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookId == null
            ? 'Новая книга'
            : widget.readOnly
                ? 'Книга'
                : 'Редактирование книги'),
        leading: IconButton(
            onPressed: () => context.go('/books'),
            icon: const Icon(Icons.arrow_back)),
      ),
      body: FutureBuilder<Book?>(
        future: _bookFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              (widget.bookId != null && snapshot.data == null)) {
            return const Center(child: Text('Книга не найдена'));
          }
          return _form();
        },
      ),
    );
  }

  Widget _form() {
    final authors = context.read<AuthorRepository>();
    return FutureBuilder(
      future: Future.wait([authors.findById(1)]),
      builder: (context, _) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                      controller: _titleController,
                      readOnly: widget.readOnly,
                      decoration: const InputDecoration(
                          labelText: 'Название', border: OutlineInputBorder()),
                      validator: (value) => textLength(value, max: 200)),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _isbnController,
                      readOnly: widget.readOnly,
                      decoration: const InputDecoration(
                          labelText: 'ISBN', border: OutlineInputBorder()),
                      validator: isbnValidator),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: _yearController,
                              readOnly: widget.readOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Год',
                                  border: OutlineInputBorder()),
                              validator: (value) =>
                                  integerInRange(value, min: 1000, max: 2100))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: _pagesController,
                              readOnly: widget.readOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Страниц',
                                  border: OutlineInputBorder()),
                              validator: (value) =>
                                  integerInRange(value, min: 1, max: 5000))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: _totalController,
                              readOnly: widget.readOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Всего копий',
                                  border: OutlineInputBorder()),
                              validator: (value) => positiveQuantity(value))),
                      SizedBox(
                          width: 150,
                          child: TextFormField(
                              controller: _availableController,
                              readOnly: widget.readOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Доступно',
                                  border: OutlineInputBorder()),
                              validator: (value) =>
                                  positiveQuantity(value, allowZero: true))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                      value: _publisherId,
                      decoration: const InputDecoration(
                          labelText: 'Издательство',
                          border: OutlineInputBorder()),
                      items: publishers.entries
                          .map((entry) => DropdownMenuItem(
                              value: entry.key, child: Text(entry.value)))
                          .toList(),
                      onChanged: widget.readOnly
                          ? null
                          : (value) =>
                              setState(() => _publisherId = value ?? 1),
                      validator: (value) => requiredSelection(value,
                          message: 'Выберите издательство')),
                  const SizedBox(height: 16),
                  _selectionBlock(
                      'Авторы',
                      seedAuthors
                          .map((author) => (author.id, author.fullName))
                          .toList(),
                      _authorIds,
                      (value) => setState(() => _authorIds = value)),
                  _selectionBlock(
                      'Жанры',
                      genres.entries
                          .map((entry) => (entry.key, entry.value))
                          .toList(),
                      _genreIds,
                      (value) => setState(() => _genreIds = value)),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? 'Сохранение...' : 'Сохранить')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionBlock(String title, List<(int, String)> values,
      Set<int> selected, ValueChanged<Set<int>> onChanged) {
    return FormField<Set<int>>(
      initialValue: {...selected},
      validator: (value) => nonEmptySelection(value),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            children: values
                .map((value) => SizedBox(
                    width: 240,
                    child: CheckboxListTile(
                        value: field.value?.contains(value.$1) ?? false,
                        dense: true,
                        title: Text(value.$2),
                        onChanged: widget.readOnly
                            ? null
                            : (checked) {
                                final next = {...?field.value};
                                checked == true
                                    ? next.add(value.$1)
                                    : next.remove(value.$1);
                                field.didChange(next);
                                onChanged(next);
                              })))
                .toList(),
          ),
          if (field.errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(field.errorText!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
