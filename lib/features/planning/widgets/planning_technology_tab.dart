part of '../planning_screen.dart';

class PlanningTechnologyTab extends StatefulWidget {
  final PlanningDraft draft;
  final PlanningScenario scenario;
  final List<PlanningTechnologyCostItem> items;
  final ValueChanged<List<PlanningTechnologyCostItem>> onItemsChanged;

  const PlanningTechnologyTab({
    super.key,
    required this.draft,
    required this.scenario,
    required this.items,
    required this.onItemsChanged,
  });

  @override
  State<PlanningTechnologyTab> createState() => _PlanningTechnologyTabState();
}

class _PlanningTechnologyTabState extends State<PlanningTechnologyTab> {
  late List<PlanningTechnologyCostItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant PlanningTechnologyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.id != widget.draft.id ||
        oldWidget.items != widget.items) {
      _items = [...widget.items];
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTechnologyDetails = _technologyCostTotalEur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Technikkosten brutto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hier werden nur die Technikpositionen gepflegt, die wirklich zusaetzlich geliehen oder bezahlt werden muessen. Vorhandene Hausanlage oder Buehne muss nicht erneut eingetragen werden.',
              ),
              const SizedBox(height: 12),
              _valueRow(
                'Detailpositionen brutto',
                formatEuro(totalTechnologyDetails),
              ),
              _valueRow(
                'Aktuelles Szenario',
                '${widget.scenario.name} - ${widget.scenario.locationName}',
              ),
              const Text(
                'Wenn keine Position erfasst ist, nutzt die Main-Kalkulation den Szenario-Wert. Sobald hier Positionen stehen, ersetzen diese Brutto-Werte die Technik-Kosten des Szenarios.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Positionen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Position hinzufuegen'),
                ),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                const Text(
                  'Noch keine Technikpositionen angelegt. Fuege z. B. Ton, Licht, Buehne, Traversen, Leinwand / Beamer oder Sonstiges hinzu.',
                )
              else
                for (final item in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TechnologyCostItemEditor(
                      key: ValueKey(item.id),
                      item: item,
                      onChanged: (updated) => _replaceItem(item.id, updated),
                      onDelete: () => _deleteItem(item.id),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  double get _technologyCostTotalEur {
    return _items.fold<double>(
      0,
      (total, item) => total + item.grossTotalEur,
    );
  }

  void _addItem() {
    _setItems([
      ..._items,
      PlanningTechnologyCostItem(
        id: 'technology-${DateTime.now().microsecondsSinceEpoch}',
        label: '',
        type: PlanningTechnologyCostType.sound,
        quantity: 1,
        grossUnitAmountEur: 0,
      ),
    ]);
  }

  void _replaceItem(String id, PlanningTechnologyCostItem updated) {
    _setItems([
      for (final item in _items)
        if (item.id == id) updated else item,
    ]);
  }

  void _deleteItem(String id) {
    _setItems(_items.where((item) => item.id != id).toList());
  }

  void _setItems(List<PlanningTechnologyCostItem> items) {
    setState(() {
      _items = items;
    });
    widget.onItemsChanged(items);
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

  Widget _valueRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnologyCostItemEditor extends StatelessWidget {
  final PlanningTechnologyCostItem item;
  final ValueChanged<PlanningTechnologyCostItem> onChanged;
  final VoidCallback onDelete;

  const _TechnologyCostItemEditor({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<PlanningTechnologyCostType>(
                  initialValue: item.type,
                  decoration: const InputDecoration(
                    labelText: 'Art',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PlanningTechnologyCostType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type == null) {
                      return;
                    }
                    onChanged(item.copyWith(type: type));
                  },
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  key: ValueKey('${item.id}-label'),
                  initialValue: item.label,
                  decoration: const InputDecoration(
                    labelText: 'Bezeichnung',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    onChanged(item.copyWith(label: value));
                  },
                ),
              ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  key: ValueKey('${item.id}-quantity'),
                  initialValue: '${item.quantity}',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Anzahl',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(quantity: int.tryParse(value.trim()) ?? 1),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextFormField(
                  key: ValueKey('${item.id}-amount'),
                  initialValue: _editableMoneyValue(item.grossUnitAmountEur),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Einzelpreis brutto',
                    suffixText: 'EUR',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(grossUnitAmountEur: parseEuroInput(value)),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: Text(
                  formatEuro(item.grossTotalEur),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Position loeschen',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${item.id}-note'),
            initialValue: item.note,
            decoration: const InputDecoration(
              labelText: 'Hinweis / Anbieter',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (value) {
              onChanged(item.copyWith(note: value));
            },
          ),
        ],
      ),
    );
  }

  String _editableMoneyValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
