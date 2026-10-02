import 'package:flutter/foundation.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import '../repositories/author_repository.dart';

class AuthorListNotifier extends ChangeNotifier {
  final AuthorRepository _repository;

  AuthorListNotifier(this._repository);

  AuthorQuery _query = const AuthorQuery();
  PageResult<Author> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  AuthorQuery get query => _query;
  PageResult<Author> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (error) {
      _error = 'Не удалось загрузить список: $error';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  Future<void> syncQuery(AuthorQuery next) async {
    if (next.toQueryString() == _query.toQueryString()) return;
    _query = next;
    _selected.clear();
    await load();
  }

  Future<void> applyQuery(AuthorQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> deleteOne(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> restoreOne(int id) async {
    await _repository.restore(id);
    await load();
  }
}

enum LoadStatus { idle, loading, success, error }
