import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/features/building_blocks/domain/building_block_catalog.dart';

class BuildingBlockLibraryScreen extends StatefulWidget {
  const BuildingBlockLibraryScreen({super.key});

  @override
  State<BuildingBlockLibraryScreen> createState() =>
      _BuildingBlockLibraryScreenState();
}

class _BuildingBlockLibraryScreenState
    extends State<BuildingBlockLibraryScreen> {
  BuildingBlockCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    buildingBlockCatalogStore.addListener(_refresh);
    buildingBlockCatalogStore.load();
  }

  @override
  void dispose() {
    buildingBlockCatalogStore.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = buildingBlockCatalogStore.value;
    final visibleBlocks = _categoryFilter == null
        ? blocks
        : blocks
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
              for (final category in BuildingBlockCategory.values)
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
                      onAreaSelectionChanged: (areaName, selected) {
                        _setAreaSelected(block, areaName, selected);
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog({
    BuildingBlock? existing,
    BuildingBlockCategory? initialCategory,
  }) async {
    final result = await showDialog<BuildingBlock>(
      context: context,
      builder: (_) => _BuildingBlockEditDialog(
        existing: existing,
        initialCategory: initialCategory,
      ),
    );

    if (result == null) {
      return;
    }

    buildingBlockCatalogStore.upsert(result);
  }

  Future<void> _deleteBlock(BuildingBlock block) async {
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

    buildingBlockCatalogStore.delete(block.id);
  }

  void _setAreaSelected(
    BuildingBlock block,
    String areaName,
    bool selected,
  ) {
    final selectedAreaNames = {...block.selectedAreaNames};
    if (!selected &&
        selectedAreaNames.length == 1 &&
        selectedAreaNames.contains(areaName)) {
      return;
    }
    if (selected) {
      selectedAreaNames.add(areaName);
    } else {
      selectedAreaNames.remove(areaName);
    }

    buildingBlockCatalogStore.upsert(
      block.copyWith(selectedAreaNames: selectedAreaNames),
    );
  }
}

class _BuildingBlockCard extends StatelessWidget {
  final BuildingBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String areaName, bool selected) onAreaSelectionChanged;

  const _BuildingBlockCard({
    required this.block,
    required this.onEdit,
    required this.onDelete,
    required this.onAreaSelectionChanged,
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
            if (block.areas.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final area in block.areas)
                    _BuildingBlockAreaChip(
                      area: area,
                      color: color,
                      selected: block.selectedAreaNames.contains(area.name),
                      onSelected: (selected) =>
                          onAreaSelectionChanged(area.name, selected),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuildingBlockAreaChip extends StatelessWidget {
  final BuildingBlockArea area;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _BuildingBlockAreaChip({
    required this.area,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      showCheckmark: true,
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      selectedColor: color.withValues(alpha: 0.16),
      onSelected: onSelected,
      label: Text(
        area.amountEur <= 0
            ? '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m² · Preis offen'
            : '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m² · ${formatEuro(area.amountEur)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BuildingBlockEditDialog extends StatefulWidget {
  final BuildingBlock? existing;
  final BuildingBlockCategory? initialCategory;

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
  late List<_EditableBuildingBlockArea> _areas;
  late BuildingBlockCategory _category;

  @override
  void initState() {
    super.initState();
    final current = widget.existing;
    _nameController = TextEditingController(text: current?.name ?? '');
    _amountController = TextEditingController(
      text: _editableMoneyValue(current?.defaultAmountEur ?? 0),
    );
    _noteController = TextEditingController(text: current?.note ?? '');
    _areas = [
      for (final area in current?.areas ?? const <BuildingBlockArea>[])
        _EditableBuildingBlockArea.fromArea(area),
    ];
    _category = current?.category ??
        widget.initialCategory ??
        BuildingBlockCategory.technology;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final area in _areas) {
      area.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Baustein anlegen' : 'Baustein bearbeiten'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
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
            DropdownButtonFormField<BuildingBlockCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: BuildingBlockCategory.values
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
            if (_category == BuildingBlockCategory.location) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bereiche',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addArea,
                    icon: const Icon(Icons.add),
                    label: const Text('Bereich hinzufügen'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_areas.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Noch keine Bereiche angelegt.'),
                )
              else
                for (var index = 0; index < _areas.length; index++)
                  _areaEditor(index),
            ],
          ],
          ),
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
    final areas = [
      for (final area in _areas)
        if (area.nameController.text.trim().isNotEmpty)
          BuildingBlockArea(
            name: area.nameController.text.trim(),
            squareMeters: _parseAmount(area.squareMetersController.text),
            amountEur: _parseAmount(area.amountController.text),
          ),
    ];
    final selectedAreaNames = {
      for (final area in areas)
        if (widget.existing?.selectedAreaNames.contains(area.name) ?? true)
          area.name,
    };

    Navigator.of(context).pop(
      BuildingBlock(
        id: widget.existing?.id ??
            'block-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: _category,
        defaultAmountEur: _parseAmount(_amountController.text),
        note: _noteController.text.trim(),
        areas: areas,
        selectedAreaNames: selectedAreaNames.isEmpty && areas.isNotEmpty
            ? {areas.first.name}
            : selectedAreaNames,
      ),
    );
  }

  void _addArea() {
    setState(() {
      _areas.add(_EditableBuildingBlockArea.empty());
    });
  }

  Widget _areaEditor(int index) {
    final area = _areas[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: area.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bereich',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Bereich löschen',
                onPressed: () {
                  setState(() {
                    final removed = _areas.removeAt(index);
                    removed.dispose();
                  });
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: area.squareMetersController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fläche',
                    suffixText: 'm²',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: area.amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preis brutto',
                    suffixText: 'EUR',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
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

class _EditableBuildingBlockArea {
  final TextEditingController nameController;
  final TextEditingController squareMetersController;
  final TextEditingController amountController;

  _EditableBuildingBlockArea({
    required this.nameController,
    required this.squareMetersController,
    required this.amountController,
  });

  factory _EditableBuildingBlockArea.fromArea(BuildingBlockArea area) {
    return _EditableBuildingBlockArea(
      nameController: TextEditingController(text: area.name),
      squareMetersController: TextEditingController(
        text: _editableNumberValue(area.squareMeters),
      ),
      amountController: TextEditingController(
        text: _editableNumberValue(area.amountEur),
      ),
    );
  }

  factory _EditableBuildingBlockArea.empty() {
    return _EditableBuildingBlockArea(
      nameController: TextEditingController(),
      squareMetersController: TextEditingController(text: '0'),
      amountController: TextEditingController(text: '0'),
    );
  }

  void dispose() {
    nameController.dispose();
    squareMetersController.dispose();
    amountController.dispose();
  }

  static String _editableNumberValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
