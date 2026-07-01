part of '../planning_screen.dart';

extension on _PlanningScreenState {
  bool _isOptionEnabled(PlanningDraft draft, PlanningScenarioOption option) {
    return _draftOptionOverrides[draft.id]?[option] ?? _defaultOptionEnabled(draft, option);
  }

  bool _defaultOptionEnabled(PlanningDraft draft, PlanningScenarioOption option) {
    switch (option) {
      case PlanningScenarioOption.stage:
        return draft.requiresStage;
      case PlanningScenarioOption.sound:
        return draft.requiresSound;
      case PlanningScenarioOption.light:
        return draft.requiresLight;
      case PlanningScenarioOption.backstage:
        return draft.requiresBackstage;
      case PlanningScenarioOption.medical:
        return draft.checkMedical;
      case PlanningScenarioOption.security:
        return draft.checkSecurity;
      case PlanningScenarioOption.toilets:
        return draft.checkToilets;
      case PlanningScenarioOption.barriers:
        return draft.checkBarriers;
    }
  }

  bool _isStaffingItemEnabled(PlanningStaffingItem item) {
    return _staffingItemOverrides[item.id] ?? item.enabledByDefault;
  }

  List<PlanningStaffingItem> _visibleStaffingItems(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return scenario.staffingItems.where((item) {
      if (!_isStaffingCategoryActive(draft, item.category)) {
        return false;
      }
      if (item.isOptional && !_isStaffingItemEnabled(item)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _isStaffingCategoryActive(
    PlanningDraft draft,
    PlanningStaffingCategory category,
  ) {
    switch (category) {
      case PlanningStaffingCategory.security:
        return _isOptionEnabled(draft, PlanningScenarioOption.security);
      case PlanningStaffingCategory.medical:
        return _isOptionEnabled(draft, PlanningScenarioOption.medical);
      case PlanningStaffingCategory.staff:
        return true;
    }
  }

  int _staffingPeopleCount(PlanningStaffingItem item) {
    return _staffingPeopleOverrides[item.id] ?? item.peopleCount;
  }

  double _staffingHours(PlanningStaffingItem item) {
    return _staffingHoursOverrides[item.id] ?? item.hours;
  }

  double _staffingHourlyRate(PlanningStaffingItem item) {
    return _staffingRateOverrides[item.id] ?? item.hourlyRateEur;
  }

  double _staffingItemTotal(PlanningStaffingItem item) {
    return _staffingPeopleCount(item) *
        _staffingHours(item) *
        _staffingHourlyRate(item);
  }

  double _visibleStaffingCostByCategory(
    PlanningDraft draft,
    PlanningScenario scenario,
    PlanningStaffingCategory category,
  ) {
    return _visibleStaffingItems(draft, scenario)
        .where((item) => item.category == category)
        .fold<double>(0, (sum, item) => sum + _staffingItemTotal(item));
  }

  void _updateScenarioVariableCostPerAttendee(
    PlanningScenario scenario,
    String value,
  ) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _scenarioVariableCostOverrides[scenario.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateScenarioVariableCostThreshold(
    PlanningScenario scenario,
    String value,
  ) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return;
    }
    _scenarioVariableCostThresholdOverrides[scenario.id] = parsed;
    _savePlanningSandboxState();
  }

  double? _parsePlanningNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains(',') && trimmed.contains('.')) {
      return double.tryParse(
        trimmed.replaceAll('.', '').replaceAll(',', '.'),
      );
    }
    if (trimmed.contains(',')) {
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return double.tryParse(trimmed);
  }

  String _editableMoneyValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _scenarioOccupancy(PlanningScenario scenario) {
    return _scenarioOccupancyOverrides[scenario.id] ?? scenario.targetOccupancyPercent;
  }

  int _scenarioTargetAttendees(PlanningScenario scenario) {
    return max(1, (scenario.capacity * _scenarioOccupancy(scenario)).round());
  }

  List<PlanningArtistCostItem> _artistCostItemsForDraft(PlanningDraft draft) {
    return _artistCostItemOverrides[draft.id] ?? draft.artistCostItems;
  }

  List<PlanningArtistCostItem> _plannedArtistCostItemsForDraft(
    PlanningDraft draft,
  ) {
    return [
      for (final item in _artistCostItemOverrides[draft.id] ??
          const <PlanningArtistCostItem>[])
        if (item.id.startsWith('program-') &&
            _isProgramItemBackedByBuildingBlock(item))
          item,
    ];
  }

  List<PlanningTechnologyCostItem> _technologyCostItemsForDraft(
    PlanningDraft draft,
  ) {
    return _technologyCostItemOverrides[draft.id] ?? draft.technologyCostItems;
  }

  List<PlanningTechnologyCostItem> _plannedTechnologyCostItemsForDraft(
    PlanningDraft draft,
  ) {
    return [
      for (final item in _technologyCostItemOverrides[draft.id] ??
          const <PlanningTechnologyCostItem>[])
        if (item.id.startsWith('technology-') &&
            _isTechnologyItemBackedByBuildingBlock(item))
          item,
    ];
  }

  bool _isProgramItemBackedByBuildingBlock(PlanningArtistCostItem item) {
    return buildingBlockCatalogStore.value.any(
      (block) =>
          block.category == BuildingBlockCategory.program &&
          (block.name == item.label || block.name == item.note),
    );
  }

  bool _isTechnologyItemBackedByBuildingBlock(
    PlanningTechnologyCostItem item,
  ) {
    return buildingBlockCatalogStore.value.any(
      (block) =>
          block.category == BuildingBlockCategory.technology &&
          (block.name == item.label || block.name == item.note),
    );
  }

  List<PlanningBoxItem> _planningBoxItemsForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final programCostKey = _isCinemaPlanning(draft)
        ? 'Film / Lizenz'
        : 'Künstler / Programm';
    final technologyItems = _plannedTechnologyCostItemsForDraft(draft);
    final programItems = _plannedArtistCostItemsForDraft(draft);
    final items = <PlanningBoxItem>[
      _costPlanningBoxItem(
        draft,
        scenario,
        costKey: 'Location / Halle',
        amountEur: _locationCostForScenario(draft, scenario),
        source: _planningLocationName(draft, scenario),
      ),
      for (final programItem in programItems)
        PlanningBoxItem(
          id: 'program-${programItem.id}',
          category: PlanningBoxItemCategory.program,
          kind: PlanningBoxItemKind.programDetail,
          label: programItem.label.isEmpty
              ? programItem.type.label
              : programItem.label,
          amountEur: programItem.grossAmountEur,
          source:
              programItem.note.isEmpty ? programItem.type.label : programItem.note,
          costKey: programCostKey,
          detailItemId: programItem.id,
          canRemove: true,
        ),
      for (final technologyItem in technologyItems)
        PlanningBoxItem(
          id: 'technology-${technologyItem.id}',
          category: PlanningBoxItemCategory.technology,
          kind: PlanningBoxItemKind.technologyDetail,
          label: technologyItem.label.isEmpty
              ? technologyItem.type.label
              : technologyItem.label,
          amountEur: technologyItem.grossTotalEur,
          source: technologyItem.note.isEmpty
              ? technologyItem.type.label
              : technologyItem.note,
          costKey: 'Technik',
          detailItemId: technologyItem.id,
          canRemove: true,
        ),
      ..._staffBuildingBlockPlanningItems(draft, scenario),
      ..._costBuildingBlockPlanningItems(draft, scenario),
    ];

    return items
        .where(
          (item) => _isVisiblePlanningBoxItem(draft, item),
        )
        .toList();
  }

  bool _isVisiblePlanningBoxItem(PlanningDraft draft, PlanningBoxItem item) {
    if (item.category == PlanningBoxItemCategory.location) {
      return true;
    }
    if (item.kind == PlanningBoxItemKind.technologyDetail ||
        item.kind == PlanningBoxItemKind.programDetail) {
      return true;
    }
    if (item.kind == PlanningBoxItemKind.costPosition &&
        item.canRemove &&
        _isPlannedCostPosition(draft, item.costKey)) {
      return true;
    }
    return false;
  }

  List<PlanningBoxItem> _costBuildingBlockPlanningItems(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return [
      for (final block in buildingBlockCatalogStore.value)
        if (block.category == BuildingBlockCategory.cost)
          if (_isCostBuildingBlockPlanned(draft, block))
            _costPlanningBoxItem(
              draft,
              scenario,
              costKey: _costKeyForBuildingBlock(block),
              amountEur: block.defaultAmountEur,
              source: _costBuildingBlockSourceLabel(block),
              canRemove: true,
            ),
    ];
  }

  List<PlanningBoxItem> _staffBuildingBlockPlanningItems(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return [
      for (final block in buildingBlockCatalogStore.value)
        if (block.category == BuildingBlockCategory.staff)
          if (_isStaffBuildingBlockPlanned(draft, block))
            _costPlanningBoxItem(
              draft,
              scenario,
              costKey: _staffCostKeyForBuildingBlock(block),
              amountEur: block.defaultAmountEur,
              source: block.note.isEmpty ? 'Baustein' : block.note,
              canRemove: true,
            ),
    ];
  }

  bool _isCostBuildingBlockPlanned(PlanningDraft draft, BuildingBlock block) {
    return _isPlannedCostPosition(draft, _costKeyForBuildingBlock(block));
  }

  bool _isStaffBuildingBlockPlanned(PlanningDraft draft, BuildingBlock block) {
    return _isPlannedCostPosition(draft, _staffCostKeyForBuildingBlock(block));
  }

  bool _isPlannedCostPosition(PlanningDraft draft, String costKey) {
    final overrideKey = _costPositionOverrideKey(draft, costKey);
    return _costPositionLabelOverrides.containsKey(overrideKey) ||
        _costPositionAmountOverrides.containsKey(overrideKey);
  }

  String _costBuildingBlockSourceLabel(BuildingBlock block) {
    if (block.costProfile == BuildingBlockCostProfile.gema ||
        block.name.toLowerCase() == 'gema') {
      return _gemaSourceLabel();
    }
    return block.note.isEmpty ? 'Baustein' : block.note;
  }

  List<PlanningCostOverviewItem> _costOverviewItemsForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _planningBoxItemsForScenario(draft, scenario)
        .map(_costOverviewItemFromPlanningBoxItem)
        .toList();
  }

