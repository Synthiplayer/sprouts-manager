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
    final visibleBlocks = _sortedBlocks(
      _categoryFilter == null
          ? blocks
          : blocks
              .where((block) => block.category == _categoryFilter)
              .toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Bausteine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
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

  List<BuildingBlock> _sortedBlocks(List<BuildingBlock> blocks) {
    final sortedBlocks = [...blocks];
    sortedBlocks.sort(_compareBuildingBlocks);
    return sortedBlocks;
  }

  int _compareBuildingBlocks(BuildingBlock a, BuildingBlock b) {
    final categoryComparison = _categorySortIndex(
      a.category,
    ).compareTo(_categorySortIndex(b.category));
    if (categoryComparison != 0) {
      return categoryComparison;
    }

    final nameComparison = a.name.toLowerCase().compareTo(
      b.name.toLowerCase(),
    );
    if (nameComparison != 0) {
      return nameComparison;
    }

    return a.id.compareTo(b.id);
  }

  int _categorySortIndex(BuildingBlockCategory category) {
    return BuildingBlockCategory.values.indexOf(category);
  }

  Future<void> _showCreateDialog() async {
    final category = _categoryFilter ?? await _pickCategoryForNewBlock();
    if (category == null) {
      return;
    }

    await _showEditDialog(initialCategory: category);
  }

  Future<BuildingBlockCategory?> _pickCategoryForNewBlock() {
    return showDialog<BuildingBlockCategory>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategorie wählen'),
        content: SizedBox(
          width: 360,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in BuildingBlockCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: false,
                  onSelected: (_) => Navigator.of(dialogContext).pop(category),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
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
      block.copyWith(
        defaultAmountEur: _selectedAreaAmount(
          block.areas,
          selectedAreaNames,
          block.defaultAmountEur,
        ),
        selectedAreaNames: selectedAreaNames,
      ),
    );
  }
}

double _buildingBlockDisplayAmount(BuildingBlock block) {
  return _selectedAreaAmount(
    block.areas,
    block.selectedAreaNames,
    block.defaultAmountEur,
  );
}

