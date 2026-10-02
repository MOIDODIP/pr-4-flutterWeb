import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: sortAscending,
        columns: [
          if (onToggleSelect != null) const DataColumn(label: Text('')),
          ...columns.map(
            (column) => DataColumn(
              numeric: column.numeric,
              onSort: column.sortField == null || onSort == null
                  ? null
                  : (_, __) => onSort!(column.sortField!),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(column.label),
                  if (sortField == column.sortField)
                    Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          if (actions != null) const DataColumn(label: Text('Действия')),
        ],
        rows: items.map((item) {
          final id = idOf(item);
          return DataRow(
            selected: selected.contains(id),
            onSelectChanged:
                onToggleSelect == null ? null : (_) => onToggleSelect!(id),
            cells: [
              if (onToggleSelect != null)
                DataCell(Checkbox(
                    value: selected.contains(id),
                    onChanged: (_) => onToggleSelect!(id))),
              ...columns.map((column) => DataCell(column.build(item))),
              if (actions != null)
                DataCell(Row(
                    mainAxisSize: MainAxisSize.min, children: actions!(item))),
            ],
          );
        }).toList(),
      ),
    );
  }

  int? get _sortColumnIndex {
    if (sortField == null) return null;
    final index = columns.indexWhere((column) => column.sortField == sortField);
    if (index == -1) return null;
    return index + (onToggleSelect == null ? 0 : 1);
  }
}

class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int size;
  final ValueChanged<int> onSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.size,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        IconButton(
          tooltip: 'Первая страница',
          onPressed: page > 1 ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая страница',
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Страница $page из $totalPages'),
        IconButton(
          tooltip: 'Следующая страница',
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя страница',
          onPressed: page < totalPages ? () => onPageChanged(totalPages) : null,
          icon: const Icon(Icons.last_page),
        ),
        DropdownButton<int>(
          value: size,
          items: const [10, 25, 50]
              .map((value) => DropdownMenuItem(
                  value: value, child: Text('$value на странице')))
              .toList(),
          onChanged: (value) {
            if (value != null) onSizeChanged(value);
          },
        ),
      ],
    );
  }
}
