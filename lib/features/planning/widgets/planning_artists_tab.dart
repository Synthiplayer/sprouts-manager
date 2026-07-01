part of '../planning_screen.dart';

class PlanningArtistsTab extends StatefulWidget {
  final PlanningDraft draft;
  final PlanningScenario scenario;
  final List<PlanningArtistCostItem> items;
  final ValueChanged<List<PlanningArtistCostItem>> onItemsChanged;

  const PlanningArtistsTab({
    super.key,
    required this.draft,
    required this.scenario,
    required this.items,
    required this.onItemsChanged,
  });

  @override
  State<PlanningArtistsTab> createState() => _PlanningArtistsTabState();
}

class _PlanningArtistsTabState extends State<PlanningArtistsTab> {
  late List<PlanningArtistCostItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant PlanningArtistsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.id != widget.draft.id ||
        oldWidget.items != widget.items) {
      _items = [...widget.items];
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalArtistDetails = _artistCostTotalEur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: '$_programCostLabel brutto',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alle Werte werden als Brutto-Beträge geplant. Positionen aus Bausteinen können hier je Planung angepasst werden.',
              ),
              const SizedBox(height: 12),
              _valueRow(
                'Detailpositionen brutto',
                formatEuro(totalArtistDetails),
              ),
              const Text(
                'Die Main-Kalkulation nutzt nur die Programmpositionen, die in der Planungsbox liegen.',
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
                  label: const Text('Position hinzufügen'),
                ),
              ),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                Text(_emptyProgramText)
              else
                for (final item in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ArtistCostItemEditor(
                      key: ValueKey(item.id),
                      item: item,
                      onChanged: (updated) => _replaceItem(item.id, updated),
                      onDelete: () => _deleteItem(item.id),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Spaeter ausbauen',
          child: const Text(
            'Als naechster Schritt koennen variable Kuenstlervereinbarungen dazu: Grundgage plus Betrag pro Besucher, Staffel ab Schwelle oder individuelle Umsatzbeteiligung.',
          ),
        ),
      ],
    );
  }

  double get _artistCostTotalEur {
    return _items.fold<double>(
      0,
      (total, item) => total + item.grossAmountEur,
    );
  }

  bool get _isCinemaPlanning {
    final text = '${widget.draft.title} ${widget.draft.format}'.toLowerCase();
    return widget.draft.category == EventCategory.movie ||
        text.contains('kino') ||
        text.contains('film');
  }

  String get _programCostLabel {
    if (_isCinemaPlanning) {
      return 'Film- und Programmkosten';
    }
    return 'Kuenstler- und Programmkosten';
  }

  String get _emptyProgramText {
    if (_isCinemaPlanning) {
      return 'Noch keine Film- oder Programmpositionen angelegt. Fuege z. B. Filmrechte, Vorfuehrlizenz oder Begleitprogramm hinzu.';
    }
    return 'Noch keine Kuenstlerpositionen angelegt. Fuege z. B. Hauptact, Support, DJ, Reise, Hotel oder Backstage hinzu.';
  }

  void _addItem() {
    _setItems([
      ..._items,
      PlanningArtistCostItem(
        id: 'artist-${DateTime.now().microsecondsSinceEpoch}',
        label: '',
        type: PlanningArtistCostType.mainActFee,
        grossAmountEur: 0,
      ),
    ]);
  }

  void _replaceItem(String id, PlanningArtistCostItem updated) {
    _setItems([
      for (final item in _items)
        if (item.id == id) updated else item,
    ]);
  }

  void _deleteItem(String id) {
    _setItems(_items.where((item) => item.id != id).toList());
  }

  void _setItems(List<PlanningArtistCostItem> items) {
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

class _ArtistCostItemEditor extends StatelessWidget {
  final PlanningArtistCostItem item;
  final ValueChanged<PlanningArtistCostItem> onChanged;
  final VoidCallback onDelete;

  const _ArtistCostItemEditor({
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
                child: DropdownButtonFormField<PlanningArtistCostType>(
                  initialValue: item.type,
                  decoration: const InputDecoration(
                    labelText: 'Art',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: PlanningArtistCostType.values
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
                width: 180,
                child: TextFormField(
                  key: ValueKey('${item.id}-amount'),
                  initialValue: _editableMoneyValue(item.grossAmountEur),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Brutto',
                    suffixText: 'EUR',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(grossAmountEur: parseEuroInput(value)),
                    );
                  },
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
              labelText: 'Hinweis / Vereinbarung',
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
