part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildTicketsTab(BuildContext context, PlanningDraft draft) {
    final scenario = _recommendedScenario(draft);
    final earlyBirdPrice = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final markupPercent = _normalPriceMarkupPercent(draft);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Ticketstrategie',
          child: Column(
            children: [
              _valueRow(
                'Early-Bird-Preis aus Sachlage',
                '${earlyBirdPrice.round()} EVC / ${formatEuro(earlyBirdPrice)}',
              ),
              _valueRow('Ausgewaehltes Szenario', '${scenario.name} - ${scenario.locationName}'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: TextFormField(
                    initialValue: (markupPercent * 100).round().toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Normalpreis-Aufschlag in %',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => _updateNormalPriceMarkup(draft, value),
                    onFieldSubmitted: (value) {
                      _refreshPlanningUi(() {
                        _updateNormalPriceMarkup(draft, value);
                      });
                    },
                    onEditingComplete: _refreshPlanningUi,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _valueRow(
                'Normalpreis nach Break-even',
                '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
              ),
              _valueRow(
                'Aufschlag auf Early Bird',
                '${(markupPercent * 100).round()} %',
              ),
              _valueRow(
                'Early Bird finanziert Break-even',
                'vollstaendig ueber Zielauslastung',
              ),
              _valueRow(
                'Normalpreis gilt nach Break-even',
                'Ueberschuss / Features / mehr Marge',
              ),
              _valueRow(
                'Mehrbetrag pro Normalpreis-Ticket',
                formatEuro(normalPrice - earlyBirdPrice),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Szenarien gegen Ticketplan',
          child: Column(
            children: draft.scenarios.map((scenario) {
              final required = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
              final normalPrice = _normalPriceEurForScenario(draft, scenario);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${scenario.name} - noetig ${formatEuro(required)} bis Break-even',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('danach ${formatEuro(normalPrice)} Normalpreis'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Vorab-Pruefung',
          child: const Text(
            'Zuerst wird der Early-Bird-Preis aus Halle und Zielauslastung abgeleitet. Der Normalpreis wird danach ueber den Aufschlag berechnet und auf volle Euro aufgerundet.',
          ),
        ),
      ],
    );
  }

}
