import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Библиотечная система')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_library_outlined, size: 72),
                const SizedBox(height: 16),
                Text('Каталог библиотеки',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/books'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Книги'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/authors'),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Авторы'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
