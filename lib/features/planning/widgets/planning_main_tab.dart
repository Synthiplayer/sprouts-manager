part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildMainTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final visibleStaffingItems = _visibleStaffingItems(draft, scenario);
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
                    draft.category.toChip(filled: false),
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
                    _infoPair('Location', scenario.locationName),
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
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Anforderungen und Setup',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  _infoPair('Mindestkapazitaet', '${draft.minimumCapacity}'),
                  _infoPair('Raumkonzept', draft.seatingMode),
                  _infoPair('Location', scenario.locationName),
                  _infoPair('Setup', scenario.setupName),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlanningScenarioOption.values.map((option) {
                  return FilterChip(
                    label: Text(option.label),
                    selected: _isOptionEnabled(draft, option),
                    onSelected: (value) {
                      _refreshPlanningUi(() {
                        _setOptionEnabled(draft, option, value);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Diese Chips koennen fuer die Planung an- und abgewaehlt werden. Aktive Personalbloecke erscheinen direkt darunter und koennen dort bearbeitet werden.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Security, Sanitaeter und Personal',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _valueRow('Aktuelles Szenario', '${scenario.name} - ${scenario.locationName}'),
              _valueRow('Setup', scenario.setupName),
              const SizedBox(height: 12),
              if (visibleStaffingItems.isEmpty)
                const Text(
                  'Aktuell sind keine passenden Bloecke aktiv. Security und Sanitaeter folgen den Chips, Personal wird davon getrennt als eigener Kostenposten gefuehrt.',
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: PlanningStaffingCategory.values
                      .where(
                        (category) => visibleStaffingItems.any(
                          (item) => item.category == category,
                        ),
                      )
                      .map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildStaffingCategorySection(
                            context,
                            draft,
                            scenario,
                            category,
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 6),
              _valueRow(
                'Aktive Personal- und Sicherheitsbloecke',
                formatEuro(_visibleStaffingCostTotal(draft, scenario)),
              ),
            ],
          ),
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

  Widget _buildInlineStaffingEditor(
    BuildContext context,
    PlanningStaffingItem item,
  ) {
    final isEnabled = _isStaffingItemEnabled(item);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              _pill(context, item.category.label),
              if (item.isOptional)
                FilterChip(
                  label: const Text('aktiv'),
                  selected: isEnabled,
                  onSelected: (value) {
                    _refreshPlanningUi(() {
                      _setStaffingItemEnabled(item, value);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _staffingNumberField(
                context,
                label: 'Personen',
                initialValue: '${_staffingPeopleCount(item)}',
                onChangedValue: (value) => _updateStaffingPeople(item, value),
                onApply: _refreshPlanningUi,
              ),
              _staffingNumberField(
                context,
                label: 'Stunden',
                initialValue: _staffingHours(item).toStringAsFixed(
                  _staffingHours(item) == _staffingHours(item).roundToDouble() ? 0 : 1,
                ),
                onChangedValue: (value) => _updateStaffingHours(item, value),
                onApply: _refreshPlanningUi,
              ),
              _staffingNumberField(
                context,
                label: 'Satz / Stunde brutto',
                initialValue: _editableMoneyValue(_staffingHourlyRate(item)),
                onChangedValue: (value) => _updateStaffingRate(item, value),
                onApply: _refreshPlanningUi,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _valueRow(
            'Gesamt',
            formatEuro(_staffingItemTotal(item)),
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.note,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffingCategorySection(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario scenario,
    PlanningStaffingCategory category,
  ) {
    final items = _visibleStaffingItems(
      draft,
      scenario,
    ).where((item) => item.category == category).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildInlineStaffingEditor(
              context,
              item,
            ),
          ),
        ),
        _valueRow(
          'Summe ${category.label}',
          formatEuro(
            items.fold<double>(
              0,
              (sum, item) => sum + _staffingItemTotal(item),
            ),
          ),
        ),
      ],
    );
  }

  Widget _staffingNumberField(
    BuildContext context, {
    required String label,
    required String initialValue,
    required ValueChanged<String> onChangedValue,
    required VoidCallback onApply,
  }) {
    return SizedBox(
      width: 130,
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChangedValue,
        onEditingComplete: onApply,
        onFieldSubmitted: (_) => onApply(),
      ),
    );
  }

}
