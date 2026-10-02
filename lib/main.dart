import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'router.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final dio = buildDio();
  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<BookRepository>(create: (_) => ApiBookRepository(dio)),
        Provider<AuthorRepository>(create: (_) => ApiAuthorRepository(dio)),
        ChangeNotifierProvider(
          create: (context) =>
              BookListNotifier(context.read<BookRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              AuthorListNotifier(context.read<AuthorRepository>())..load(),
        ),
      ],
      child: const LibraryApp(),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Библиотечная система',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
