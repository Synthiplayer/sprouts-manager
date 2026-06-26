part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildBreakEvenTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final earlyBirdPrice =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Break-even / Detailansicht',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Die eigentliche Abschluss-Sachlage steht jetzt im Main-Tab. Hier bleiben die Break-even-Details fuer Vergleich und Szenarioarbeit.',
              ),
              const SizedBox(height: 12),
              _buildCalculationMainOverview(
                context,
                draft,
                scenario,
                earlyBirdPrice: earlyBirdPrice,
                normalPrice: normalPrice,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Break-even je Szenario',
          child: Column(
            children: draft.scenarios.map((scenario) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    _valueRow(
                      'Zu deckender Betrag',
                      formatEuro(_amountToCoverAfterSupportEur(draft, scenario)),
                    ),
                    _valueRow(
                      'Zielteilnehmer fuer Break-even',
                      '${_scenarioTargetAttendees(scenario)}',
                    ),
                    _valueRow(
                      'Noetiger Early-Bird-Preis bei ${_scenarioTargetAttendees(scenario)} Personen',
                      formatEuro(
                        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario),
                      ),
                    ),
                    _valueRow(
                      'Normalpreis nach Break-even',
                      formatEuro(_normalPriceEurForScenario(draft, scenario)),
                    ),
                    _valueRow(
                      'Ueberschuss durch Normalpreis bei ${_scenarioTargetAttendees(scenario)} Personen',
                      formatEuro(_normalPhaseGrossSurplusAtTarget(draft, scenario)),
                    ),
                    _valueRow(
                      'Feature-Budget nach Break-even',
                      formatEuro(
                        _featureBudgetAtTargetAfterBreakEven(draft, scenario),
                      ),
                    ),
                    _valueRow(
                      'Preisstatus',
                      _riskStatusLabel(draft, scenario),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Upgrade nach Break-even',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final stage in draft.upgradeStages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Ab ${formatEuro(stage.minimumBudgetEur)} Zusatzbudget: ${stage.label}',
                  ),
                ),
              const SizedBox(height: 10),
              const Text(
                'Nach Break-even koennen Teilnehmer spaeter ueber gewuenschte Upgrades abstimmen: Showeffekte, Freigetraenke, Support-Act, EVC-Erstattung oder Ruecklage.',
              ),
            ],
          ),
        ),
      ],
    );
  }

}
