part of '../planning_screen.dart';

extension on _PlanningScreenState {
  static const List<BuildingBlockCategory> _planningCatalogCategories = [
    BuildingBlockCategory.location,
    BuildingBlockCategory.technology,
    BuildingBlockCategory.program,
    BuildingBlockCategory.staff,
    BuildingBlockCategory.cost,
  ];

  Widget _buildMainTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final earlyBirdPrice = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);
    final preEventBalance =
        _mainAvailableEventBudgetBeforeEvent(draft, scenario) -
            _scenarioEventCostsEur(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
            context,
            title: 'Main / Entscheidungsansicht',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _planningCategory(draft).toChip(filled: false),
                    _pill(context, _mainDecisionStatus(draft)),
                    _pill(context, scenario.name),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 14,
                  children: [
                    _infoPair('Projekt', draft.title),
                    _infoPair('Format', draft.format),
                    _infoPair('Zielgruppe', draft.targetAudience),
                    _infoPair('Location', _planningLocationName(draft, scenario)),
                    _infoPair('Setup', scenario.setupName),
                    _infoPair('Besucher Ziel', '${_scenarioTargetAttendees(scenario)}'),
                    _infoPair(
                      'Early-Bird bis Break-even',
                      '${earlyBirdPrice.round()} EVC / ${formatEuro(earlyBirdPrice)}',
                    ),
                    _infoPair(
                      'Normalpreis danach',
                      '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
                    ),
                    _infoPair(
                      preEventBalance >= 0
                          ? 'Puffer vor Veranstaltung'
                          : 'Fehlbetrag vor Veranstaltung',
                      formatEuro(preEventBalance),
                    ),
                    _infoPair(
                      'Feature-Budget danach',
                      formatEuro(
                        _featureBudgetAtTargetAfterBreakEven(draft, scenario),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_mainDecisionSummary(draft)),
              ],
            )),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Main / Kalkulationsabschluss',
          child: _buildCalculationMainOverview(
            context,
            draft,
            scenario,
            earlyBirdPrice: earlyBirdPrice,
            normalPrice: normalPrice,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final planningBoxItems = _planningBoxItemsForScenario(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Planungs-Konfiguration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<EventCategory>(
                      initialValue: _planningCategory(draft),
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: EventCategory.values
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
                        _refreshPlanningUi(() {
                          _draftCategoryOverrides[draft.id] = category;
                        });
                        _savePlanningSandboxState();
                      },
                    ),
                  ),
                  _infoPair('Mindestkapazitaet', '${draft.minimumCapacity}'),
                  _infoPair('Raumkonzept', draft.seatingMode),
                  _infoPair('Location', _planningLocationName(draft, scenario)),
                  _infoPair('Setup', scenario.setupName),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Die Planung nutzt Bausteine aus der zentralen Baustein-Verwaltung. Neue Location-, Technik-, Programm- oder Kostenkarten werden dort angelegt und erscheinen anschließend hier.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final catalog = _buildPlanningCardCatalog(context, draft);
            final planningBox = _buildPlanningBox(
              context,
              draft,
              planningBoxItems,
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  catalog,
                  const SizedBox(height: 12),
                  planningBox,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: catalog),
                const SizedBox(width: 12),
                Expanded(child: planningBox),
              ],
            );
          },
        ),
      ],
    );
  }

  double _mainAvailableEventBudgetBeforeEvent(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final income = _requiredGrossRevenueBeforeEvent(draft, scenario);
    final deductions = income *
        (_preEventSharePercent(draft) +
            _leakagePercent(draft) +
            _reservePercent(draft));
    return income - deductions;
  }

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
                  initiallyExpanded: category == BuildingBlockCategory.location ||
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
        _selectLocationScenario(draft, block.name);
        break;
      case BuildingBlockCategory.technology:
        _addTechnologyCatalogItem(
          draft,
          label: block.name,
          type: _technologyTypeForBuildingBlock(block),
          amountEur: block.defaultAmountEur,
          sourceBlockName: block.name,
        );
        break;
      case BuildingBlockCategory.program:
        _addProgramCatalogItem(
          draft,
          label: block.name,
          type: _programTypeForBuildingBlock(block),
          amountEur: block.defaultAmountEur,
          sourceBlockName: block.name,
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
    final costKey = _staffCostKeyForBuildingBlock(block);

    _refreshPlanningUi(() {
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, costKey)
      ] = block.name;
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
    final activeGroups = items
        .map((item) => item.category)
        .toSet();

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
    final showSource = item.source.isNotEmpty &&
        item.category != PlanningBoxItemCategory.location;

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
                  if (showSource) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.category.label} · ${item.source}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
          _costOverviewItemForPlanningBoxItem(item),
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

  PlanningCostOverviewItem _costOverviewItemForPlanningBoxItem(
    PlanningBoxItem item,
  ) {
    return PlanningCostOverviewItem(
      label: item.costKey,
      amountEur: item.amountEur,
      source: item.source,
      isVariable: item.isVariable,
    );
  }

  PlanningTechnologyCostItem? _technologyItemById(
    PlanningDraft draft,
    String? itemId,
  ) {
    if (itemId == null) {
      return null;
    }
    for (final item in _plannedTechnologyCostItemsForDraft(draft)) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  PlanningArtistCostItem? _programItemById(
    PlanningDraft draft,
    String? itemId,
  ) {
    if (itemId == null) {
      return null;
    }
    for (final item in _plannedArtistCostItemsForDraft(draft)) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  void _removeTechnologyItem(PlanningDraft draft, String? itemId) {
    if (itemId == null) {
      return;
    }
    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        for (final current in _plannedTechnologyCostItemsForDraft(draft))
          if (current.id != itemId) current,
      ];
    });
    _savePlanningSandboxState();
  }

  void _removeProgramItem(PlanningDraft draft, String? itemId) {
    if (itemId == null) {
      return;
    }
    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        for (final current in _plannedArtistCostItemsForDraft(draft))
          if (current.id != itemId) current,
      ];
    });
    _savePlanningSandboxState();
  }

  List<_PlanningLocationArea> _locationAreasForName(String locationName) {
    final locationBlock = _locationBuildingBlockForName(locationName);
    if (locationBlock == null) {
      return const [];
    }

    return [
      for (final area in locationBlock.areas)
        _PlanningLocationArea(
          name: area.name,
          squareMeters: area.squareMeters,
          amountEur: area.amountEur,
        ),
    ];
  }

  BuildingBlock? _locationBuildingBlockForName(String locationName) {
    for (final block in buildingBlockCatalogStore.value) {
      if (block.category == BuildingBlockCategory.location &&
          block.name == locationName) {
        return block;
      }
    }
    return null;
  }

  Set<String> _defaultLocationAreaNames(String locationName) {
    final block = _locationBuildingBlockForName(locationName);
    if (block == null || block.areas.isEmpty) {
      return {};
    }
    if (block.selectedAreaNames.isNotEmpty) {
      return {...block.selectedAreaNames};
    }
    return {block.areas.first.name};
  }

  double _locationAmountForAreaNames(
    String locationName,
    Set<String> selectedAreaNames,
    double fallbackAmountEur,
  ) {
    final block = _locationBuildingBlockForName(locationName);
    if (block == null || block.areas.isEmpty) {
      return fallbackAmountEur;
    }

    final selectedAreas = block.areas
        .where((area) => selectedAreaNames.contains(area.name))
        .toList();
    final areaAmount = selectedAreas.fold<double>(
      0,
      (total, area) => total + area.amountEur,
    );
    if (selectedAreas.isNotEmpty) {
      return areaAmount;
    }
    if (block.defaultAmountEur > 0) {
      return block.defaultAmountEur;
    }
    return fallbackAmountEur;
  }

  Future<void> _showCostPositionEditDialog(
    BuildContext context,
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) async {
    final currentLocationName = _planningLocationName(
      draft,
      _selectedScenario(draft),
    );
    final isLocationItem = item.label == 'Location / Halle';
    final displayLabel = _costPositionDisplayLabel(draft, item);
    final labelController = TextEditingController(
      text: isLocationItem
          ? currentLocationName
          : displayLabel,
    );
    final locationAreas = item.label == 'Location / Halle'
        ? _locationAreasForName(currentLocationName)
        : const <_PlanningLocationArea>[];
    final storedAreaNames = isLocationItem
        ? _locationAreaSelectionOverrides[draft.id] ??
            _defaultLocationAreaNames(currentLocationName)
        : null;
    final selectedAreaNames = {
      ...(storedAreaNames == null || storedAreaNames.isEmpty
          ? locationAreas.map((area) => area.name)
          : storedAreaNames),
    };
    final amountController = TextEditingController(
      text: _editableMoneyValue(
        item.amountEur,
      ),
    );

    final result = await showDialog<_CostPositionEditResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isLocationItem
                ? '$currentLocationName bearbeiten'
                : '$displayLabel bearbeiten',
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Betrag brutto',
                    suffixText: 'EUR',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(
                      _CostPositionEditResult(
                        label: labelController.text.trim(),
                        amountEur: parseEuroInput(value),
                        selectedAreaNames: selectedAreaNames,
                      ),
                    );
                  },
                ),
                if (locationAreas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bereiche',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final area in locationAreas)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selectedAreaNames.contains(area.name),
                      onChanged: selectedAreaNames.length == 1 &&
                              selectedAreaNames.contains(area.name)
                          ? null
                          : (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedAreaNames.add(area.name);
                                } else {
                                  selectedAreaNames.remove(area.name);
                                }
                                amountController.text = _editableMoneyValue(
                                  _locationAmountForAreaNames(
                                    currentLocationName,
                                    selectedAreaNames,
                                    parseEuroInput(amountController.text),
                                  ),
                                );
                              });
                            },
                      title: Text(
                        area.amountEur <= 0
                            ? '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m²'
                            : '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m² · ${formatEuro(area.amountEur)}',
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _CostPositionEditResult(
                    label: labelController.text.trim(),
                    amountEur: parseEuroInput(amountController.text),
                    selectedAreaNames: selectedAreaNames,
                  ),
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.amountEur < 0) {
      return;
    }

    _refreshPlanningUi(() {
      final label = result.label.isEmpty ? item.label : result.label;
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, item.label)
      ] = label;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, item.label)
      ] = result.amountEur;
      if (item.label == 'Location / Halle') {
        if (locationAreas.isEmpty) {
          _locationNameOverrides[draft.id] = label;
        } else {
          _locationNameOverrides.remove(draft.id);
        }
        if (locationAreas.isNotEmpty) {
          _locationAreaSelectionOverrides[draft.id] =
              result.selectedAreaNames.isEmpty
                  ? {locationAreas.first.name}
                  : result.selectedAreaNames;
        }
      }
    });
    _savePlanningSandboxState();
  }

  String _costPositionDisplayLabel(
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) {
    final overrideLabel = _costPositionLabelOverrides[
      _costPositionOverrideKey(draft, item.label)
    ];
    if (overrideLabel != null) {
      return overrideLabel;
    }
    if (item.label.startsWith(_staffCostKeyPrefix)) {
      return _planningBoxLabelForCostKey(
        draft,
        _selectedScenario(draft),
        item.label,
      );
    }
    return item.label;
  }

  void _selectLocationScenario(PlanningDraft draft, String locationName) {
    PlanningScenario? matchingScenario;
    for (final scenario in draft.scenarios) {
      if (scenario.locationName == locationName) {
        matchingScenario = scenario;
        break;
      }
    }

    if (matchingScenario == null) {
      _showCreateLocationCardDialog(draft, initialLabel: locationName);
      return;
    }

    final selectedScenario = matchingScenario;
    _refreshPlanningUi(() {
      _selectedScenarioOverrides[draft.id] = selectedScenario.id;
      _locationNameOverrides.remove(draft.id);
      _costPositionLabelOverrides.remove(
        _costPositionOverrideKey(draft, 'Location / Halle'),
      );
      final selectedAreaNames = _defaultLocationAreaNames(locationName);
      if (selectedAreaNames.isEmpty) {
        _locationAreaSelectionOverrides.remove(draft.id);
        _costPositionAmountOverrides.remove(
          _costPositionOverrideKey(draft, 'Location / Halle'),
        );
      } else {
        _locationAreaSelectionOverrides[draft.id] = selectedAreaNames;
        _costPositionAmountOverrides[
          _costPositionOverrideKey(draft, 'Location / Halle')
        ] = _locationAmountForAreaNames(
          locationName,
          selectedAreaNames,
          selectedScenario.baseRentEur,
        );
      }
    });
    _savePlanningSandboxState();
  }

  Future<void> _showCreateLocationCardDialog(
    PlanningDraft draft, {
    required String initialLabel,
  }) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Location bearbeiten',
      initialLabel: initialLabel,
      initialAmountEur: 0,
    );

    if (result == null) {
      return;
    }

    _applyLocationOverride(
      draft,
      label: result.label.isEmpty ? initialLabel : result.label,
      amountEur: result.amountEur,
    );
  }

  void _applyLocationOverride(
    PlanningDraft draft, {
    required String label,
    required double amountEur,
  }) {
    _refreshPlanningUi(() {
      _locationNameOverrides[draft.id] = label;
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, 'Location / Halle')
      ] = label;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, 'Location / Halle')
      ] = amountEur;
    });
    _savePlanningSandboxState();
  }

  Future<void> _showEditTechnologyCardDialog(
    PlanningDraft draft,
    PlanningTechnologyCostItem item,
  ) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Technik bearbeiten',
      initialLabel: item.label.isEmpty ? item.type.label : item.label,
      initialAmountEur: item.grossUnitAmountEur,
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        for (final current in _plannedTechnologyCostItemsForDraft(draft))
          if (current.id == item.id)
            current.copyWith(
              label: result.label.isEmpty ? current.label : result.label,
              grossUnitAmountEur: result.amountEur,
            )
          else
            current,
      ];
    });
    _savePlanningSandboxState();
  }

  Future<void> _showEditProgramCardDialog(
    PlanningDraft draft,
    PlanningArtistCostItem item,
  ) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Programm bearbeiten',
      initialLabel: item.label.isEmpty ? item.type.label : item.label,
      initialAmountEur: item.grossAmountEur,
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        for (final current in _plannedArtistCostItemsForDraft(draft))
          if (current.id == item.id)
            current.copyWith(
              label: result.label.isEmpty ? current.label : result.label,
              grossAmountEur: result.amountEur,
            )
          else
            current,
      ];
    });
    _savePlanningSandboxState();
  }

  Future<_CostPositionEditResult?> _showNameAmountDialog({
    required BuildContext context,
    required String title,
    required String initialLabel,
    required double initialAmountEur,
  }) async {
    final labelController = TextEditingController(text: initialLabel);
    final amountController = TextEditingController(
      text: _editableMoneyValue(initialAmountEur),
    );

    final result = await showDialog<_CostPositionEditResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Betrag brutto',
                suffixText: 'EUR',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(
                  _CostPositionEditResult(
                    label: labelController.text.trim(),
                    amountEur: parseEuroInput(value),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _CostPositionEditResult(
                  label: labelController.text.trim(),
                  amountEur: parseEuroInput(amountController.text),
                ),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == null || result.amountEur < 0) {
      return null;
    }

    return result;
  }

  void _addTechnologyCatalogItem(
    PlanningDraft draft, {
    required String label,
    required PlanningTechnologyCostType type,
    required double amountEur,
    required String sourceBlockName,
  }) {
    final currentItems = [..._plannedTechnologyCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningTechnologyCostItem(
          id: 'technology-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          quantity: 1,
          grossUnitAmountEur: amountEur,
          note: sourceBlockName,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _addProgramCatalogItem(
    PlanningDraft draft, {
    required String label,
    required PlanningArtistCostType type,
    required double amountEur,
    required String sourceBlockName,
  }) {
    final currentItems = [..._plannedArtistCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningArtistCostItem(
          id: 'program-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          grossAmountEur: amountEur,
          note: sourceBlockName,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _removeCostPosition(
    PlanningDraft draft,
    String label,
  ) {
    _refreshPlanningUi(() {
      _costPositionLabelOverrides.remove(_costPositionOverrideKey(draft, label));
      _costPositionAmountOverrides.remove(_costPositionOverrideKey(draft, label));
    });
    _savePlanningSandboxState();
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
        return Icons.settings_input_component_outlined;
      case PlanningBoxItemCategory.program:
        return Icons.local_activity_outlined;
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
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
