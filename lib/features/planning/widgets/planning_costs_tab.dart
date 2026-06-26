part of '../planning_screen.dart';

class PlanningCostsTab extends StatelessWidget {
  final PlanningDraft draft;
  final PlanningScenario scenario;
  final List<PlanningCostOverviewItem> items;

  const PlanningCostsTab({
    super.key,
    required this.draft,
    required this.scenario,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final fixedTotal = items
        .where((item) => !item.isVariable)
        .fold<double>(0, (total, item) => total + item.amountEur);
    final variableTotal = items
        .where((item) => item.isVariable)
        .fold<double>(0, (total, item) => total + item.amountEur);
    final total = fixedTotal + variableTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Kostenuebersicht brutto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${draft.title} - ${scenario.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Diese Ansicht zeigt nur geplante Event-Ausgaben. Gewinn, Risiko, Leckage, Reserve und Finanzierung bleiben in Main und Break-even.',
              ),
              const SizedBox(height: 14),
              _summaryRow('Fixe Kosten', formatEuro(fixedTotal)),
              _summaryRow('Variable Wachstumskosten', formatEuro(variableTotal)),
              _summaryRow(
                'Eventkosten brutto gesamt',
                formatEuro(total),
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Positionen',
          child: Column(
            children: [
              _headerRow(context),
              const Divider(height: 16),
              if (items.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Noch keine Kostenpositionen aktiv.'),
                )
              else
                for (final item in items) _costRow(context, item),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Row(
      children: [
        Expanded(flex: 3, child: Text('Position', style: style)),
        Expanded(flex: 2, child: Text('Quelle', style: style)),
        Expanded(
          flex: 2,
          child: Text(
            'Brutto',
            textAlign: TextAlign.right,
            style: style,
          ),
        ),
      ],
    );
  }

  Widget _costRow(BuildContext context, PlanningCostOverviewItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (item.isVariable) ...[
                  const Icon(Icons.trending_up, size: 16),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(item.source)),
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
    );
  }
}
