import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;

  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(AuthorQuery q) => guard(() async {
        final response = await _dio.get('/authors', queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.country != null && q.country!.isNotEmpty) 'country': q.country,
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
                .map((item) => Author.fromJson(Map<String, dynamic>.from(item)))
                .toList()
            : <Author>[];
        return PageResult(
          items: items,
          page: _asInt(data['page'], q.page),
          size: _asInt(data['size'], q.size),
          total: _asInt(data['total'] ?? data['totalElements'], items.length),
        );
      });

  @override
  Future<Author?> findById(int id) => guard(() async {
        final response = await _dio.get('/authors/$id');
        return Author.fromJson(_asMap(response.data));
      });

  @override
  Future<Author> create(Author author) => guard(() async {
        final response = await _dio.post('/authors', data: _writeData(author));
        return Author.fromJson(_asMap(response.data));
      });

  @override
  Future<Author> update(Author author) => guard(() async {
        final response =
            await _dio.put('/authors/${author.id}', data: _writeData(author));
        return Author.fromJson(_asMap(response.data));
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/authors/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.patch('/authors/$id', data: {'deletedAt': null}));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/authors/bulk-delete', data: {'ids': ids});
        final data = _asMap(response.data);
        return _asInt(data['deleted'], ids.length);
      });

  Map<String, dynamic> _writeData(Author author) => {
        'firstName': author.firstName,
        'lastName': author.lastName,
        'country': author.country,
        'birthYear': author.birthYear,
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
