import 'package:go_router/go_router.dart';

import 'models/author_query.dart';
import 'models/book_query.dart';
import 'screens/author_form_screen.dart';
import 'screens/author_list_screen.dart';
import 'screens/book_form_screen.dart';
import 'screens/book_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/not_found_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/books',
      builder: (context, state) => BookListScreen(
        initialQuery: BookQuery.fromUri(state.uri),
      ),
      routes: [
        GoRoute(
            path: 'new', builder: (context, state) => const BookFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => BookFormScreen(
            bookId: int.tryParse(state.pathParameters['id'] ?? ''),
            readOnly: true,
          ),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => BookFormScreen(
            bookId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/authors',
      builder: (context, state) => AuthorListScreen(
        initialQuery: AuthorQuery.fromUri(state.uri),
      ),
      routes: [
        GoRoute(
            path: 'new', builder: (context, state) => const AuthorFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => AuthorFormScreen(
            authorId: int.tryParse(state.pathParameters['id'] ?? ''),
            readOnly: true,
          ),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (context, state) => AuthorFormScreen(
            authorId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) =>
      NotFoundScreen(location: state.uri.toString()),
);