  PlanningCostOverviewItem _costOverviewItemFromPlanningBoxItem(
    PlanningBoxItem item,
  ) {
    return PlanningCostOverviewItem(
      label: item.label,
      amountEur: item.amountEur,
      source: item.source,
      isVariable: item.isVariable,
    );
  }

  PlanningBoxItem _costPlanningBoxItem(
    PlanningDraft draft,
    PlanningScenario scenario, {
    required String costKey,
    required double amountEur,
    required String source,
    bool isVariable = false,
    bool? canRemove,
  }) {
    final overrideAmount =
        _costPositionAmountOverrides[_costPositionOverrideKey(draft, costKey)];

    return PlanningBoxItem(
      id: 'cost-${draft.id}-$costKey',
      category: _planningBoxCategoryForCostKey(costKey),
      kind: PlanningBoxItemKind.costPosition,
      label: _planningBoxLabelForCostKey(draft, scenario, costKey),
      amountEur: overrideAmount ?? amountEur,
      source: source,
      costKey: costKey,
      isVariable: isVariable,
      canRemove: canRemove ?? false,
    );
  }

  String _planningBoxLabelForCostKey(
    PlanningDraft draft,
    PlanningScenario scenario,
    String key,
  ) {
    if (key == 'Location / Halle') {
      return _planningLocationName(draft, scenario);
    }
    final overrideLabel = _costPositionLabelOverrides[
      _costPositionOverrideKey(draft, key)
    ];
    if (overrideLabel != null) {
      return overrideLabel;
    }
    if (key.startsWith(_staffCostKeyPrefix)) {
      final blockId = key.substring(_staffCostKeyPrefix.length);
      for (final block in buildingBlockCatalogStore.value) {
        if (block.id == blockId) {
          return block.name;
        }
      }
      return 'Personal';
    }
    return key;
  }

