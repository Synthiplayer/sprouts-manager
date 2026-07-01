part of '../planning_screen.dart';

extension on _PlanningScreenState {
  static const List<BuildingBlockCategory> _planningCatalogCategories = [
    BuildingBlockCategory.location,
    BuildingBlockCategory.technology,
    BuildingBlockCategory.program,
    BuildingBlockCategory.staff,
    BuildingBlockCategory.cost,
  ];

  Widget _buildPlanningCardCatalog(BuildContext context, PlanningDraft draft) {
    return ValueListenableBuilder<List<BuildingBlock>>(
      valueListenable: buildingBlockCatalogStore,
      builder: (context, blocks, _) {
        return _sectionCard(
          context,
          title: 'Bausteine',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final category in _planningCatalogCategories)
                _catalogGroup(
                  context,
                  title: category.label,
                  color: category.color,
                  initiallyExpanded:
                      category == BuildingBlockCategory.location ||
                          category == BuildingBlockCategory.technology ||
                          category == BuildingBlockCategory.program ||
                          category == BuildingBlockCategory.staff ||
                          category == BuildingBlockCategory.cost,
                  children: _catalogCardsForCategory(
                    context,
                    draft,
                    blocks,
                    category,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _catalogCardsForCategory(
    BuildContext context,
    PlanningDraft draft,
    List<BuildingBlock> blocks,
    BuildingBlockCategory category,
  ) {
    final categoryBlocks = blocks
        .where((block) => block.category == category)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (categoryBlocks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Noch keine Bausteine angelegt.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ];
    }

    return [
      for (final block in categoryBlocks)
        _catalogCard(
          context,
          title: block.name,
          category: block.category.label,
          amountLabel: _buildingBlockAmountLabel(block),
          color: block.category.color,
          onAdd: () => _addBuildingBlockToPlanning(draft, block),
        ),
    ];
  }

  String _buildingBlockAmountLabel(BuildingBlock block) {
    final amountEur = _buildingBlockAmountEur(block);
    if (amountEur <= 0) {
      return block.note.isEmpty ? 'Preis offen' : block.note;
    }
    return formatEuro(amountEur);
  }

  double _buildingBlockAmountEur(BuildingBlock block) {
    if (block.category != BuildingBlockCategory.location ||
        block.areas.isEmpty) {
      return block.defaultAmountEur;
    }

    final selectedAreaNames = block.selectedAreaNames.isEmpty
        ? {block.areas.first.name}
        : block.selectedAreaNames;
    final selectedAreas = block.areas
        .where((area) => selectedAreaNames.contains(area.name))
        .toList();
    if (selectedAreas.isEmpty) {
      return block.defaultAmountEur;
    }

    return selectedAreas.fold<double>(
      0,
      (total, area) => total + area.amountEur,
    );
  }

  void _addBuildingBlockToPlanning(
    PlanningDraft draft,
    BuildingBlock block,
  ) {
    switch (block.category) {
      case BuildingBlockCategory.location:
        _selectLocationBlock(draft, block);
        break;
      case BuildingBlockCategory.technology:
        _addTechnologyCatalogItem(
          draft,
          label: block.name,
          type: _technologyTypeForBuildingBlock(block),
          amountEur: block.defaultAmountEur,
          buildingBlockId: block.id,
        );
        break;
      case BuildingBlockCategory.program:
        _addProgramCatalogItem(
          draft,
          label: block.name,
          type: _programTypeForBuildingBlock(block),
          amountEur: block.defaultAmountEur,
          buildingBlockId: block.id,
        );
        break;
      case BuildingBlockCategory.staff:
        _addStaffBuildingBlockToPlanning(draft, block);
        break;
      case BuildingBlockCategory.cost:
        _addCostBuildingBlockToPlanning(draft, block);
        break;
      case BuildingBlockCategory.special:
        break;
    }
  }

  void _addCostBuildingBlockToPlanning(
    PlanningDraft draft,
    BuildingBlock block,
  ) {
    final costKey = _costKeyForBuildingBlock(block);
    final amountEur = _buildingBlockAmountEur(block);

    _refreshPlanningUi(() {
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = block.name;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = amountEur;
    });
    _savePlanningSandboxState();
  }

  void _addStaffBuildingBlockToPlanning(
    PlanningDraft draft,
    BuildingBlock block,
  ) {
    final costKey = _newStaffCostKeyForBuildingBlock(block);

    _refreshPlanningUi(() {
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = block.name;
      _staffPeopleCountOverrides[_costPositionOverrideKey(draft, costKey)] = 1;
      _staffHoursOverrides[_costPositionOverrideKey(draft, costKey)] = 1;
      _staffHourlyRateOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = block.defaultAmountEur;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = block.defaultAmountEur;
    });
    _savePlanningSandboxState();
  }

  PlanningTechnologyCostType _technologyTypeForBuildingBlock(
    BuildingBlock block,
  ) {
    final name = block.name.toLowerCase();
    if (name.contains('ton') || name.contains('anlage')) {
      return PlanningTechnologyCostType.sound;
    }
    if (name.contains('licht')) {
      return PlanningTechnologyCostType.light;
    }
    if (name.contains('bühne') || name.contains('buehne')) {
      return PlanningTechnologyCostType.stage;
    }
    if (name.contains('beamer') || name.contains('leinwand')) {
      return PlanningTechnologyCostType.screenProjector;
    }
    return PlanningTechnologyCostType.other;
  }

  PlanningArtistCostType _programTypeForBuildingBlock(BuildingBlock block) {
    final name = block.name.toLowerCase();
    if (name.contains('dj')) {
      return PlanningArtistCostType.djFee;
    }
    if (name.contains('film') || name.contains('lizenz')) {
      return PlanningArtistCostType.filmLicense;
    }
    return PlanningArtistCostType.other;
  }

  Widget _catalogCard(
    BuildContext context, {
    required String title,
    required String category,
    required String amountLabel,
    required Color color,
    required VoidCallback onAdd,
  }) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      amountLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Zur Planung hinzufügen',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );

    return Draggable<_PlanningCatalogDragData>(
      data: _PlanningCatalogDragData(onDrop: onAdd),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 300,
          child: _catalogCardView(
            context,
            title: title,
            category: category,
            amountLabel: amountLabel,
            color: color,
            onAdd: null,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.45,
        child: _catalogCardView(
          context,
          title: title,
          category: category,
          amountLabel: amountLabel,
          color: color,
          onAdd: null,
        ),
      ),
      child: card,
    );
  }

  Widget _catalogCardView(
    BuildContext context, {
    required String title,
    required String category,
    required String amountLabel,
    required Color color,
    required VoidCallback? onAdd,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category  $amountLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Zur Planung hinzufügen',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _catalogGroup(
    BuildContext context, {
    required String title,
    required Color color,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          iconColor: color,
          collapsedIconColor: color,
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildPlanningBox(
    BuildContext context,
    PlanningDraft draft,
    List<PlanningBoxItem> items,
  ) {
    final fixedTotal = items
        .where((item) => !item.isVariable)
        .fold<double>(0, (total, item) => total + item.amountEur);
    final variableTotal = items
        .where((item) => item.isVariable)
        .fold<double>(0, (total, item) => total + item.amountEur);
    final total = fixedTotal + variableTotal;

    return DragTarget<_PlanningCatalogDragData>(
      onAcceptWithDetails: (details) => details.data.onDrop(),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: _sectionCard(
            context,
            title: isActive ? 'Planungsbox - hier loslassen' : 'Planungsbox',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _compactInfoPair(
                      context,
                      'Fixe Kosten',
                      formatEuro(fixedTotal),
                    ),
                    _compactInfoPair(
                      context,
                      'Variable Kosten',
                      formatEuro(variableTotal),
                    ),
                    _compactInfoPair(
                      context,
                      'Summe Eventkosten',
                      formatEuro(total),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Text('Noch keine Karten in der Planungsbox.')
                else
                  for (final group in _orderedPlanningBoxGroups(items))
                    _planningBoxGroup(
                      context,
                      draft,
                      group,
                      items
                          .where(
                            (item) => item.category == group,
                          )
                          .toList(),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PlanningBoxItemCategory> _orderedPlanningBoxGroups(
    List<PlanningBoxItem> items,
  ) {
    const preferredOrder = [
      PlanningBoxItemCategory.location,
      PlanningBoxItemCategory.technology,
      PlanningBoxItemCategory.program,
      PlanningBoxItemCategory.staff,
      PlanningBoxItemCategory.cost,
    ];
    final activeGroups = items.map((item) => item.category).toSet();

    return [
      for (final group in preferredOrder)
        if (activeGroups.contains(group)) group,
      for (final group in activeGroups)
        if (!preferredOrder.contains(group)) group,
    ];
  }

  Widget _planningBoxGroup(
    BuildContext context,
    PlanningDraft draft,
    PlanningBoxItemCategory group,
    List<PlanningBoxItem> items,
  ) {
    final color = _planningBoxCategoryColor(group);
    final total = items.fold<double>(0, (sum, item) => sum + item.amountEur);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Icon(_planningBoxCategoryIcon(group), color: color),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                formatEuro(total),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          children: [
            for (final item in items) _planningBoxRow(context, draft, item),
          ],
        ),
      ),
    );
  }

  Widget _planningBoxRow(
    BuildContext context,
    PlanningDraft draft,
    PlanningBoxItem item,
  ) {
    final color = _planningBoxCategoryColor(item.category);
    final detailLines = [
      item.description.trim(),
      item.calculationHint.trim(),
    ].where((line) => line.isNotEmpty).toList();

    return GestureDetector(
      onTap:
          item.canEdit ? () => _editPlanningBoxItem(context, draft, item) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(
              _planningBoxCategoryIcon(item.category),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final line in detailLines) ...[
                    const SizedBox(height: 2),
                    Text(line, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatEuro(item.amountEur),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Betrag ändern',
              onPressed: item.canEdit
                  ? () => _editPlanningBoxItem(context, draft, item)
                  : null,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: item.canRemove
                  ? 'Position entfernen'
                  : 'Diese Position kommt aktuell aus dem Szenario',
              onPressed: item.canRemove
                  ? () => _removePlanningBoxItem(draft, item)
                  : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPlanningBoxItem(
    BuildContext context,
    PlanningDraft draft,
    PlanningBoxItem item,
  ) async {
    switch (item.kind) {
      case PlanningBoxItemKind.costPosition:
        await _showCostPositionEditDialog(
          context,
          draft,
          item,
        );
        return;
      case PlanningBoxItemKind.technologyDetail:
        final technologyItem = _technologyItemById(draft, item.detailItemId);
        if (technologyItem == null) {
          return;
        }
        await _showEditTechnologyCardDialog(draft, technologyItem);
        return;
      case PlanningBoxItemKind.programDetail:
        final programItem = _programItemById(draft, item.detailItemId);
        if (programItem == null) {
          return;
        }
        await _showEditProgramCardDialog(draft, programItem);
        return;
    }
  }

  void _removePlanningBoxItem(PlanningDraft draft, PlanningBoxItem item) {
    switch (item.kind) {
      case PlanningBoxItemKind.costPosition:
        _removeCostPosition(draft, item.costKey);
        return;
      case PlanningBoxItemKind.technologyDetail:
        _removeTechnologyItem(draft, item.detailItemId);
        return;
      case PlanningBoxItemKind.programDetail:
        _removeProgramItem(draft, item.detailItemId);
        return;
    }
  }

  Color _planningBoxCategoryColor(PlanningBoxItemCategory category) {
    switch (category) {
      case PlanningBoxItemCategory.location:
        return Colors.blueGrey;
      case PlanningBoxItemCategory.technology:
        return Colors.indigo;
      case PlanningBoxItemCategory.program:
        return Colors.deepPurple;
      case PlanningBoxItemCategory.staff:
        return Colors.deepOrange;
      case PlanningBoxItemCategory.cost:
        return Colors.green;
    }
  }

  IconData _planningBoxCategoryIcon(PlanningBoxItemCategory category) {
    switch (category) {
      case PlanningBoxItemCategory.location:
        return Icons.location_on_outlined;
      case PlanningBoxItemCategory.technology:
        return Icons.tune;
      case PlanningBoxItemCategory.program:
        return Icons.theater_comedy_outlined;
      case PlanningBoxItemCategory.staff:
        return Icons.groups_outlined;
      case PlanningBoxItemCategory.cost:
        return Icons.receipt_long_outlined;
    }
  }

  Widget _compactInfoPair(
    BuildContext context,
    String label,
    String value,
  ) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
