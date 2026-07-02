part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildScenarioComparison(BuildContext context, PlanningDraft draft) {
    final selectedScenario = _selectedScenario(draft);

    return _scenarioComparisonContent(context, draft, selectedScenario);
  }

  Widget _scenarioComparisonContent(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario selectedScenario,
  ) {
    final headerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Szenario', style: headerStyle)),
              Expanded(child: Text('Kapazitaet', style: headerStyle)),
              Expanded(child: Text('Auslastung', style: headerStyle)),
              Expanded(child: Text('Besucher', style: headerStyle)),
              Expanded(child: Text('Early-Bird', style: headerStyle)),
              Expanded(child: Text('Normalpreis', style: headerStyle)),
              Expanded(child: Text('Var. Kosten', style: headerStyle)),
              Expanded(child: Text('Status', style: headerStyle)),
              const SizedBox(width: 112),
            ],
          ),
        ),
        ...draft.scenarios.map((scenario) {
          final isSelected = scenario.id == selectedScenario.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _refreshPlanningUi(() {
                  _selectedScenarioOverrides[draft.id] = scenario.id;
                });
                _savePlanningSandboxState();
              },
              child: Container(
                padding: const EdgeInsets.all(10),            decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? _planningCategory(draft).color.withValues(alpha: 0.08)
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? _planningCategory(draft).color
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        scenario.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text('${scenario.capacity}')),
                    Expanded(
                      child: Text(
                        '${(_scenarioOccupancy(scenario) * 100).round()} %',
                      ),
                    ),
                    Expanded(
                      child: Text('${_scenarioTargetAttendees(scenario)}'),
                    ),
                    Expanded(
                      child: Text(
                        formatEuro(
                          _requiredEarlyBirdPriceAtTargetOccupancy(
                            draft,
                            scenario,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatEuro(_normalPriceEurForScenario(draft, scenario)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatEuro(_scenarioVariableCostsEur(draft, scenario)),
                      ),
                    ),
                    Expanded(child: Text(_scenarioPriceLabel(draft, scenario))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 104,
                      child: OutlinedButton(
                        onPressed: isSelected
                            ? null
                            : () {
                                _refreshPlanningUi(() {
                                  _selectedScenarioOverrides[draft.id] =
                                      scenario.id;
                                });
                                _savePlanningSandboxState();
                              },
                        child: Text(isSelected ? 'Aktiv' : 'Waehlen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalculationMainOverview(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario scenario, {
    required double earlyBirdPrice,
    required double normalPrice,
  }) {
    final attendees = _scenarioTargetAttendees(scenario);
    final fixedEventCosts = _scenarioBaseCostsEur(draft, scenario);
    final variableEventCosts = _scenarioVariableCostsEur(draft, scenario);
    final totalEventCosts = _scenarioEventCostsEur(draft, scenario);
    final grossTicketsBeforeEvent = attendees * earlyBirdPrice;
    final totalIncomeBeforeEvent =
        grossTicketsBeforeEvent + _totalSupportEur(draft);
    final organizerSharePercent = _organizerSharePercent(draft);
    final partnerSharePercent = _partnerSharePercent(draft);
    final totalSharePercent = organizerSharePercent + partnerSharePercent;
    final organizerShareAmount = totalIncomeBeforeEvent * organizerSharePercent;
    final partnerShareAmount = totalIncomeBeforeEvent * partnerSharePercent;
    final totalShareAmount = organizerShareAmount + partnerShareAmount;
    final leakagePercent = _leakagePercent(draft);
    final reservePercent = _reservePercent(draft);
    final leakageAmount = totalIncomeBeforeEvent * leakagePercent;
    final reserveAmount = totalIncomeBeforeEvent * reservePercent;
    final totalDeductions =
        totalShareAmount + leakageAmount + reserveAmount;
    final availableEventBudget =
        totalIncomeBeforeEvent - totalDeductions;
    final preEventBalance = availableEventBudget - totalEventCosts;
    final normalPhaseGross = _normalPhaseGrossSurplusAtTarget(draft, scenario);
    final organizerAfterBreakEven =
        _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
            _organizerMarginPerNormalTicketAfterBreakEven(draft, scenario);
    final featureBudget = _featureBudgetAtTargetAfterBreakEven(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _breakEvenWideBlock(
          context,
          title: 'Szenariovergleich',
          child: _scenarioComparisonContent(context, draft, scenario),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _breakEvenOverviewBlock(
              context,
              title: 'Projekt / Main',
              rows: [
                ('Projekt', _draftTitle(draft)),
                ('Szenario', scenario.name),
                ('Kapazitaet', '${scenario.capacity}'),
                (
                  'Auslastung',
                  '${(_scenarioOccupancy(scenario) * 100).round()} %',
                ),
                ('Besucher', '$attendees'),
                (
                  'Early-Bird',
                  '${earlyBirdPrice.round()} EVC / ${formatEuro(earlyBirdPrice)}',
                ),
                (
                  'Normalpreis',
                  '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
                ),
              ],
              footer: _compactOccupancySlider(draft, scenario),
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Einnahmen vor Veranstaltung',
              rows: [
                ('Tickets', formatEuro(grossTicketsBeforeEvent)),
                ..._fundingDisplayRows(draft),
                ('Summe Einnahmen', formatEuro(totalIncomeBeforeEvent)),
              ],
              emphasizeLast: true,
            ),
            _editablePercentageBlock(
              context,
              title: 'Abzuege vor Eventfinanzierung',
              rows: [
                (
                  'Veranstaltergewinn',
                  _percentField(
                    initialValue: _editablePercentValue(organizerSharePercent),
                    onChangedValue: (value) => _updateOrganizerSharePercent(draft, value),
                  ),
                  formatEuro(organizerShareAmount),
                ),
                (
                  'Partner',
                  _percentField(
                    initialValue: _editablePercentValue(partnerSharePercent),
                    onChangedValue: (value) => _updatePartnerSharePercent(draft, value),
                  ),
                  formatEuro(partnerShareAmount),
                ),
                (
                  'Risiko / Leckage',
                  _percentField(
                    initialValue: _editablePercentValue(leakagePercent),
                    onChangedValue: (value) => _updateLeakagePercent(draft, value),
                  ),
                  formatEuro(leakageAmount),
                ),
                (
                  'Reserve',
                  _percentField(
                    initialValue: _editablePercentValue(reservePercent),
                    onChangedValue: (value) => _updateReservePercent(draft, value),
                  ),
                  formatEuro(reserveAmount),
                ),
                (
                  'Summe Abzuege',
                  Text('${((totalSharePercent + leakagePercent + reservePercent) * 100).toStringAsFixed(1)} %'),
                  formatEuro(totalDeductions),
                ),
              ],
              emphasizeLast: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _breakEvenOverviewBlock(
              context,
              title: 'Verfuegbar fuer Eventfinanzierung',
              rows: [
                ('Einnahmen gesamt', formatEuro(totalIncomeBeforeEvent)),
                ('abzgl. Abzuege', formatEuro(totalDeductions)),
                ('Budget fuer Eventkosten', formatEuro(availableEventBudget)),
              ],
              emphasizeLast: true,
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Kostenstruktur',
              rows: [
                ('Fixe Grundkosten', formatEuro(fixedEventCosts)),
                ('Variable Wachstumskosten', formatEuro(variableEventCosts)),
                ('Eventkosten gesamt', formatEuro(totalEventCosts)),
                (
                  preEventBalance >= 0
                      ? 'Puffer vor Veranstaltung'
                      : 'Fehlbetrag vor Veranstaltung',
                  formatEuro(preEventBalance),
                ),
              ],
              emphasizeLast: true,
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Nach Break-even',
              rows: [
                (
                  'Normalpreis-Aufschlag',
                  '${(_normalPriceMarkupPercent(draft) * 100).round()} %',
                ),
                (
                  'Normalpreis-Tickets',
                  '${_normalTicketsAfterBreakEvenAtTarget(draft, scenario)}',
                ),
                ('Ueberschuss brutto', formatEuro(normalPhaseGross)),
                (
                  'Veranstalter-Marge danach',
                  formatEuro(organizerAfterBreakEven),
                ),
                ('Feature-Budget', formatEuro(featureBudget)),
              ],
              emphasizeLast: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _breakEvenWideBlock(
          context,
          title: 'Eventkosten nach Positionen',
          child: _mainCostPositionSummary(context, draft, scenario),
        ),
      ],
    );
  }

  Widget _mainCostPositionSummary(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final items = _costOverviewItemsForScenario(draft, scenario);
    final fixedTotal = items
        .where((item) => !item.isVariable)
        .fold<double>(0, (sum, item) => sum + item.amountEur);
    final variableTotal = items
        .where((item) => item.isVariable)
        .fold<double>(0, (sum, item) => sum + item.amountEur);
    final requiredGrossRevenue =
        _totalPlannedCostsEur(draft, scenario);
    final ticketRemainder =
        _amountToCoverForTicketPriceEur(draft, scenario);
    final earlyBirdPrice =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _infoPair('Fixe Kosten', formatEuro(fixedTotal)),
            _infoPair('Variable Kosten', formatEuro(variableTotal)),
            _infoPair('Summe Eventkosten', formatEuro(fixedTotal + variableTotal)),
            _infoPair('Gegenfinanzierung', formatEuro(_totalSupportEur(draft))),
            _infoPair('Restbetrag Tickets', formatEuro(ticketRemainder)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Position',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Quelle',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  'Betrag',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          const Text('Noch keine aktiven Kostenpositionen.')
        else
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final selectionKey = '${draft.id}:${scenario.id}';
            final selectedIndex = _selectedMainCostRowIndexes[selectionKey];
            final isSelected = selectedIndex == index;
            final rowTint = _planningCategory(draft).color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    _refreshPlanningUi(() {
                      if (isSelected) {
                        _selectedMainCostRowIndexes.remove(selectionKey);
                      } else {
                        _selectedMainCostRowIndexes[selectionKey] = index;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isSelected
                          ? rowTint.withValues(alpha: 0.14)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? rowTint.withValues(alpha: 0.5)
                              : Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            [
                              item.description,
                              item.calculationHint,
                            ].where((line) => line.trim().isNotEmpty).join(' · '),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(
                            formatEuro(item.amountEur),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Text(
          'Gegenfinanzierung und Zielpreis',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        _valueRow(
          'Nötige Einnahmen vor Veranstaltung',
          formatEuro(requiredGrossRevenue),
        ),
        for (final row in _fundingDisplayRows(draft))
          _valueRow(row.$1, row.$2),
        _valueRow(
          'Gesamte Gegenfinanzierung',
          formatEuro(_totalSupportEur(draft)),
        ),
        _valueRow(
          'Restbetrag für Ticketpreis',
          formatEuro(ticketRemainder),
          valueStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        _valueRow(
          'Early-Bird bei ${_scenarioTargetAttendees(scenario)} Personen',
          formatEuro(earlyBirdPrice),
        ),
        _valueRow(
          'Normalpreis danach',
          formatEuro(normalPrice),
        ),
      ],
    );
  }

  Widget _breakEvenOverviewBlock(
    BuildContext context, {
    required String title,
    required List<(String, String)> rows,
    bool emphasizeLast = false,
    Widget? footer,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 420,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLast = index == rows.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _valueRow(
                  row.$1,
                  row.$2,
                  valueStyle: emphasizeLast && isLast
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                  ),
                );
              }),
            if (footer != null) ...[
              const SizedBox(height: 8),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  Widget _breakEvenWideBlock(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _compactOccupancySlider(PlanningDraft draft, PlanningScenario scenario) {
    final occupancy = _scenarioOccupancy(scenario);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auslastung feinjustieren: ${(occupancy * 100).round()} %',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(
          width: 260,
          child: Slider(
            value: occupancy,
            min: 0.3,
            max: 1.0,
            divisions: 14,
            label: '${(occupancy * 100).round()} %',
            onChanged: (value) {
              _refreshPlanningUi(() {
                _scenarioOccupancyOverrides[scenario.id] = value;
                _selectedScenarioOverrides[draft.id] = scenario.id;
              });
              _savePlanningSandboxState();
            },
          ),
        ),
      ],
    );
  }

  Widget _editablePercentageBlock(
    BuildContext context, {
    required String title,
    required List<(String, Widget, String)> rows,
    bool emphasizeLast = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 420,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLast = index == rows.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: row.$2,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.$3,
                        textAlign: TextAlign.right,
                        style: emphasizeLast && isLast
                            ? const TextStyle(fontWeight: FontWeight.w700)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _percentField({
    required String initialValue,
    required ValueChanged<String> onChangedValue,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          _refreshPlanningUi();
        }
      },
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          suffixText: '%',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChangedValue,
        onEditingComplete: _refreshPlanningUi,
        onFieldSubmitted: (_) => _refreshPlanningUi(),
      ),
    );
  }

  String _editablePercentValue(double value) {
    final percent = value * 100;
    if (percent == percent.roundToDouble()) {
      return percent.toStringAsFixed(0);
    }
    return percent.toStringAsFixed(1).replaceAll('.', ',');
  }
}
