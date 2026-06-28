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

  void _setOptionEnabled(
    PlanningDraft draft,
    PlanningScenarioOption option,
    bool value,
  ) {
    final options = _draftOptionOverrides.putIfAbsent(draft.id, () => {});
    options[option] = value;
    _savePlanningSandboxState();
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

  double _artistCostTotalEurForDraft(PlanningDraft draft) {
    return _artistCostItemsForDraft(draft).fold<double>(
      0,
      (total, item) => total + item.grossAmountEur,
    );
  }

  double _artistCostForScenario(PlanningDraft draft, PlanningScenario scenario) {
    if (_artistCostItemOverrides.containsKey(draft.id)) {
      return _artistCostTotalEurForDraft(draft);
    }
    final plannedArtistCosts = _artistCostTotalEurForDraft(draft);
    if (plannedArtistCosts <= 0) {
      return scenario.artistCostEur;
    }
    return plannedArtistCosts;
  }

  List<PlanningTechnologyCostItem> _technologyCostItemsForDraft(
    PlanningDraft draft,
  ) {
    return _technologyCostItemOverrides[draft.id] ?? draft.technologyCostItems;
  }

  double _technologyCostTotalEurForDraft(PlanningDraft draft) {
    return _technologyCostItemsForDraft(draft).fold<double>(
      0,
      (total, item) => total + item.grossTotalEur,
    );
  }

  double _technologyCostForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    if (_technologyCostItemOverrides.containsKey(draft.id)) {
      return _technologyCostTotalEurForDraft(draft);
    }
    final plannedTechnologyCosts = _technologyCostTotalEurForDraft(draft);
    if (plannedTechnologyCosts <= 0) {
      return scenario.technologyCostEur;
    }
    return plannedTechnologyCosts;
  }

  List<PlanningCostOverviewItem> _costOverviewItemsForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final programCostLabel = _isCinemaPlanning(draft)
        ? 'Film / Lizenz'
        : 'Künstler / Programm';
    final items = <PlanningCostOverviewItem>[
      PlanningCostOverviewItem(
        label: 'Location / Halle',
        amountEur: _locationCostForScenario(draft, scenario),
        source: _planningLocationName(draft, scenario),
      ),
      PlanningCostOverviewItem(
        label: programCostLabel,
        amountEur: _artistCostForScenario(draft, scenario),
        source: _artistCostItemsForDraft(draft).isEmpty
            ? 'Szenario-Wert'
            : 'Programm-Tab',
      ),
      PlanningCostOverviewItem(
        label: 'Technik',
        amountEur: _technologyCostForScenario(draft, scenario),
        source: _technologyCostItemsForDraft(draft).isEmpty
            ? 'Szenario-Wert'
            : 'Technik-Tab',
      ),
      PlanningCostOverviewItem(
        label: 'Security',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.security,
        ),
        source: 'aktive Security-Blöcke',
      ),
      PlanningCostOverviewItem(
        label: 'Personal',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.staff,
        ),
        source: 'aktive Personal-Blöcke',
      ),
      PlanningCostOverviewItem(
        label: 'Sanitäter',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.medical,
        ),
        source: 'aktive Sanitäter-Blöcke',
      ),
      PlanningCostOverviewItem(
        label: 'GEMA',
        amountEur: scenario.gemaCostEur,
        source: 'Szenario / Location',
      ),
      PlanningCostOverviewItem(
        label: 'Werbung',
        amountEur: scenario.marketingCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Versicherung',
        amountEur: scenario.insuranceCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Veranstalterarbeit',
        amountEur: scenario.organizerWorkEur,
        source: 'Planung',
      ),
    ];

    if (_isOptionEnabled(draft, PlanningScenarioOption.toilets)) {
      items.add(
        PlanningCostOverviewItem(
          label: 'Toiletten',
          amountEur: scenario.toiletCostEur,
          source: 'Konfiguration',
        ),
      );
    }

    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      items.add(
        PlanningCostOverviewItem(
          label: 'Absperrgitter',
          amountEur: scenario.barriersCostEur,
          source: 'Konfiguration',
        ),
      );
    }

    items.add(
      PlanningCostOverviewItem(
        label: 'Variable Wachstumskosten',
        amountEur: _scenarioVariableCostsEur(draft, scenario),
        source: 'Auslastung / Szenario',
        isVariable: true,
      ),
    );

    return items
        .map((item) => _costItemWithAmountOverride(draft, item))
        .where((item) => item.amountEur > 0 || item.label == 'Location / Halle')
        .toList();
  }

  PlanningCostOverviewItem _costItemWithAmountOverride(
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) {
    if (item.label == 'Location / Halle' &&
        _locationHasConfiguredAreas(item.source)) {
      return item;
    }

    final overrideAmount =
        _costPositionAmountOverrides[_costPositionOverrideKey(draft, item.label)];
    if (overrideAmount == null) {
      return item;
    }

    return PlanningCostOverviewItem(
      label: item.label,
      amountEur: overrideAmount,
      source: item.source,
      isVariable: item.isVariable,
    );
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

  bool _locationHasConfiguredAreas(String locationName) {
    for (final block in buildingBlockCatalogStore.value) {
      if (block.category == BuildingBlockCategory.location &&
          block.name == locationName) {
        return block.areas.isNotEmpty;
      }
    }

    return false;
  }

  String _costPositionOverrideKey(PlanningDraft draft, String label) {
    return '${draft.id}::$label';
  }

  double _staffingCostForCategory(
    PlanningScenario scenario,
    PlanningStaffingCategory category,
  ) {
    return scenario.staffingItems
        .where((item) => item.category == category)
        .where((item) => _isStaffingItemEnabled(item))
        .fold<double>(0, (sum, item) => sum + _staffingItemTotal(item));
  }

  double _scenarioBaseCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    final programCostLabel = _isCinemaPlanning(draft)
        ? 'Film / Lizenz'
        : 'Künstler / Programm';
    var total = _locationCostForScenario(draft, scenario) +
        _costPositionAmountForCalculation(
          draft,
          programCostLabel,
          _artistCostForScenario(draft, scenario),
        ) +
        _costPositionAmountForCalculation(
          draft,
          'Technik',
          _technologyCostForScenario(draft, scenario),
        ) +
        _costPositionAmountForCalculation(draft, 'GEMA', scenario.gemaCostEur) +
        _costPositionAmountForCalculation(
          draft,
          'Versicherung',
          scenario.insuranceCostEur,
        ) +
        _costPositionAmountForCalculation(
          draft,
          'Werbung',
          scenario.marketingCostEur,
        ) +
        _costPositionAmountForCalculation(
          draft,
          'Veranstalterarbeit',
          scenario.organizerWorkEur,
        );

    if (_isOptionEnabled(draft, PlanningScenarioOption.security)) {
      final securityCost = scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.security)
          : scenario.securityCostEur;
      total += _costPositionAmountForCalculation(
        draft,
        'Security',
        securityCost,
      );
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.medical)) {
      final medicalCost = scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.medical)
          : scenario.medicalCostEur;
      total += _costPositionAmountForCalculation(
        draft,
        'Sanitäter',
        medicalCost,
      );
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.toilets)) {
      total += _costPositionAmountForCalculation(
        draft,
        'Toiletten',
        scenario.toiletCostEur,
      );
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      total += _costPositionAmountForCalculation(
        draft,
        'Absperrgitter',
        scenario.barriersCostEur,
      );
    }

    if (scenario.staffingItems.isNotEmpty) {
      total += _costPositionAmountForCalculation(
        draft,
        'Personal',
        _staffingCostForCategory(scenario, PlanningStaffingCategory.staff),
      );
    }

    return total;
  }

  double _costPositionAmountForCalculation(
    PlanningDraft draft,
    String label,
    double fallbackAmountEur,
  ) {
    return _costPositionAmountOverrides[
          _costPositionOverrideKey(draft, label)
        ] ??
        fallbackAmountEur;
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
    return _scenarioBaseCostsEur(draft, scenario) +
        _scenarioVariableCostsEur(draft, scenario);
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