  PlanningBoxItemCategory _planningBoxCategoryForCostKey(String key) {
    if (key == 'Location / Halle') {
      return PlanningBoxItemCategory.location;
    }
    if (key.startsWith(_staffCostKeyPrefix)) {
      return PlanningBoxItemCategory.staff;
    }
    return PlanningBoxItemCategory.cost;
  }

  double _locationCostForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final locationName = _planningLocationName(draft, scenario);
    BuildingBlock? locationBlock;
    for (final block in buildingBlockCatalogStore.value) {
      if (block.category == BuildingBlockCategory.location &&
          block.name == locationName) {
        locationBlock = block;
        break;
      }
    }

    if (locationBlock == null || locationBlock.areas.isEmpty) {
      return scenario.baseRentEur;
    }

    final selectedAreaNames = _locationAreaSelectionOverrides[draft.id] ??
        (locationBlock.selectedAreaNames.isNotEmpty
            ? locationBlock.selectedAreaNames
            : {locationBlock.areas.first.name});

    final selectedAreas = locationBlock.areas
        .where((area) => selectedAreaNames.contains(area.name))
        .toList();
    if (selectedAreas.isEmpty) {
      return locationBlock.areas.first.amountEur;
    }

    return selectedAreas.fold<double>(
      0,
      (total, area) => total + area.amountEur,
    );
  }

  String _gemaSourceLabel() {
    for (final block in buildingBlockCatalogStore.value) {
      if (block.costProfile == BuildingBlockCostProfile.gema ||
          block.name.toLowerCase() == 'gema') {
        final config = block.gemaConfig;
        if (config == null) {
          return 'GEMA-Baustein';
        }
        return 'GEMA-Baustein · ${config.musicType.label} · ${config.audienceType.label}';
      }
    }
    return 'GEMA-Baustein / Planung';
  }

  String _costPositionOverrideKey(PlanningDraft draft, String label) {
    return '${draft.id}::$label';
  }

  double _scenarioBaseCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    return _planningBoxItemsForScenario(draft, scenario)
        .where((item) => !item.isVariable)
        .fold<double>(0, (sum, item) => sum + item.amountEur);
  }

  double _scenarioVariableCostsEur(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final costPerAttendee = _scenarioVariableCostPerAttendee(scenario);
    if (costPerAttendee <= 0) {
      return 0;
    }

    final threshold = _scenarioVariableCostThreshold(scenario);
    final variableAttendees = _scenarioTargetAttendees(scenario) - threshold;

    if (variableAttendees <= 0) {
      return 0;
    }

    return variableAttendees * costPerAttendee;
  }

  double _scenarioVariableCostPerAttendee(PlanningScenario scenario) {
    return _scenarioVariableCostOverrides[scenario.id] ??
        scenario.variableCostPerAttendeeEur;
  }

  int _scenarioVariableCostThreshold(PlanningScenario scenario) {
    return _scenarioVariableCostThresholdOverrides[scenario.id] ??
        (scenario.variableCostThresholdAttendees > 0
            ? scenario.variableCostThresholdAttendees
            : (scenario.capacity * 0.5).round());
  }

  double _scenarioEventCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    return _planningBoxItemsForScenario(draft, scenario)
        .fold<double>(0, (sum, item) => sum + item.amountEur);
  }

  double _totalPlannedCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    return _requiredGrossRevenueBeforeEvent(draft, scenario);
  }

  double _amountToCoverAfterSupportEur(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final result =
        _requiredGrossRevenueBeforeEvent(draft, scenario) - draft.totalSupportEur;
    return result < 0 ? 0 : result;
  }

  double _requiredTicketPriceAtTargetOccupancy(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _amountToCoverAfterSupportEur(draft, scenario) /
        _scenarioTargetAttendees(scenario);
  }

  double _requiredEarlyBirdPriceAtTargetOccupancy(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _requiredTicketPriceAtTargetOccupancy(draft, scenario);
  }

  double _normalPriceMarkupPercent(PlanningDraft draft) {
    return _normalPriceMarkupOverrides[draft.id] ?? 0.5;
  }

  double _leakagePercent(PlanningDraft draft) {
    return _leakagePercentOverrides[draft.id] ?? draft.leakagePercent;
  }

  double _reservePercent(PlanningDraft draft) {
    return _reservePercentOverrides[draft.id] ?? draft.reservePercent;
  }

  double _organizerSharePercent(PlanningDraft draft) {
    return _organizerSharePercentOverrides[draft.id] ??
        draft.organizerMarginPercent;
  }

  double _partnerSharePercent(PlanningDraft draft) {
    return _partnerSharePercentOverrides[draft.id] ?? 0.03;
  }

  double _preEventSharePercent(PlanningDraft draft) {
    return _organizerSharePercent(draft) + _partnerSharePercent(draft);
  }

  double _requiredGrossRevenueBeforeEvent(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final eventCosts = _scenarioEventCostsEur(draft, scenario);
    final deductionFactor =
        1 -
        _preEventSharePercent(draft) -
        _leakagePercent(draft) -
        _reservePercent(draft);

    if (deductionFactor <= 0) {
      return eventCosts;
    }

    return eventCosts / deductionFactor;
  }

  void _updateNormalPriceMarkup(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _normalPriceMarkupOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateLeakagePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _leakagePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateReservePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _reservePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateOrganizerSharePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _organizerSharePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updatePartnerSharePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _partnerSharePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  double _roundUpToFullEuro(double value) {
    return value.ceilToDouble();
  }

  double _normalPriceEurForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final earlyBird = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    return _roundUpToFullEuro(
      earlyBird * (1 + _normalPriceMarkupPercent(draft)),
    );
  }

  int _breakEvenEarlyBirdTickets(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final earlyBirdPrice =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);

    if (earlyBirdPrice <= 0) {
      return 0;
    }

    return (_amountToCoverAfterSupportEur(draft, scenario) / earlyBirdPrice)
        .ceil();
  }

  int _normalTicketsAfterBreakEvenAtTarget(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final remainder =
        _scenarioTargetAttendees(scenario) - _breakEvenEarlyBirdTickets(draft, scenario);
    return remainder < 0 ? 0 : remainder;
  }

  double _normalPriceSurplusPerTicketAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalPriceEurForScenario(draft, scenario);
  }

  double _organizerMarginPerNormalTicketAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalPriceEurForScenario(draft, scenario) *
        draft.postBreakEvenMarginPercent;
  }

  double _normalPhaseGrossSurplusAtTarget(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
        _normalPriceSurplusPerTicketAfterBreakEven(draft, scenario);
  }

  double _featureBudgetAtTargetAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final gross = _normalPhaseGrossSurplusAtTarget(draft, scenario);
    final organizerPart =
        _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
            _organizerMarginPerNormalTicketAfterBreakEven(draft, scenario);
    final result = gross - organizerPart;
    return result < 0 ? 0 : result;
  }

  String _scenarioPriceLabel(PlanningDraft draft, PlanningScenario scenario) {
    final required = _requiredTicketPriceAtTargetOccupancy(draft, scenario);
    if (required <= 50) {
      return 'Preis niedrig';
    }
    if (required <= 75) {
      return 'Preis pruefen';
    }
    return 'Preis hoch';
  }

  String _riskStatusLabel(PlanningDraft draft, PlanningScenario scenario) {
    return _scenarioPriceLabel(draft, scenario);
  }

  PlanningScenario _selectedScenario(PlanningDraft draft) {
    final selectedId = _selectedScenarioOverrides[draft.id];
    if (selectedId == null) {
      return _recommendedScenario(draft);
    }

    return draft.scenarios.firstWhere(
      (scenario) => scenario.id == selectedId,
      orElse: () => _recommendedScenario(draft),
    );
  }

  PlanningScenario _recommendedScenario(PlanningDraft draft) {
    final ranked = [...draft.scenarios]
      ..sort(
        (a, b) => _requiredTicketPriceAtTargetOccupancy(draft, a)
            .compareTo(_requiredTicketPriceAtTargetOccupancy(draft, b)),
      );
    return ranked.first;
  }

  String _mainDecisionStatus(PlanningDraft draft) {
    return _riskStatusLabel(draft, _selectedScenario(draft));
  }

  String _mainDecisionSummary(PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final required =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);
    return 'Das ausgewaehlte Szenario braucht bei ${_scenarioTargetAttendees(scenario)} zahlenden Early Birds ${formatEuro(required)} bis Break-even. Danach liegt der Normalpreis bei ${formatEuro(normalPrice)}.';
  }

  bool _isCinemaPlanning(PlanningDraft draft) {
    final text = '${draft.title} ${draft.format}'.toLowerCase();
    return _planningCategory(draft) == EventCategory.movie ||
        text.contains('kino') ||
        text.contains('film');
  }
}
