import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:library_web/models/author_query.dart';
import 'package:library_web/models/author.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/in_memory_author_repository.dart';
import 'package:library_web/repositories/in_memory_book_repository.dart';
import 'package:library_web/validation/validators.dart';

void main() {
  test('book query restores filters from URL', () {
    final query = BookQuery.fromUri(
        Uri.parse('/books?search=война&genreId=2&sort=year,desc&page=2'));
    expect(query.search, 'война');
    expect(query.genreId, 2);
    expect(query.sortField, 'year');
    expect(query.sortAscending, isFalse);
    expect(query.page, 2);
  });

  test('book repository filters and paginates', () async {
    final result =
        await InMemoryBookRepository().find(const BookQuery(search: 'робот'));
    expect(result.total, 1);
    expect(result.items.single.title, 'Я, робот');
  });

  test('book repository supports soft delete and restore', () async {
    final repository = InMemoryBookRepository();
    await repository.softDelete(1);
    expect(
        (await repository.find(const BookQuery()))
            .items
            .any((book) => book.id == 1),
        isFalse);
    await repository.restore(1);
    expect(
        (await repository.find(const BookQuery()))
            .items
            .any((book) => book.id == 1),
        isTrue);
  });

  test('book repository supports create and update', () async {
    final repository = InMemoryBookRepository();
    final created = await repository.create(BookQueryBookFactory.book);
    expect(created.id, 21);
    final changed = created.copyWith(title: 'Новое название');
    await repository.update(changed);
    expect((await repository.findById(created.id))?.title, 'Новое название');
  });

  test('author query restores country and sorting from URL', () {
    final query = AuthorQuery.fromUri(
        Uri.parse('/authors?country=Россия&sort=birthYear,desc'));
    expect(query.country, 'Россия');
    expect(query.sortField, 'birthYear');
    expect(query.sortAscending, isFalse);
  });

  test('author repository searches by full name', () async {
    final result = await InMemoryAuthorRepository()
        .find(const AuthorQuery(search: 'Толстой'));
    expect(result.total, 1);
    expect(result.items.single.firstName, 'Лев');
  });

  test('book and author models survive JSON round trip', () {
    final book = seedBookForTest;
    final restoredBook = Book.fromJson(book.toJson());
    expect(restoredBook.title, book.title);
    expect(restoredBook.authorIds, book.authorIds);

    final author = seedAuthorForTest;
    final restoredAuthor = Author.fromJson(author.toJson());
    expect(restoredAuthor.fullName, author.fullName);
    expect(restoredAuthor.birthYear, author.birthYear);
  });

  test('persistent book repository restores data after recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await SharedPreferences.getInstance();
    final repository = PersistentBookRepository(first);
    final created = await repository.create(seedBookForTest);

    final second = await SharedPreferences.getInstance();
    final restored = PersistentBookRepository(second);
    expect((await restored.findById(created.id))?.title, seedBookForTest.title);
  });

  test('validators return errors for invalid values', () {
    expect(textLength(''), isNotNull);
    expect(integerInRange('abc', min: 1, max: 10), isNotNull);
    expect(isbnValidator('123'), isNotNull);
    expect(positiveQuantity('0'), isNotNull);
    expect(nonEmptySelection(<int>[]), isNotNull);
  });
}

const seedBookForTest = Book(
  id: 0,
  title: 'Тестовая книга',
  isbn: '978-5-17-999999-9',
  year: 2024,
  pages: 100,
  publisherId: 1,
  authorIds: [1],
  genreIds: [1],
  copiesTotal: 1,
  copiesAvailable: 1,
);

const seedAuthorForTest = Author(
  id: 0,
  firstName: 'Тест',
  lastName: 'Автор',
  country: 'Россия',
  birthYear: 1990,
);

class BookQueryBookFactory {
  static const book = Book(
    id: 0,
    title: 'Тестовая книга',
    isbn: '978-5-17-999999-9',
    year: 2024,
    pages: 100,
    publisherId: 1,
    authorIds: [1],
    genreIds: [1],
    copiesTotal: 1,
    copiesAvailable: 1,
  );
}
