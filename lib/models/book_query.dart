class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  factory BookQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sort = q['sort']?.split(',') ?? const <String>[];
    return BookQuery(
      search: q['search'] ?? '',
      genreId: int.tryParse(q['genreId'] ?? ''),
      publisherId: int.tryParse(q['publisherId'] ?? ''),
      yearFrom: int.tryParse(q['yearFrom'] ?? ''),
      yearTo: int.tryParse(q['yearTo'] ?? ''),
      sortField: sort.isEmpty || sort.first.isEmpty ? 'title' : sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: int.tryParse(q['page'] ?? '') ?? 1,
      size: int.tryParse(q['size'] ?? '') ?? 10,
      includeDeleted: q['deleted'] == '1',
    );
  }

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId:
          publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  BookQuery pageChanged(int value) => BookQuery(
        search: search,
        genreId: genreId,
        publisherId: publisherId,
        yearFrom: yearFrom,
        yearTo: yearTo,
        sortField: sortField,
        sortAscending: sortAscending,
        page: value,
        size: size,
        includeDeleted: includeDeleted,
      );

  String toQueryString() {
    final values = <String, String>{};
    if (search.trim().isNotEmpty) values['search'] = search.trim();
    if (genreId != null) values['genreId'] = '$genreId';
    if (publisherId != null) values['publisherId'] = '$publisherId';
    if (yearFrom != null) values['yearFrom'] = '$yearFrom';
    if (yearTo != null) values['yearTo'] = '$yearTo';
    if (sortField != 'title' || !sortAscending) {
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
