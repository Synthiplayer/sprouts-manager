part of '../planning_screen.dart';

class _PlanningCatalogDragData {
  final VoidCallback onDrop;

  const _PlanningCatalogDragData({required this.onDrop});
}

class _CostPositionEditResult {
  final String label;
  final double amountEur;
  final Set<String> selectedAreaNames;

  const _CostPositionEditResult({
    required this.label,
    required this.amountEur,
    this.selectedAreaNames = const {},
  });
}

class _PlanningLocationArea {
  final String name;
  final double squareMeters;

  const _PlanningLocationArea({
    required this.name,
    required this.squareMeters,
  });
}

extension on _PlanningScreenState {
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
    final costItems = _costOverviewItemsForScenario(draft, scenario);

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
                'Die alte Chip-Logik ist hier raus. Ab jetzt wird die Planung über Karten aufgebaut, die automatisch als Location, Technik, Programm, Personal oder Kostenposition einsortiert werden.',
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
              costItems,
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
    return _sectionCard(
      context,
      title: 'Karten-Bibliothek',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _catalogGroup(
            context,
            title: 'Location',
            color: Colors.blueGrey,
            initiallyExpanded: true,
            children: [
          _catalogCard(
            context,
            title: 'Metropol',
            category: 'Location',
            amountLabel: 'Locationprofil',
            color: Colors.blueGrey,
            onAdd: () => _selectLocationScenario(draft, 'Metropol'),
          ),
          _catalogCard(
            context,
            title: 'Eventschiff',
            category: 'Location',
            amountLabel: 'Sonderlocation',
            color: Colors.blueGrey,
            onAdd: () => _showCreateLocationCardDialog(
              draft,
              initialLabel: 'Eventschiff',
            ),
          ),
          _catalogCard(
            context,
            title: 'Freie Location',
            category: 'Location',
            amountLabel: 'editierbar',
            color: Colors.blueGrey,
            onAdd: () => _showCreateLocationCardDialog(
              draft,
              initialLabel: 'Neue Location',
            ),
          ),
            ],
          ),
          _catalogGroup(
            context,
            title: 'Technik',
            color: Colors.indigo,
            initiallyExpanded: true,
            children: [
          _catalogCard(
            context,
            title: 'Beamer',
            category: 'Technik',
            amountLabel: '180 EUR',
            color: Colors.indigo,
            onAdd: () => _addTechnologyCatalogItem(
              draft,
              label: 'Beamer',
              type: PlanningTechnologyCostType.screenProjector,
              amountEur: 180,
            ),
          ),
          _catalogCard(
            context,
            title: 'Leinwand',
            category: 'Technik',
            amountLabel: '120 EUR',
            color: Colors.indigo,
            onAdd: () => _addTechnologyCatalogItem(
              draft,
              label: 'Leinwand',
              type: PlanningTechnologyCostType.screenProjector,
              amountEur: 120,
            ),
          ),
          _catalogCard(
            context,
            title: 'Kleine Tonanlage',
            category: 'Technik',
            amountLabel: '150 EUR',
            color: Colors.indigo,
            onAdd: () => _addTechnologyCatalogItem(
              draft,
              label: 'Kleine Tonanlage',
              type: PlanningTechnologyCostType.sound,
              amountEur: 150,
            ),
          ),
          _catalogCard(
            context,
            title: 'Freie Technik',
            category: 'Technik',
            amountLabel: 'editierbar',
            color: Colors.indigo,
            onAdd: () => _showCreateTechnologyCardDialog(draft),
          ),
            ],
          ),
          _catalogGroup(
            context,
            title: 'Programm',
            color: Colors.deepPurple,
            initiallyExpanded: true,
            children: [
          _catalogCard(
            context,
            title: 'DJ',
            category: 'Programm',
            amountLabel: '900 EUR',
            color: Colors.deepPurple,
            onAdd: () => _addProgramCatalogItem(
              draft,
              label: 'DJ',
              type: PlanningArtistCostType.djFee,
              amountEur: 900,
            ),
          ),
          _catalogCard(
            context,
            title: 'Filmrechte',
            category: 'Programm',
            amountLabel: '350 EUR',
            color: Colors.red,
            onAdd: () => _addProgramCatalogItem(
              draft,
              label: 'Filmrechte / Vorführlizenz',
              type: PlanningArtistCostType.filmLicense,
              amountEur: 350,
            ),
          ),
          _catalogCard(
            context,
            title: 'Freies Programm',
            category: 'Programm',
            amountLabel: 'editierbar',
            color: Colors.deepPurple,
            onAdd: () => _showCreateProgramCardDialog(draft),
          ),
            ],
          ),
          _catalogGroup(
            context,
            title: 'Personal',
            color: Colors.deepOrange,
            children: [
          _catalogCard(
            context,
            title: 'Barkeeper',
            category: 'Personal',
            amountLabel: 'editierbar',
            color: Colors.deepOrange,
            onAdd: () => _showPlaceholderDialog(
              context,
              title: 'Personal-Karte',
              message:
                  'Personal-Karten bekommen als nächstes Personen, Stunden, Satz, Abgabenhinweis und ein Löschsymbol.',
            ),
          ),
          _catalogCard(
            context,
            title: 'Freies Personal',
            category: 'Personal',
            amountLabel: 'editierbar',
            color: Colors.deepOrange,
            onAdd: () => _showPlaceholderDialog(
              context,
              title: 'Freie Personal-Karte',
              message:
                  'Freie Personal-Karten bekommen als nächstes Name, Personen, Stunden, Satz und Abgabenhinweis.',
            ),
          ),
            ],
          ),
          _catalogGroup(
            context,
            title: 'Freie Kosten',
            color: Colors.green,
            children: [
              _catalogCard(
                context,
                title: 'Freie Position',
                category: 'Kosten',
                amountLabel: 'editierbar',
                color: Colors.green,
                onAdd: () => _showPlaceholderDialog(
                  context,
                  title: 'Freie Karte',
                  message:
                      'Freie Karten bekommen als nächstes Bezeichnung, Kategorie, Betrag und Notiz.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    List<PlanningCostOverviewItem> items,
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
                            (item) => _costPositionGroup(item.label) == group,
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

  List<String> _orderedPlanningBoxGroups(List<PlanningCostOverviewItem> items) {
    const preferredOrder = [
      'Location',
      'Technik',
      'Programm',
      'Personal',
      'Kosten',
    ];
    final activeGroups = items
        .map((item) => _costPositionGroup(item.label))
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
    String group,
    List<PlanningCostOverviewItem> items,
  ) {
    final color = _costGroupColor(group);
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
          leading: Icon(_costGroupIcon(group), color: color),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group,
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
            ..._planningBoxGroupRows(context, draft, group, items),
          ],
        ),
      ),
    );
  }

  List<Widget> _planningBoxGroupRows(
    BuildContext context,
    PlanningDraft draft,
    String group,
    List<PlanningCostOverviewItem> items,
  ) {
    if (group == 'Technik') {
      final technologyItems = _technologyCostItemsForDraft(draft);
      if (technologyItems.isNotEmpty) {
        return [
          for (final item in technologyItems)
            _technologyPlanningBoxRow(context, draft, item),
        ];
      }
    }

    if (group == 'Programm') {
      final programItems = _artistCostItemsForDraft(draft);
      if (programItems.isNotEmpty) {
        return [
          for (final item in programItems)
            _programPlanningBoxRow(context, draft, item),
        ];
      }
    }

    return [
      for (final item in items) _planningBoxRow(context, draft, item),
    ];
  }

  Widget _planningBoxRow(
    BuildContext context,
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) {
    final color = _costPositionColor(item.label);
    final canRemove = _canRemoveCostPosition(item.label);
    final displayLabel = item.label == 'Location / Halle'
        ? _planningLocationName(draft, _selectedScenario(draft))
        : _costPositionDisplayLabel(draft, item);
    final showSource = item.label != 'Location / Halle';

    return GestureDetector(
      onTap: () => _showCostPositionEditDialog(context, draft, item),
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
          Icon(_costPositionIcon(item.label), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (showSource) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_costPositionGroup(item.label)} · ${item.source}',
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
            onPressed: () => _showCostPositionEditDialog(
              context,
              draft,
              item,
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: canRemove
                ? 'Position entfernen'
                : 'Diese Position kommt aktuell aus dem Szenario',
            onPressed: canRemove
                ? () => _removeCostPosition(draft, item.label)
                : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      ),
    );
  }

  Widget _technologyPlanningBoxRow(
    BuildContext context,
    PlanningDraft draft,
    PlanningTechnologyCostItem item,
  ) {
    return _detailPlanningBoxRow(
      context,
      label: item.label.isEmpty ? item.type.label : item.label,
      amountEur: item.grossTotalEur,
      color: Colors.indigo,
      icon: Icons.settings_input_component_outlined,
      onEdit: () => _showEditTechnologyCardDialog(draft, item),
      onDelete: () {
        _refreshPlanningUi(() {
          _technologyCostItemOverrides[draft.id] = [
            for (final current in _technologyCostItemsForDraft(draft))
              if (current.id != item.id) current,
          ];
        });
        _savePlanningSandboxState();
      },
    );
  }

  List<_PlanningLocationArea> _locationAreasForName(String locationName) {
    if (locationName != 'Metropol') {
      return const [];
    }

    return const [
      _PlanningLocationArea(name: 'Saal', squareMeters: 320),
      _PlanningLocationArea(name: 'Außenbereich', squareMeters: 375),
    ];
  }

  Widget _programPlanningBoxRow(
    BuildContext context,
    PlanningDraft draft,
    PlanningArtistCostItem item,
  ) {
    return _detailPlanningBoxRow(
      context,
      label: item.label.isEmpty ? item.type.label : item.label,
      amountEur: item.grossAmountEur,
      color: Colors.deepPurple,
      icon: Icons.local_activity_outlined,
      onEdit: () => _showEditProgramCardDialog(draft, item),
      onDelete: () {
        _refreshPlanningUi(() {
          _artistCostItemOverrides[draft.id] = [
            for (final current in _artistCostItemsForDraft(draft))
              if (current.id != item.id) current,
          ];
        });
        _savePlanningSandboxState();
      },
    );
  }

  Widget _detailPlanningBoxRow(
    BuildContext context, {
    required String label,
    required double amountEur,
    required Color color,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onEdit,
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
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatEuro(amountEur),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Karte bearbeiten',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Karte entfernen',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCostPositionEditDialog(
    BuildContext context,
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) async {
    final labelController = TextEditingController(
      text: _costPositionDisplayLabel(draft, item),
    );
    final amountController = TextEditingController(
      text: _editableMoneyValue(item.amountEur),
    );
    final currentLocationName = _planningLocationName(
      draft,
      _selectedScenario(draft),
    );
    final locationAreas = item.label == 'Location / Halle'
        ? _locationAreasForName(currentLocationName)
        : const <_PlanningLocationArea>[];
    final storedAreaNames = _locationAreaSelectionOverrides[draft.id];
    final selectedAreaNames = {
      ...(storedAreaNames == null || storedAreaNames.isEmpty
          ? locationAreas.map((area) => area.name)
          : storedAreaNames),
    };

    final result = await showDialog<_CostPositionEditResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${item.label} bearbeiten'),
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
                              });
                            },
                      title: Text(
                        '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m²',
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
    return _costPositionLabelOverrides[
          _costPositionOverrideKey(draft, item.label)
        ] ??
        item.label;
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
      _costPositionAmountOverrides.remove(
        _costPositionOverrideKey(draft, 'Location / Halle'),
      );
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

  Future<void> _showCreateTechnologyCardDialog(PlanningDraft draft) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Freie Technik',
      initialLabel: 'Seifenblasenmaschine',
      initialAmountEur: 0,
    );

    if (result == null) {
      return;
    }

    _addTechnologyCatalogItem(
      draft,
      label: result.label.isEmpty ? 'Freie Technik' : result.label,
      type: PlanningTechnologyCostType.other,
      amountEur: result.amountEur,
    );
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
        for (final current in _technologyCostItemsForDraft(draft))
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

  Future<void> _showCreateProgramCardDialog(PlanningDraft draft) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Freies Programm',
      initialLabel: 'Programmpunkt',
      initialAmountEur: 0,
    );

