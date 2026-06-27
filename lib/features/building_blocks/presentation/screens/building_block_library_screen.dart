import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';

enum _BuildingBlockCategory {
  location,
  technology,
  program,
  staff,
  cost,
  special,
}

extension on _BuildingBlockCategory {
  String get label {
    switch (this) {
      case _BuildingBlockCategory.location:
        return 'Location';
      case _BuildingBlockCategory.technology:
        return 'Technik';
      case _BuildingBlockCategory.program:
        return 'Programm';
      case _BuildingBlockCategory.staff:
        return 'Personal';
      case _BuildingBlockCategory.cost:
        return 'Kosten';
      case _BuildingBlockCategory.special:
        return 'Special';
    }
  }

  Color get color {
    switch (this) {
      case _BuildingBlockCategory.location:
        return Colors.blueGrey;
      case _BuildingBlockCategory.technology:
        return Colors.indigo;
      case _BuildingBlockCategory.program:
        return Colors.deepPurple;
      case _BuildingBlockCategory.staff:
        return Colors.deepOrange;
      case _BuildingBlockCategory.cost:
        return Colors.green;
      case _BuildingBlockCategory.special:
        return Colors.teal;
    }
  }

  IconData get icon {
    switch (this) {
      case _BuildingBlockCategory.location:
        return Icons.location_on_outlined;
      case _BuildingBlockCategory.technology:
        return Icons.settings_input_component_outlined;
      case _BuildingBlockCategory.program:
        return Icons.local_activity_outlined;
      case _BuildingBlockCategory.staff:
        return Icons.groups_outlined;
      case _BuildingBlockCategory.cost:
        return Icons.receipt_long_outlined;
      case _BuildingBlockCategory.special:
        return Icons.auto_awesome_outlined;
    }
  }
}

class _BuildingBlock {
  final String id;
  final String name;
  final _BuildingBlockCategory category;
  final double defaultAmountEur;
  final String note;

  const _BuildingBlock({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultAmountEur,
    required this.note,
  });
}

class BuildingBlockLibraryScreen extends StatefulWidget {
  const BuildingBlockLibraryScreen({super.key});

  @override
  State<BuildingBlockLibraryScreen> createState() =>
      _BuildingBlockLibraryScreenState();
}

class _BuildingBlockLibraryScreenState
    extends State<BuildingBlockLibraryScreen> {
  _BuildingBlockCategory? _categoryFilter;
  final List<_BuildingBlock> _blocks = [
    const _BuildingBlock(
      id: 'location-metropol',
      name: 'Metropol',
      category: _BuildingBlockCategory.location,
      defaultAmountEur: 3200,
      note: 'Locationprofil mit Halle, Kapazität und Standardmiete.',
    ),
    const _BuildingBlock(
      id: 'location-event-ship',
      name: 'Eventschiff',
      category: _BuildingBlockCategory.location,
      defaultAmountEur: 0,
      note: 'Sonderlocation, Preis und Setup je Anfrage.',
    ),
    const _BuildingBlock(
      id: 'technology-projector',
      name: 'Beamer',
      category: _BuildingBlockCategory.technology,
      defaultAmountEur: 180,
      note: 'Leihgerät für Kino, Seminar oder Präsentation.',
    ),
    const _BuildingBlock(
      id: 'program-dj',
      name: 'DJ',
      category: _BuildingBlockCategory.program,
      defaultAmountEur: 900,
      note: 'Programmpunkt mit Standardgage.',
    ),
    const _BuildingBlock(
      id: 'staff-barkeeper',
      name: 'Barkeeper',
      category: _BuildingBlockCategory.staff,
      defaultAmountEur: 0,
      note: 'Personalbaustein, Anzahl und Satz später je Planung.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleBlocks = _categoryFilter == null
        ? _blocks
        : _blocks
            .where((block) => block.category == _categoryFilter)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bausteine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(initialCategory: _categoryFilter),
        icon: const Icon(Icons.add),
        label: const Text('Baustein hinzufügen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hier entsteht die zentrale Sammlung für wiederverwendbare Planungskarten.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Alle'),
                selected: _categoryFilter == null,
                onSelected: (_) => setState(() => _categoryFilter = null),
              ),
              for (final category in _BuildingBlockCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: _categoryFilter == category,
                  onSelected: (_) =>
                      setState(() => _categoryFilter = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleBlocks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('Noch keine Bausteine in dieser Kategorie.'),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final block in visibleBlocks)
                  SizedBox(
                    width: 340,
                    child: _BuildingBlockCard(
                      block: block,
                      onEdit: () => _showEditDialog(existing: block),
                      onDelete: () => _deleteBlock(block),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog({
    _BuildingBlock? existing,
    _BuildingBlockCategory? initialCategory,
  }) async {
    final result = await showDialog<_BuildingBlock>(
      context: context,
      builder: (_) => _BuildingBlockEditDialog(
        existing: existing,
        initialCategory: initialCategory,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = _blocks.indexWhere((block) => block.id == result.id);
      if (index == -1) {
        _blocks.add(result);
      } else {
        _blocks[index] = result;
      }
    });
  }

  Future<void> _deleteBlock(_BuildingBlock block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Baustein löschen'),
        content: Text('${block.name} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _blocks.removeWhere((current) => current.id == block.id);
    });
  }
}

class _BuildingBlockCard extends StatelessWidget {
  final _BuildingBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BuildingBlockCard({
    required this.block,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = block.category.color;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(block.category.icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bearbeiten',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Löschen',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(block.category.label),
                  side: BorderSide(color: color.withValues(alpha: 0.55)),
                ),
                Text(
                  block.defaultAmountEur <= 0
                      ? 'Preis offen'
                      : formatEuro(block.defaultAmountEur),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (block.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(block.note),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuildingBlockEditDialog extends StatefulWidget {
  final _BuildingBlock? existing;
  final _BuildingBlockCategory? initialCategory;

  const _BuildingBlockEditDialog({
    this.existing,
    this.initialCategory,
  });

  @override
  State<_BuildingBlockEditDialog> createState() =>
      _BuildingBlockEditDialogState();
}

class _BuildingBlockEditDialogState extends State<_BuildingBlockEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late _BuildingBlockCategory _category;

  @override
  void initState() {
    super.initState();
    final current = widget.existing;
    _nameController = TextEditingController(text: current?.name ?? '');
    _amountController = TextEditingController(
      text: _editableMoneyValue(current?.defaultAmountEur ?? 0),
    );
    _noteController = TextEditingController(text: current?.note ?? '');
    _category = current?.category ??
        widget.initialCategory ??
        _BuildingBlockCategory.technology;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Baustein anlegen' : 'Baustein bearbeiten'),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_BuildingBlockCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: _BuildingBlockCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (category) {
                if (category == null) {
                  return;
                }
                setState(() => _category = category);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Standardbetrag brutto',
                suffixText: 'EUR',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      _BuildingBlock(
        id: widget.existing?.id ??
            'block-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: _category,
        defaultAmountEur: _parseAmount(_amountController.text),
        note: _noteController.text.trim(),
      ),
    );
  }

  double _parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    if (trimmed.contains(',') && trimmed.contains('.')) {
      return double.tryParse(
            trimmed.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0;
    }
    if (trimmed.contains(',')) {
      return double.tryParse(trimmed.replaceAll(',', '.')) ?? 0;
    }
    return double.tryParse(trimmed) ?? 0;
  }

  String _editableMoneyValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
