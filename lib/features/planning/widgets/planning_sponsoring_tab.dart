part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildSponsoringTab(BuildContext context, PlanningDraft draft) {
    final fundingItems = _fundingItemsForDraft(draft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Finanzierungspositionen',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _showFundingItemDialog(context, draft),
                  icon: const Icon(Icons.add),
                  label: const Text('Position hinzufügen'),
                ),
              ),
              const SizedBox(height: 12),
              if (fundingItems.isEmpty)
                const Text('Noch keine Gegenfinanzierung eingetragen.')
              else
                Column(
                  children: [
                    for (final item in fundingItems)
                      _fundingItemRow(context, draft, item),
                    const Divider(height: 20),
                    _valueRow(
                      'Gesamte Gegenfinanzierung',
                      formatEuro(_totalSupportEur(draft)),
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Mögliche Werbepartner aus Datenbank',
          child: Column(
            children: draft.partners.map((partner) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${partner.name} - ${partner.type.label}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sponsorprofil: ${partner.audienceFocus}',
                          ),
                          Text(
                            'Potenzial: ${formatEuro(partner.expectedAmountEur)} | Fokus: ${partner.note}',
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showFundingItemDialog(
                        context,
                        draft,
                        partner: partner,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Übernehmen'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _fundingItemRow(
    BuildContext context,
    PlanningDraft draft,
    PlanningFundingItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.volunteer_activism_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(_fundingTypeAndLevelLabel(item)),
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(item.note.trim()),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatEuro(item.amountEur),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: () => _showFundingItemDialog(context, draft, item: item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: () {
              _refreshPlanningUi(() {
                _removeFundingItem(draft, item.id);
              });
              _savePlanningSandboxState();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _showFundingItemDialog(
    BuildContext context,
    PlanningDraft draft, {
    PlanningFundingItem? item,
    PlanningPartnerProfile? partner,
  }) async {
    final result = await showDialog<PlanningFundingItem>(
      context: context,
      builder: (_) => _FundingItemDialog(
        item: item,
        initialName: item?.name ?? partner?.name ?? '',
        initialNote: item?.note ?? partner?.note ?? '',
        initialType: item?.type ?? _fundingTypeForPartner(partner),
        initialAmountText: item != null && item.amountEur != 0
            ? _editableMoneyValue(item.amountEur)
            : partner != null && partner.expectedAmountEur != 0
                ? _editableMoneyValue(partner.expectedAmountEur)
                : '',
      ),
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _upsertFundingItem(draft, result);
    });
    _savePlanningSandboxState();
  }

  PlanningFundingType _fundingTypeForPartner(PlanningPartnerProfile? partner) {
    if (partner?.type == PlanningPartnerType.supporter) {
      return PlanningFundingType.supporter;
    }
    return PlanningFundingType.eventSponsor;
  }
}

class _FundingItemDialog extends StatefulWidget {
  const _FundingItemDialog({
    required this.initialAmountText,
    required this.initialName,
    required this.initialNote,
    required this.initialType,
    this.item,
  });

  final PlanningFundingItem? item;
  final String initialAmountText;
  final String initialName;
  final String initialNote;
  final PlanningFundingType initialType;

  @override
  State<_FundingItemDialog> createState() => _FundingItemDialogState();
}

class _FundingItemDialogState extends State<_FundingItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late PlanningFundingType _selectedType;
  late PlanningSponsorshipLevel _selectedLevel;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: widget.initialName);
    _amountController = TextEditingController(text: widget.initialAmountText);
    _noteController = TextEditingController(text: widget.initialNote);
    _selectedType = widget.initialType;
    _selectedLevel = item?.level ?? PlanningSponsorshipLevel.none;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AlertDialog(
      title: Text(
        item == null ? 'Finanzierung hinzufügen' : 'Finanzierung bearbeiten',
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Firma, Förderer oder Sponsor',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlanningFundingType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Art'),
              items: [
                for (final type in PlanningFundingType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ),
              ],
              onChanged: (type) {
                if (type == null) {
                  return;
                }
                setState(() {
                  _selectedType = type;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlanningSponsorshipLevel>(
              initialValue: _selectedLevel,
              decoration: const InputDecoration(labelText: 'Event-Level'),
              items: [
                for (final level in PlanningSponsorshipLevel.values)
                  DropdownMenuItem(
                    value: level,
                    child: Text(level.label),
                  ),
              ],
              onChanged: (level) {
                if (level == null) {
                  return;
                }
                setState(() {
                  _selectedLevel = level;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Betrag brutto',
                hintText: '0',
                suffixText: 'EUR',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notiz'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final amount = parseEuroInput(_amountController.text);
            Navigator.of(context).pop(
              PlanningFundingItem(
                id: item?.id ??
                    'funding-${DateTime.now().microsecondsSinceEpoch}',
                name: name.isEmpty ? _selectedType.label : name,
                type: _selectedType,
                level: _selectedLevel,
                amountEur: amount < 0 ? 0 : amount,
                note: _noteController.text.trim(),
              ),
            );
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
