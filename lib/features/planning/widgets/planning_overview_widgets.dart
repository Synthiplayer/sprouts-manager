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
                      ? draft.category.color.withValues(alpha: 0.08)
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? draft.category.color
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
        grossTicketsBeforeEvent + draft.totalSupportEur;
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
                ('Projekt', draft.title),
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
                ('Sponsoring', formatEuro(draft.fixedSponsorAmountEur)),
                ('Unterstuetzer', formatEuro(draft.supporterAmountEur)),
                ('Foerderung', formatEuro(draft.grantAmountEur)),
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
                  'Rest nach Eventkosten',
                  formatEuro(availableEventBudget - totalEventCosts),
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
