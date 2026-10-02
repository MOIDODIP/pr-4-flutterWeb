import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/catalog_data.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class InMemoryAuthorRepository implements AuthorRepository {
  final SharedPreferences? _prefs;
  late final List<Author> _authors;
  int _nextId = seedAuthors.length + 1;

  InMemoryAuthorRepository([this._prefs]) {
    _authors = [...seedAuthors];
    _restore();
  }

  static const _storageKey = 'authors_v1';

  void _restore() {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null) {
      _persist();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) throw const FormatException('Ожидался список');
      _authors
        ..clear()
        ..addAll(decoded.whereType<Map>().map(
              (item) => Author.fromJson(Map<String, dynamic>.from(item)),
            ));
      if (_authors.isEmpty) _authors.addAll(seedAuthors);
    } catch (_) {
      _authors
        ..clear()
        ..addAll(seedAuthors);
      _persist();
    }
    _nextId = _authors.fold<int>(
        1, (max, author) => author.id >= max ? author.id + 1 : max);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _storageKey,
      jsonEncode(_authors.map((author) => author.toJson()).toList()),
    );
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows =
          rows.where((a) => a.fullName.toLowerCase().contains(needle)).toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.compareTo(b.country),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : from + q.size;
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async =>
      _authors.where((a) => a.id == id).firstOrNull;

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
    );
    _authors.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final index = _authors.indexWhere((item) => item.id == author.id);
    if (index == -1) throw StateError('Автор ${author.id} не найден');
    _authors[index] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final index = _authors.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Автор $id не найден');
    _authors[index] = _authors[index].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async => _deleteAndPersist(id);

  Future<void> _deleteAndPersist(int id) async {
    _authors.removeWhere((item) => item.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final index = _authors.indexWhere((item) => item.id == id);
    if (index == -1) throw StateError('Автор $id не найден');
    _authors[index] = _authors[index].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final index =
          _authors.indexWhere((author) => author.id == id && !author.isDeleted);
      if (index != -1) {
        _authors[index] = _authors[index].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}

class PersistentAuthorRepository extends InMemoryAuthorRepository {
  PersistentAuthorRepository(super.prefs);
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