    if (result == null) {
      return;
    }

    _addProgramCatalogItem(
      draft,
      label: result.label.isEmpty ? 'Freies Programm' : result.label,
      type: PlanningArtistCostType.other,
      amountEur: result.amountEur,
    );
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
        for (final current in _artistCostItemsForDraft(draft))
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
  }) {
    final currentItems = [..._technologyCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningTechnologyCostItem(
          id: 'technology-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          quantity: 1,
          grossUnitAmountEur: amountEur,
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
  }) {
    final currentItems = [..._artistCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningArtistCostItem(
          id: 'program-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          grossAmountEur: amountEur,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  bool _canRemoveCostPosition(String label) {
    return label == 'Technik' ||
        label == 'Künstler / Programm' ||
        label == 'Film / Lizenz' ||
        label == 'Security' ||
        label == 'Sanitäter' ||
        label == 'Toiletten' ||
        label == 'Absperrgitter';
  }

  void _removeCostPosition(
    PlanningDraft draft,
    String label,
  ) {
    _refreshPlanningUi(() {
      if (label == 'Technik') {
        _technologyCostItemOverrides[draft.id] = [];
      } else if (label == 'Künstler / Programm' ||
          label == 'Film / Lizenz') {
        _artistCostItemOverrides[draft.id] = [];
      } else if (label == 'Security') {
        _setOptionEnabled(draft, PlanningScenarioOption.security, false);
      } else if (label == 'Sanitäter') {
        _setOptionEnabled(draft, PlanningScenarioOption.medical, false);
      } else if (label == 'Toiletten') {
        _setOptionEnabled(draft, PlanningScenarioOption.toilets, false);
      } else if (label == 'Absperrgitter') {
        _setOptionEnabled(draft, PlanningScenarioOption.barriers, false);
      }
    });
    _savePlanningSandboxState();
  }

  String _costPositionGroup(String label) {
    if (label == 'Location / Halle') {
      return 'Location';
    }
    if (label == 'Technik') {
      return 'Technik';
    }
    if (label == 'Künstler / Programm' || label == 'Film / Lizenz') {
      return 'Programm';
    }
    if (label == 'Security' || label == 'Sanitäter' || label == 'Personal') {
      return 'Personal';
    }
    return 'Kosten';
  }

  Color _costPositionColor(String label) {
    return _costGroupColor(_costPositionGroup(label));
  }

  Color _costGroupColor(String group) {
    switch (group) {
      case 'Location':
        return Colors.blueGrey;
      case 'Technik':
        return Colors.indigo;
      case 'Programm':
        return Colors.deepPurple;
      case 'Personal':
        return Colors.deepOrange;
      default:
        return Colors.green;
    }
  }

  IconData _costPositionIcon(String label) {
    return _costGroupIcon(_costPositionGroup(label));
  }

  IconData _costGroupIcon(String group) {
    switch (group) {
      case 'Location':
        return Icons.location_on_outlined;
      case 'Technik':
        return Icons.settings_input_component_outlined;
      case 'Programm':
        return Icons.local_activity_outlined;
      case 'Personal':
        return Icons.groups_outlined;
      default:
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
