class AuthorQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory AuthorQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sort = q['sort']?.split(',') ?? const <String>[];
    return AuthorQuery(
      search: q['search'] ?? '',
      country: q['country'],
      sortField: sort.isEmpty || sort.first.isEmpty ? 'lastName' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(q['page'] ?? '') ?? 1,
      size: int.tryParse(q['size'] ?? '') ?? 10,
      includeDeleted: q['deleted'] == '1',
    );
  }

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? 10,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  AuthorQuery pageChanged(int value) => AuthorQuery(
        search: search,
        country: country,
        sortField: sortField,
        sortAscending: sortAscending,
        page: value,
        size: size,
        includeDeleted: includeDeleted,
      );

  String toQueryString() {
    final values = <String, String>{};
    if (search.trim().isNotEmpty) values['search'] = search.trim();
    if (country != null && country!.isNotEmpty) values['country'] = country!;
    if (sortField != 'lastName' || !sortAscending) {
      values['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';
    }
    if (page != 1) values['page'] = '$page';
    if (size != 10) values['size'] = '$size';
    if (includeDeleted) values['deleted'] = '1';
    final query = Uri(queryParameters: values).query;
    return query.isEmpty ? '' : '?$query';
  }

  static const _unset = Object();
}