double _selectedAreaAmount(
  List<BuildingBlockArea> areas,
  Set<String> selectedAreaNames,
  double fallbackAmountEur,
) {
  if (areas.isEmpty) {
    return fallbackAmountEur;
  }

  final effectiveSelection = selectedAreaNames.isEmpty
      ? {areas.first.name}
      : selectedAreaNames;
  var hasSelectedArea = false;
  var total = 0.0;
  for (final area in areas) {
    if (!effectiveSelection.contains(area.name)) {
      continue;
    }
    hasSelectedArea = true;
    total += area.amountEur;
  }

  return hasSelectedArea ? total : fallbackAmountEur;
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
    final displayAmountEur = _buildingBlockDisplayAmount(block);

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
                  displayAmountEur <= 0
                      ? 'Preis offen'
                      : formatEuro(displayAmountEur),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (block.costProfile == BuildingBlockCostProfile.gema &&
                    block.gemaConfig != null) ...[
                  Chip(
                    label: Text(block.gemaConfig!.musicType.label),
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: Text(block.gemaConfig!.audienceType.label),
                    side: BorderSide(color: color.withValues(alpha: 0.35)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
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
  late BuildingBlockCostProfile _costProfile;
  late GemaMusicType _gemaMusicType;
  late GemaAudienceType _gemaAudienceType;

  @override
  void initState() {
    super.initState();
    final current = widget.existing;
    _nameController = TextEditingController(text: current?.name ?? '');
    _nameController.addListener(_refreshGemaFields);
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
    _costProfile = current?.costProfile ?? BuildingBlockCostProfile.none;
    _gemaMusicType = current?.gemaConfig?.musicType ?? GemaMusicType.live;
    _gemaAudienceType =
        current?.gemaConfig?.audienceType ?? GemaAudienceType.public;
    for (final area in _areas) {
      _attachAreaListeners(area);
    }
    _syncDerivedAmount();
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.existing == null
                  ? 'Baustein anlegen'
                  : 'Baustein bearbeiten',
            ),
          ),
          _categoryBadge(context),
        ],
      ),
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
            TextField(
              controller: _amountController,
              readOnly: _derivesAmountFromAreas,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Standardbetrag brutto',
                helperText: _derivesAmountFromAreas
                    ? 'Bei Locations mit Bereichen aus der Vorauswahl berechnet.'
                    : null,
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
            if (_isGemaProfile) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<GemaMusicType>(
                initialValue: _gemaMusicType,
                decoration: const InputDecoration(
                  labelText: 'Musikart',
                  border: OutlineInputBorder(),
                ),
                items: GemaMusicType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type == null) {
                    return;
                  }
                  setState(() {
                    _gemaMusicType = type;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GemaAudienceType>(
                initialValue: _gemaAudienceType,
                decoration: const InputDecoration(
                  labelText: 'Gesellschaft',
                  border: OutlineInputBorder(),
                ),
                items: GemaAudienceType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type == null) {
                    return;
                  }
                  setState(() {
                    _gemaAudienceType = type;
                  });
                },
              ),
            ],
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

  Widget _categoryBadge(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _changeCategory,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _category.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _category.color.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _category.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _category.color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more,
              size: 16,
              color: _category.color,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCategory() async {
    final selected = await showDialog<BuildingBlockCategory>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategorie wählen'),
        content: SizedBox(
          width: 360,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in BuildingBlockCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: category == _category,
                  onSelected: (_) => Navigator.of(dialogContext).pop(category),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (selected == null || selected == _category) {
      return;
    }

    setState(() {
      _category = selected;
      if (_category != BuildingBlockCategory.cost) {
        _costProfile = BuildingBlockCostProfile.none;
      }
      _syncDerivedAmount();
    });
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
    final effectiveSelectedAreaNames =
        selectedAreaNames.isEmpty && areas.isNotEmpty
            ? {areas.first.name}
            : selectedAreaNames;
    final defaultAmountEur =
        _category == BuildingBlockCategory.location && areas.isNotEmpty
            ? _selectedAreaAmount(
                areas,
                effectiveSelectedAreaNames,
                _parseAmount(_amountController.text),
              )
            : _parseAmount(_amountController.text);

    Navigator.of(context).pop(
      BuildingBlock(
        id: widget.existing?.id ??
            'block-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        category: _category,
        costProfile:
            _isGemaProfile
                ? BuildingBlockCostProfile.gema
                : BuildingBlockCostProfile.none,
        defaultAmountEur: defaultAmountEur,
        note: _noteController.text.trim(),
        areas: areas,
        selectedAreaNames: effectiveSelectedAreaNames,
        gemaConfig: _isGemaProfile
            ? BuildingBlockGemaConfig(
                musicType: _gemaMusicType,
                audienceType: _gemaAudienceType,
              )
            : null,
      ),
    );
  }

  void _addArea() {
    setState(() {
      final area = _EditableBuildingBlockArea.empty();
      _attachAreaListeners(area);
      _areas.add(area);
      _syncDerivedAmount();
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
                    _syncDerivedAmount();
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

  bool get _derivesAmountFromAreas {
    return _category == BuildingBlockCategory.location && _areas.isNotEmpty;
  }

  bool get _isGemaProfile {
    return _category == BuildingBlockCategory.cost &&
        (_costProfile == BuildingBlockCostProfile.gema ||
            _nameController.text.trim().toLowerCase() == 'gema');
  }

  void _refreshGemaFields() {
    if (!mounted || _category != BuildingBlockCategory.cost) {
      return;
    }
    setState(() {});
  }

  void _attachAreaListeners(_EditableBuildingBlockArea area) {
    area.nameController.addListener(_syncDerivedAmount);
    area.amountController.addListener(_syncDerivedAmount);
  }

  void _syncDerivedAmount() {
    if (!_derivesAmountFromAreas) {
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
    final effectiveSelectedAreaNames =
        selectedAreaNames.isEmpty && areas.isNotEmpty
            ? {areas.first.name}
            : selectedAreaNames;
    final amount = _selectedAreaAmount(
      areas,
      effectiveSelectedAreaNames,
      _parseAmount(_amountController.text),
    );
    final text = _editableMoneyValue(amount);
    if (_amountController.text != text) {
      _amountController.text = text;
    }
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
