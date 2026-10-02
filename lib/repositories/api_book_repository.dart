import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;

  ApiBookRepository(this._dio);

  @override
  Future<PageResult<Book>> find(BookQuery q) => guard(() async {
        final response = await _dio.get('/books', queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.genreId != null) 'genreId': q.genreId,
          if (q.publisherId != null) 'publisherId': q.publisherId,
          if (q.yearFrom != null) 'yearFrom': q.yearFrom,
          if (q.yearTo != null) 'yearTo': q.yearTo,
          'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
          'page': q.page,
          'size': q.size,
          if (q.includeDeleted) 'includeDeleted': true,
        });
        final data = _asMap(response.data);
        final rawItems = data['items'] ?? data['content'] ?? response.data;
        final items = rawItems is List
            ? rawItems
                .whereType<Map>()
                .map((item) => Book.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : <Book>[];
        return PageResult(
          items: items,
          page: _asInt(data['page'], q.page),
          size: _asInt(data['size'], q.size),
          total: _asInt(data['total'] ?? data['totalElements'], items.length),
        );
      });

  @override
  Future<Book?> findById(int id) => guard(() async {
        final response = await _dio.get('/books/$id');
        return Book.fromJson(_asMap(response.data));
      });

  @override
  Future<Book> create(Book book) => guard(() async {
        final response = await _dio.post('/books', data: _writeData(book));
        return Book.fromJson(_asMap(response.data));
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final response =
            await _dio.put('/books/${book.id}', data: _writeData(book));
        return Book.fromJson(_asMap(response.data));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/books/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.patch('/books/$id', data: {'deletedAt': null}));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/books/bulk-delete', data: {'ids': ids});
        final data = _asMap(response.data);
        return _asInt(data['deleted'], ids.length);
      });

  Map<String, dynamic> _writeData(Book book) => {
        'title': book.title,
        'isbn': book.isbn,
        'year': book.year,
        'pages': book.pages,
        'publisherId': book.publisherId,
        'authorIds': book.authorIds,
        'genreIds': book.genreIds,
        'copiesTotal': book.copiesTotal,
        'copiesAvailable': book.copiesAvailable,
      };

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Сервер вернул неверный формат данных');
  }

  static int _asInt(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
