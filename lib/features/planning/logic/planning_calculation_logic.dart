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

  void _setStaffingItemEnabled(PlanningStaffingItem item, bool value) {
    _staffingItemOverrides[item.id] = value;
    _savePlanningSandboxState();
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

  double _visibleStaffingCostTotal(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _visibleStaffingItems(draft, scenario).fold<double>(
      0,
      (sum, item) => sum + _staffingItemTotal(item),
    );
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

  void _updateStaffingPeople(PlanningStaffingItem item, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingPeopleOverrides[item.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateStaffingHours(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingHoursOverrides[item.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateStaffingRate(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingRateOverrides[item.id] = parsed;
    _savePlanningSandboxState();
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
    final plannedArtistCosts = _artistCostTotalEurForDraft(draft);
    if (plannedArtistCosts <= 0) {
      return scenario.artistCostEur;
    }
    return plannedArtistCosts;
  }

  List<PlanningCostOverviewItem> _costOverviewItemsForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final items = <PlanningCostOverviewItem>[
      PlanningCostOverviewItem(
        label: 'Location / Halle',
        amountEur: scenario.baseRentEur,
        source: scenario.locationName,
      ),
      PlanningCostOverviewItem(
        label: 'Kuenstler',
        amountEur: _artistCostForScenario(draft, scenario),
        source: _artistCostItemsForDraft(draft).isEmpty
            ? 'Szenario-Platzhalter'
            : 'Kuenstler-Tab',
      ),
      PlanningCostOverviewItem(
        label: 'Technik',
        amountEur: scenario.technologyCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Security',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.security,
        ),
        source: 'aktive Security-Bloecke',
      ),
      PlanningCostOverviewItem(
        label: 'Personal',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.staff,
        ),
        source: 'aktive Personal-Bloecke',
      ),
      PlanningCostOverviewItem(
        label: 'Sanitaeter',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.medical,
        ),
        source: 'aktive Sanitaeter-Bloecke',
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
          source: 'aktiver Chip',
        ),
      );
    }

    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      items.add(
        PlanningCostOverviewItem(
          label: 'Absperrgitter',
          amountEur: scenario.barriersCostEur,
          source: 'aktiver Chip',
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

    return items.where((item) => item.amountEur > 0).toList();
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
    var total = scenario.baseRentEur +
        _artistCostForScenario(draft, scenario) +
        scenario.technologyCostEur +
        scenario.gemaCostEur +
        scenario.insuranceCostEur +
        scenario.marketingCostEur +
        scenario.organizerWorkEur;

    if (_isOptionEnabled(draft, PlanningScenarioOption.security)) {
      total += scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.security)
          : scenario.securityCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.medical)) {
      total += scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.medical)
          : scenario.medicalCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.toilets)) {
      total += scenario.toiletCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      total += scenario.barriersCostEur;
    }

    if (scenario.staffingItems.isNotEmpty) {
      total += _staffingCostForCategory(scenario, PlanningStaffingCategory.staff);
    }

    return total;
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
}
