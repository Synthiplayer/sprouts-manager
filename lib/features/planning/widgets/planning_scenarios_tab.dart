part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildScenariosTab(BuildContext context, PlanningDraft draft) {
    final growthPath = [...draft.scenarios]
      ..sort((a, b) => a.capacity.compareTo(b.capacity));
    final selectedScenario = _selectedScenario(draft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Vergleichsbasis',
          child: const Text(
            'Alle Szenarien starten fuer den ersten Vergleich mit 50 % Auslastung. Danach kann jede Location per Slider feinjustiert werden. Lieber kleiner und voller als gross und leer.',
          ),
        ),
        const SizedBox(height: 12),
        _buildScenarioComparison(context, draft),
        const SizedBox(height: 12),
        ...draft.scenarios.map((scenario) {
          final isSelected = scenario.id == selectedScenario.id;
          final occupancy = _scenarioOccupancy(scenario);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _refreshPlanningUi(() {
                  _selectedScenarioOverrides[draft.id] = scenario.id;
                });
                _savePlanningSandboxState();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? _planningCategory(draft).color
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          scenario.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (isSelected) _pill(context, 'Ausgewaehlt'),
                        _pill(context, _scenarioPriceLabel(draft, scenario)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 14,
                      children: [
                        _infoPair('Location', scenario.locationName),
                        _infoPair('Setup', scenario.setupName),
                        _infoPair('Kapazitaet', '${scenario.capacity}'),
                        _infoPair(
                          'Zielauslastung',
                          '${(occupancy * 100).round()} %',
                        ),
                        _infoPair('Grundmiete', formatEuro(scenario.baseRentEur)),
                        _infoPair('Wichtige Hinweise', scenario.locationNotes),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Auslastung feinjustieren: ${(occupancy * 100).round()} %',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: occupancy,
                      min: 0.3,
                      max: 1.0,
                      divisions: 14,
                      label: '${(occupancy * 100).round()} %',
                      onChanged: (value) {
                        _refreshPlanningUi(() {
                          _scenarioOccupancyOverrides[scenario.id] = value;
                        });
                        _savePlanningSandboxState();
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            key: ValueKey('${scenario.id}-variable-threshold'),
                            initialValue:
                                '${_scenarioVariableCostThreshold(scenario)}',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Variable Kosten ab Personen',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _updateScenarioVariableCostThreshold(
                                scenario,
                                value,
                              );
                            },
                            onEditingComplete: _refreshPlanningUi,
                            onFieldSubmitted: (_) => _refreshPlanningUi(),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            key: ValueKey('${scenario.id}-variable-cost'),
                            initialValue: _editableMoneyValue(
                              _scenarioVariableCostPerAttendee(scenario),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kosten je Mehrgast',
                              suffixText: 'EUR',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) {
                              _updateScenarioVariableCostPerAttendee(
                                scenario,
                                value,
                              );
                            },
                            onEditingComplete: _refreshPlanningUi,
                            onFieldSubmitted: (_) => _refreshPlanningUi(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _valueRow(
                      'Fixe Grundkosten',
                      formatEuro(_scenarioBaseCostsEur(draft, scenario)),
                    ),
                    _valueRow(
                      'Variable Wachstumskosten',
                      formatEuro(_scenarioVariableCostsEur(draft, scenario)),
                    ),
                    if (scenario.variableCostNote.isNotEmpty)
                      _valueRow('Variable Annahme', scenario.variableCostNote),
                    _valueRow(
                      'Noetige Einnahmen vor Veranstaltung',
                      formatEuro(_totalPlannedCostsEur(draft, scenario)),
                    ),
                    for (final row in _fundingDisplayRows(draft))
                      _valueRow(row.$1, row.$2),
                    _valueRow(
                      'Gesamte Gegenfinanzierung',
                      formatEuro(_totalSupportEur(draft)),
                    ),
                    _valueRow(
                      'Restbetrag für Ticketpreis',
                      formatEuro(_amountToCoverForTicketPriceEur(draft, scenario)),
                    ),
                    _valueRow(
                      'Noetiger Early-Bird-Preis bei Zielauslastung',
                      formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario)),
                    ),
                    _valueRow(
                      'Zielteilnehmer fuer Break-even',
                      '${_scenarioTargetAttendees(scenario)}',
                    ),
                    _valueRow(
                      'Normalpreis nach Break-even',
                      formatEuro(_normalPriceEurForScenario(draft, scenario)),
                    ),
                    _valueRow(
                      'Feature-Ueberschuss bei Zielauslastung',
                      formatEuro(_featureBudgetAtTargetAfterBreakEven(draft, scenario)),
                    ),
                  ],
                ),
                ),
              ),
            ),
          );
        }),
        _sectionCard(
          context,
          title: 'Event kann wachsen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ein Event soll klein glaubwuerdig starten und spaeter in eine groessere Location wachsen koennen, sobald die kleinere Variante sauber zieht.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: growthPath
                    .map((scenario) => Chip(label: Text('${scenario.name}: ${scenario.capacity}')))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
