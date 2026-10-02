import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../state/author_list_notifier.dart';
import '../validation/validators.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? authorId;
  final bool readOnly;

  const AuthorFormScreen({this.authorId, this.readOnly = false, super.key});

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _birthYearController = TextEditingController();
  late Future<Author?> _authorFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _authorFuture = _loadAuthor();
  }

  Future<Author?> _loadAuthor() async {
    if (widget.authorId == null) {
      _birthYearController.text = '2000';
      return null;
    }
    final author =
        await context.read<AuthorRepository>().findById(widget.authorId!);
    if (author != null) {
      _firstNameController.text = author.firstName;
      _lastNameController.text = author.lastName;
      _countryController.text = author.country;
      _birthYearController.text = '${author.birthYear}';
    }
    return author;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final author = Author(
      id: widget.authorId ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      country: _countryController.text.trim(),
      birthYear: int.parse(_birthYearController.text),
    );
    final repository = context.read<AuthorRepository>();
    if (widget.authorId == null) {
      await repository.create(author);
    } else {
      await repository.update(author);
    }
    if (!mounted) return;
    await context.read<AuthorListNotifier>().refresh();
    if (!mounted) return;
    context.go('/authors');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.authorId == null
            ? 'Новый автор'
            : widget.readOnly
                ? 'Автор'
                : 'Редактирование автора'),
        leading: IconButton(
            onPressed: () => context.go('/authors'),
            icon: const Icon(Icons.arrow_back)),
      ),
      body: FutureBuilder<Author?>(
        future: _authorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              (widget.authorId != null && snapshot.data == null)) {
            return const Center(child: Text('Автор не найден'));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                          controller: _firstNameController,
                          readOnly: widget.readOnly,
                          decoration: const InputDecoration(
                              labelText: 'Имя', border: OutlineInputBorder()),
                          validator: (value) => textLength(value, max: 80)),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _lastNameController,
                          readOnly: widget.readOnly,
                          decoration: const InputDecoration(
                              labelText: 'Фамилия',
                              border: OutlineInputBorder()),
                          validator: (value) => textLength(value, max: 120)),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _countryController,
                          readOnly: widget.readOnly,
                          decoration: const InputDecoration(
                              labelText: 'Страна',
                              border: OutlineInputBorder()),
                          validator: (value) => textLength(value, max: 80)),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _birthYearController,
                          readOnly: widget.readOnly,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Год рождения',
                              border: OutlineInputBorder()),
                          validator: (value) =>
                              integerInRange(value, min: 1000, max: 2020)),
                      if (!widget.readOnly) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(
                                    _saving ? 'Сохранение...' : 'Сохранить'))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
