import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class InMemoryBookRepository implements BookRepository {
  final SharedPreferences? _prefs;
  late final List<Book> _books;
  int _nextId = seedBooks.length + 1;

  InMemoryBookRepository([this._prefs]) {
    _books = [...seedBooks];
    _restore();
  }

  static const _storageKey = 'books_v1';

  void _restore() {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null) {
      _persist();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Ожидался список');
      _books
        ..clear()
        ..addAll(decoded.whereType<Map>().map(
              (item) => Book.fromJson(Map<String, dynamic>.from(item)),
            ));
      if (_books.isEmpty) _books.addAll(seedBooks);
    } catch (_) {
      _books
        ..clear()
        ..addAll(seedBooks);
      _persist();
    }
    _nextId =
        _books.fold<int>(1, (max, book) => book.id >= max ? book.id + 1 : max);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _storageKey,
      jsonEncode(_books.map((book) => book.toJson()).toList()),
    );
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        'copies' => a.copiesAvailable.compareTo(b.copiesAvailable),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Book>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    return _books.where((book) => book.id == id).firstOrNull;
  }

  @override
  Future<Book> create(Book book) async {
    final created = book.copyWith();
    final value = Book(
      id: _nextId++,
      title: created.title,
      isbn: created.isbn,
      year: created.year,
      pages: created.pages,
      publisherId: created.publisherId,
      authorIds: created.authorIds,
      genreIds: created.genreIds,
      copiesTotal: created.copiesTotal,
      copiesAvailable: created.copiesAvailable,
    );
    _books.add(value);
    await _persist();
    return value;
  }

  @override
  Future<Book> update(Book book) async {
    final index = _books.indexWhere((item) => item.id == book.id);
    if (index == -1) throw StateError('Книга ${book.id} не найдена');
    _books[index] = book;
    await _persist();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _books.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Книга $id не найдена');
    _books[index] = _books[index].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async => _deleteAndPersist(id);

  Future<void> _deleteAndPersist(int id) async {
    _books.removeWhere((item) => item.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final index = _books.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Книга $id не найдена');
    _books[index] = _books[index].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index =
          _books.indexWhere((book) => book.id == id && !book.isDeleted);
      if (index != -1) {
        _books[index] = _books[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}

class PersistentBookRepository extends InMemoryBookRepository {
  PersistentBookRepository(super.prefs);
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
