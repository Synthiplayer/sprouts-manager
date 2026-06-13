import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/event_currency_config.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';

enum PlanningWorkspaceTab {
  main,
  scenarios,
  tickets,
  sponsoring,
  breakEven,
}

enum PlanningPartnerType {
  advertisingPartner,
  eventSponsor,
  supporter,
}

extension PlanningPartnerTypeX on PlanningPartnerType {
  String get label {
    switch (this) {
      case PlanningPartnerType.advertisingPartner:
        return 'Werbepartner';
      case PlanningPartnerType.eventSponsor:
        return 'Event-Sponsor';
      case PlanningPartnerType.supporter:
        return 'Unterstuetzer';
    }
  }
}

enum PartnerTier {
  silver,
  gold,
  premium,
  custom,
}

extension PartnerTierX on PartnerTier {
  String get label {
    switch (this) {
      case PartnerTier.silver:
        return 'Silber';
      case PartnerTier.gold:
        return 'Gold';
      case PartnerTier.premium:
        return 'Premium';
      case PartnerTier.custom:
        return 'Individuell';
    }
  }
}

enum PlanningScenarioOption {
  stage,
  sound,
  light,
  backstage,
  medical,
  security,
  toilets,
  barriers,
}

extension PlanningScenarioOptionX on PlanningScenarioOption {
  String get label {
    switch (this) {
      case PlanningScenarioOption.stage:
        return 'Buehne';
      case PlanningScenarioOption.sound:
        return 'Ton';
      case PlanningScenarioOption.light:
        return 'Licht';
      case PlanningScenarioOption.backstage:
        return 'Backstage';
      case PlanningScenarioOption.medical:
        return 'Sanitaeter';
      case PlanningScenarioOption.security:
        return 'Security';
      case PlanningScenarioOption.toilets:
        return 'Toiletten';
      case PlanningScenarioOption.barriers:
        return 'Absperrgitter';
    }
  }
}

enum PlanningStaffingCategory {
  security,
  medical,
  staff,
}

extension PlanningStaffingCategoryX on PlanningStaffingCategory {
  String get label {
    switch (this) {
      case PlanningStaffingCategory.security:
        return 'Security';
      case PlanningStaffingCategory.medical:
        return 'Sanitaeter';
      case PlanningStaffingCategory.staff:
        return 'Personal';
    }
  }
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final List<PlanningDraft> _drafts = PlanningDraft.sandboxDrafts;
  final Map<String, Map<PlanningScenarioOption, bool>> _draftOptionOverrides = {};
  final Map<String, double> _scenarioOccupancyOverrides = {};
  final Map<String, bool> _staffingItemOverrides = {};
  final Map<String, int> _staffingPeopleOverrides = {};
  final Map<String, double> _staffingHoursOverrides = {};
  final Map<String, double> _staffingRateOverrides = {};
  String? _selectedDraftId;
  PlanningWorkspaceTab _tab = PlanningWorkspaceTab.main;

  @override
  void initState() {
    super.initState();
    if (_drafts.isNotEmpty) {
      _selectedDraftId = _drafts.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1080;
    final selectedDraft = _drafts.firstWhere(
      (draft) => draft.id == _selectedDraftId,
      orElse: () => _drafts.first,
    );

    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(context),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      SizedBox(
                        width: 360,
                        child: _buildDraftList(context, selectedDraft),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildDraftWorkspace(context, selectedDraft),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 290,
                        child: _buildDraftList(context, selectedDraft),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _buildDraftWorkspace(context, selectedDraft),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planung',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hier wird aus einer Eventidee ueber Sachlage entschieden: Szenarien, Ticketpreise, Sponsoring und Break-even.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _showPlaceholderDialog(
                  context,
                  title: 'Aus Vorlage erstellen',
                  message:
                      'Spaeter kann hier ein neuer Planungsentwurf aus einer vorhandenen Vorlage erstellt werden.',
                ),
                child: const Text('Aus Vorlage erstellen'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showPlaceholderDialog(
                  context,
                  title: 'Vergangenes Event kopieren',
                  message:
                      'Spaeter kann hier ein frueheres Event als neue Planungsvorlage uebernommen werden.',
                ),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Vergangenes Event kopieren'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftList(BuildContext context, PlanningDraft selectedDraft) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        final isSelected = draft.id == selectedDraft.id;
        final recommendedScenario = _recommendedScenario(draft);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: draft.category.color.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? draft.category.color : Colors.transparent,
                width: isSelected ? 2.2 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  _selectedDraftId = draft.id;
                  _tab = PlanningWorkspaceTab.main;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        draft.category.toChip(),
                        _pill(context, draft.planningStatus),
                        _pill(context, _mainDecisionStatus(draft)),
                        if (isSelected) _pill(context, 'Ausgewaehlt'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      draft.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      draft.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Empfohlen: ${recommendedScenario.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Kapazitaet: ${recommendedScenario.capacity} | Zielauslastung: ${(_scenarioOccupancy(recommendedScenario) * 100).round()} %',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Noetiger Early-Bird-Preis: ${formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, recommendedScenario))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aktueller Plan: ${draft.normalPriceEvc} EVC / ${formatEuro(draft.normalPriceEur)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraftWorkspace(BuildContext context, PlanningDraft draft) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              draft.category.toChip(),
              _pill(context, draft.planningStatus),
              _pill(context, _mainDecisionStatus(draft)),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<PlanningWorkspaceTab>(
            segments: const [
              ButtonSegment(
                value: PlanningWorkspaceTab.main,
                label: Text('Main'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.scenarios,
                label: Text('Szenarien'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.tickets,
                label: Text('Tickets'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.sponsoring,
                label: Text('Sponsoring'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.breakEven,
                label: Text('Break-even'),
              ),
            ],
            selected: <PlanningWorkspaceTab>{_tab},
            onSelectionChanged: (selection) {
              setState(() {
                _tab = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _showPlaceholderDialog(
                  context,
                  title: 'Als Event veroeffentlichen',
                  message:
                      'Spaeter kann dieser Planungsentwurf als konkretes Event in die Eventverwaltung uebernommen werden.',
                ),
                child: const Text('Als Event veroeffentlichen'),
              ),
              OutlinedButton(
                onPressed: () => _showPlaceholderDialog(
                  context,
                  title: 'Pre-Sale / Abstimmung',
                  message:
                      'Spaeter kann aus dem Ticket- und Break-even-Stand direkt eine Vorab-Abstimmung oder ein Pre-Sale gestartet werden.',
                ),
                child: const Text('Pre-Sale vorbereiten'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          switch (_tab) {
            PlanningWorkspaceTab.main => _buildMainTab(context, draft),
            PlanningWorkspaceTab.scenarios => _buildScenariosTab(context, draft),
            PlanningWorkspaceTab.tickets => _buildTicketsTab(context, draft),
            PlanningWorkspaceTab.sponsoring => _buildSponsoringTab(context, draft),
            PlanningWorkspaceTab.breakEven => _buildBreakEvenTab(context, draft),
          },
        ],
      ),
    );
  }

  Widget _buildMainTab(BuildContext context, PlanningDraft draft) {
    final scenario = _recommendedScenario(draft);
    final visibleStaffingItems = _visibleStaffingItems(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Main / Entscheidungsansicht',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _valueRow('Arbeitstitel', draft.title),
              _valueRow('Kategorie', draft.category.label),
              _valueRow('Format', draft.format),
              _valueRow('Zielgruppe', draft.targetAudience),
              _valueRow('Empfohlenes Szenario', '${scenario.name} - ${scenario.locationName}'),
              _valueRow(
                'Noetiger Early-Bird-Preis bei Zielauslastung',
                formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario)),
              ),
              _valueRow(
                'Benoetigte Early-Bird-Tickets bis Break-even',
                '${_breakEvenEarlyBirdTickets(draft, scenario)}',
              ),
              _valueRow(
                'Normalpreis nach Break-even',
                '${draft.normalPriceEvc} EVC / ${formatEuro(draft.normalPriceEur)}',
              ),
              _valueRow(
                'Gesamte Unterstuetzung',
                formatEuro(draft.totalSupportEur),
              ),
              _valueRow(
                'Feature-Ueberschuss bei Zielauslastung',
                formatEuro(_featureBudgetAtTargetAfterBreakEven(draft, scenario)),
              ),
              _valueRow('Sachlage', _mainDecisionSummary(draft)),
            ],
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
                      setState(() {
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
                    setState(() {
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
                onApply: () => setState(() {}),
              ),
              _staffingNumberField(
                context,
                label: 'Stunden',
                initialValue: _staffingHours(item).toStringAsFixed(
                  _staffingHours(item) == _staffingHours(item).roundToDouble() ? 0 : 1,
                ),
                onChangedValue: (value) => _updateStaffingHours(item, value),
                onApply: () => setState(() {}),
              ),
              _staffingNumberField(
                context,
                label: 'Satz / Stunde brutto',
                initialValue: _editableMoneyValue(_staffingHourlyRate(item)),
                onChangedValue: (value) => _updateStaffingRate(item, value),
                onApply: () => setState(() {}),
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

  Widget _buildScenariosTab(BuildContext context, PlanningDraft draft) {
    final growthPath = [...draft.scenarios]
      ..sort((a, b) => a.capacity.compareTo(b.capacity));

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
        ...draft.scenarios.map((scenario) {
          final isRecommended = scenario.id == _recommendedScenario(draft).id;
          final occupancy = _scenarioOccupancy(scenario);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRecommended
                      ? draft.category.color
                      : Theme.of(context).dividerColor,
                  width: isRecommended ? 2 : 1,
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
                        if (isRecommended) _pill(context, 'Empfohlen'),
                        _pill(context, _riskStatusLabel(draft, scenario)),
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
                        if (_visibleStaffingCostByCategory(
                              draft,
                              scenario,
                              PlanningStaffingCategory.security,
                            ) >
                            0)
                          _infoPair(
                            'Security',
                            formatEuro(
                              _visibleStaffingCostByCategory(
                                draft,
                                scenario,
                                PlanningStaffingCategory.security,
                              ),
                            ),
                          ),
                        if (_visibleStaffingCostByCategory(
                              draft,
                              scenario,
                              PlanningStaffingCategory.staff,
                            ) >
                            0)
                          _infoPair(
                            'Personal',
                            formatEuro(
                              _visibleStaffingCostByCategory(
                                draft,
                                scenario,
                                PlanningStaffingCategory.staff,
                              ),
                            ),
                          ),
                        if (_visibleStaffingCostByCategory(
                              draft,
                              scenario,
                              PlanningStaffingCategory.medical,
                            ) >
                            0)
                          _infoPair(
                            'Sanitaeter',
                            formatEuro(
                              _visibleStaffingCostByCategory(
                                draft,
                                scenario,
                                PlanningStaffingCategory.medical,
                              ),
                            ),
                          ),
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
                        setState(() {
                          _scenarioOccupancyOverrides[scenario.id] = value;
                        });
                      },
                    ),
                    _valueRow(
                      'Gesamtkosten inkl. Reserve, Leckage, Marge',
                      formatEuro(_totalPlannedCostsEur(draft, scenario)),
                    ),
                    _valueRow(
                      'Zu deckender Betrag nach Unterstuetzung',
                      formatEuro(_amountToCoverAfterSupportEur(draft, scenario)),
                    ),
                    _valueRow(
                      'Noetiger Early-Bird-Preis bei Zielauslastung',
                      formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario)),
                    ),
                    _valueRow(
                      'Benoetigte Early-Bird-Tickets bis Break-even',
                      '${_breakEvenEarlyBirdTickets(draft, scenario)}',
                    ),
                    _valueRow(
                      'Feature-Ueberschuss bei Zielauslastung',
                      formatEuro(_featureBudgetAtTargetAfterBreakEven(draft, scenario)),
                    ),
                  ],
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

  Widget _buildTicketsTab(BuildContext context, PlanningDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Ticketstrategie',
          child: Column(
            children: [
              _valueRow(
                'Early-Bird-Preis',
                '${draft.earlyBirdPriceEvc} EVC / ${formatEuro(draft.earlyBirdPriceEur)}',
              ),
              _valueRow(
                'Normalpreis',
                '${draft.normalPriceEvc} EVC / ${formatEuro(draft.normalPriceEur)}',
              ),
              _valueRow(
                'Vorab-Abstimmung / Pre-Sale',
                '${draft.presaleVotingPriceEvc} EVC / ${formatEuro(draft.presaleVotingPriceEur)}',
              ),
              _valueRow(
                'Early-Bird dient bis Break-even',
                'Event auf die Beine stellen',
              ),
              _valueRow(
                'Normalpreis gilt nach Break-even',
                'Ueberschuss / Features / mehr Marge',
              ),
              _valueRow(
                'Normalpreis-Ueberschuss pro Ticket',
                formatEuro(_normalPriceSurplusPerTicketAfterBreakEven(draft)),
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
              final fitLabel = _ticketFitLabelForScenario(draft, scenario);
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
                    Text(fitLabel),
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
            'Sobald ein Ticketpreis aus der Sachlage ableitbar ist, kann dieser in die Abstimmung oder in einen spaeteren Pre-Sale gegeben werden, um echte Nachfrage zu pruefen.',
          ),
        ),
      ],
    );
  }

  Widget _buildSponsoringTab(BuildContext context, PlanningDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Finanzierungsbausteine',
          child: Column(
            children: [
              _valueRow(
                'Event-Sponsoring fix',
                formatEuro(draft.fixedSponsorAmountEur),
              ),
              _valueRow(
                'Unterstuetzer / Eventhilfe',
                formatEuro(draft.supporterAmountEur),
              ),
              _valueRow(
                'Zuschuss / Foerderung',
                formatEuro(draft.grantAmountEur),
              ),
              _valueRow(
                'Gesamtunterstuetzung',
                formatEuro(draft.totalSupportEur),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Passende Werbepartner und Sponsoren',
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
                            'Zielgruppe: ${partner.audienceFocus} | Level: ${partner.tier.label}',
                          ),
                          Text(
                            'Potenzial: ${formatEuro(partner.expectedAmountEur)} | Fokus: ${partner.note}',
                          ),
                        ],
                      ),
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
          title: 'Sponsoring-Ziel',
          child: Text(
            'Ziel ist, mehrere Werbepartner und Unterstuetzer so zu kombinieren, dass das Event eher stattfindet und der noetige Ticketpreis sinkt. Aktuell vorbereitet: ${draft.partnerSummary}.',
          ),
        ),
      ],
    );
  }

  Widget _buildBreakEvenTab(BuildContext context, PlanningDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Break-even / Main',
          child: Column(
            children: [
              _valueRow(
                'Early-Bird-Preis',
                '${draft.earlyBirdPriceEvc} EVC / ${formatEuro(draft.earlyBirdPriceEur)}',
              ),
              _valueRow(
                'Gesamte Unterstuetzung',
                formatEuro(draft.totalSupportEur),
              ),
              _valueRow(
                'Leckage',
                '${(draft.leakagePercent * 100).round()} %',
              ),
              _valueRow(
                'Reserve',
                '${(draft.reservePercent * 100).round()} %',
              ),
              _valueRow(
                'Veranstalter-Marge bis Break-even',
                '${(draft.organizerMarginPercent * 100).round()} %',
              ),
              _valueRow(
                'Veranstalter-Marge nach Break-even',
                '${(draft.postBreakEvenMarginPercent * 100).round()} %',
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
                      'Benoetigte Early-Bird-Tickets',
                      '${_breakEvenEarlyBirdTickets(draft, scenario)}',
                    ),
                    _valueRow(
                      'Noetiger Early-Bird-Preis bei ${_scenarioTargetAttendees(scenario)} Personen',
                      formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario)),
                    ),
                    _valueRow(
                      'Ueberschuss durch Normalpreis bei ${_scenarioTargetAttendees(scenario)} Personen',
                      formatEuro(_normalPhaseGrossSurplusAtTarget(draft, scenario)),
                    ),
                    _valueRow(
                      'Feature-Budget nach Break-even',
                      formatEuro(_featureBudgetAtTargetAfterBreakEven(draft, scenario)),
                    ),
                    _valueRow(
                      'Bewertung',
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

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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

  Widget _pill(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value) {
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
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceholderDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schliessen'),
          ),
        ],
      ),
    );
  }

  bool _isOptionEnabled(PlanningDraft draft, PlanningScenarioOption option) {
    return _draftOptionOverrides[draft.id]?[option] ?? _defaultOptionEnabled(draft, option);
  }

  bool _defaultOptionEnabled(PlanningDraft draft, PlanningScenarioOption option) {
    switch (option) {
      case PlanningScenarioOption.stage:
        return draft.requiresStage;
      case PlanningScenarioOption.sound:
        return draft.requiresSound;
      case PlanningScenarioOption.light:
        return draft.requiresLight;
      case PlanningScenarioOption.backstage:
        return draft.requiresBackstage;
      case PlanningScenarioOption.medical:
        return draft.checkMedical;
      case PlanningScenarioOption.security:
        return draft.checkSecurity;
      case PlanningScenarioOption.toilets:
        return draft.checkToilets;
      case PlanningScenarioOption.barriers:
        return draft.checkBarriers;
    }
  }

  void _setOptionEnabled(
    PlanningDraft draft,
    PlanningScenarioOption option,
    bool value,
  ) {
    final options = _draftOptionOverrides.putIfAbsent(draft.id, () => {});
    options[option] = value;
  }

  bool _isStaffingItemEnabled(PlanningStaffingItem item) {
    return _staffingItemOverrides[item.id] ?? item.enabledByDefault;
  }

  void _setStaffingItemEnabled(PlanningStaffingItem item, bool value) {
    _staffingItemOverrides[item.id] = value;
  }

  List<PlanningStaffingItem> _visibleStaffingItems(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return scenario.staffingItems.where((item) {
      if (!_isStaffingCategoryActive(draft, item.category)) {
        return false;
      }
      if (item.isOptional && !_isStaffingItemEnabled(item)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _isStaffingCategoryActive(
    PlanningDraft draft,
    PlanningStaffingCategory category,
  ) {
    switch (category) {
      case PlanningStaffingCategory.security:
        return _isOptionEnabled(draft, PlanningScenarioOption.security);
      case PlanningStaffingCategory.medical:
        return _isOptionEnabled(draft, PlanningScenarioOption.medical);
      case PlanningStaffingCategory.staff:
        return true;
    }
  }

  int _staffingPeopleCount(PlanningStaffingItem item) {
    return _staffingPeopleOverrides[item.id] ?? item.peopleCount;
  }

  double _staffingHours(PlanningStaffingItem item) {
    return _staffingHoursOverrides[item.id] ?? item.hours;
  }

  double _staffingHourlyRate(PlanningStaffingItem item) {
    return _staffingRateOverrides[item.id] ?? item.hourlyRateEur;
  }

  double _staffingItemTotal(PlanningStaffingItem item) {
    return _staffingPeopleCount(item) *
        _staffingHours(item) *
        _staffingHourlyRate(item);
  }

  double _visibleStaffingCostTotal(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _visibleStaffingItems(draft, scenario).fold<double>(
      0,
      (sum, item) => sum + _staffingItemTotal(item),
    );
  }

  double _visibleStaffingCostByCategory(
    PlanningDraft draft,
    PlanningScenario scenario,
    PlanningStaffingCategory category,
  ) {
    return _visibleStaffingItems(draft, scenario)
        .where((item) => item.category == category)
        .fold<double>(0, (sum, item) => sum + _staffingItemTotal(item));
  }

  void _updateStaffingPeople(PlanningStaffingItem item, String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingPeopleOverrides[item.id] = parsed;
  }

  void _updateStaffingHours(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingHoursOverrides[item.id] = parsed;
  }

  void _updateStaffingRate(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingRateOverrides[item.id] = parsed;
  }

  double? _parsePlanningNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains(',') && trimmed.contains('.')) {
      return double.tryParse(
        trimmed.replaceAll('.', '').replaceAll(',', '.'),
      );
    }
    if (trimmed.contains(',')) {
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return double.tryParse(trimmed);
  }

  String _editableMoneyValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double _scenarioOccupancy(PlanningScenario scenario) {
    return _scenarioOccupancyOverrides[scenario.id] ?? scenario.targetOccupancyPercent;
  }

  int _scenarioTargetAttendees(PlanningScenario scenario) {
    return max(1, (scenario.capacity * _scenarioOccupancy(scenario)).round());
  }

  double _staffingCostForCategory(
    PlanningScenario scenario,
    PlanningStaffingCategory category,
  ) {
    return scenario.staffingItems
        .where((item) => item.category == category)
        .where((item) => _isStaffingItemEnabled(item))
        .fold<double>(0, (sum, item) => sum + _staffingItemTotal(item));
  }

  double _scenarioBaseCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    var total = scenario.baseRentEur +
        scenario.artistCostEur +
        scenario.technologyCostEur +
        scenario.gemaCostEur +
        scenario.insuranceCostEur +
        scenario.marketingCostEur +
        scenario.organizerWorkEur;

    if (_isOptionEnabled(draft, PlanningScenarioOption.security)) {
      total += scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.security)
          : scenario.securityCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.medical)) {
      total += scenario.staffingItems.isNotEmpty
          ? _staffingCostForCategory(scenario, PlanningStaffingCategory.medical)
          : scenario.medicalCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.toilets)) {
      total += scenario.toiletCostEur;
    }
    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      total += scenario.barriersCostEur;
    }

    if (scenario.staffingItems.isNotEmpty) {
      total += _staffingCostForCategory(scenario, PlanningStaffingCategory.staff);
    }

    return total;
  }

  double _totalPlannedCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    final base = _scenarioBaseCostsEur(draft, scenario);
    return base +
        (base * draft.leakagePercent) +
        (base * draft.reservePercent) +
        (base * draft.organizerMarginPercent);
  }

  double _amountToCoverAfterSupportEur(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final result = _totalPlannedCostsEur(draft, scenario) - draft.totalSupportEur;
    return result < 0 ? 0 : result;
  }

  double _requiredTicketPriceAtTargetOccupancy(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _amountToCoverAfterSupportEur(draft, scenario) /
        _scenarioTargetAttendees(scenario);
  }

  double _requiredEarlyBirdPriceAtTargetOccupancy(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _requiredTicketPriceAtTargetOccupancy(draft, scenario);
  }

  int _breakEvenEarlyBirdTickets(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    if (draft.earlyBirdPriceEur <= 0) {
      return 0;
    }

    return (_amountToCoverAfterSupportEur(draft, scenario) / draft.earlyBirdPriceEur)
        .ceil();
  }

  int _normalTicketsAfterBreakEvenAtTarget(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final remainder =
        _scenarioTargetAttendees(scenario) - _breakEvenEarlyBirdTickets(draft, scenario);
    return remainder < 0 ? 0 : remainder;
  }

  double _normalPriceSurplusPerTicketAfterBreakEven(PlanningDraft draft) {
    return draft.normalPriceEur;
  }

  double _organizerMarginPerNormalTicketAfterBreakEven(PlanningDraft draft) {
    return draft.normalPriceEur * draft.postBreakEvenMarginPercent;
  }

  double _normalPhaseGrossSurplusAtTarget(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
        _normalPriceSurplusPerTicketAfterBreakEven(draft);
  }

  double _featureBudgetAtTargetAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final gross = _normalPhaseGrossSurplusAtTarget(draft, scenario);
    final organizerPart =
        _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
            _organizerMarginPerNormalTicketAfterBreakEven(draft);
    final result = gross - organizerPart;
    return result < 0 ? 0 : result;
  }

  String _riskStatusLabel(PlanningDraft draft, PlanningScenario scenario) {
    final required = _requiredTicketPriceAtTargetOccupancy(draft, scenario);
    if (required <= draft.normalPriceEur) {
      return 'erreichbar';
    }
    if (required <= draft.normalPriceEur * 1.15) {
      return 'knapp';
    }
    return 'kritisch';
  }

  PlanningScenario _recommendedScenario(PlanningDraft draft) {
    final ranked = [...draft.scenarios]
      ..sort(
        (a, b) => _requiredTicketPriceAtTargetOccupancy(draft, a)
            .compareTo(_requiredTicketPriceAtTargetOccupancy(draft, b)),
      );
    return ranked.first;
  }

  String _mainDecisionStatus(PlanningDraft draft) {
    final required =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, _recommendedScenario(draft));
    if (required <= draft.earlyBirdPriceEur) {
      return 'erreichbar';
    }
    if (required <= draft.normalPriceEur) {
      return 'knapp';
    }
    return 'kritisch';
  }

  String _mainDecisionSummary(PlanningDraft draft) {
    final required =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, _recommendedScenario(draft));
    if (required <= draft.earlyBirdPriceEur) {
      return 'Mit dem Early-Bird-Preis kann das empfohlene Szenario bis Break-even getragen werden.';
    }
    if (required <= draft.normalPriceEur) {
      return 'Early Bird reicht noch nicht, aber mit spaeterem Normalpreis wirkt das Szenario grundsaetzlich darstellbar.';
    }
    return 'Ohne mehr Unterstuetzung, hoeheren Preis oder ein kleineres Szenario ist das Event aktuell kritisch.';
  }

  String _ticketFitLabelForScenario(PlanningDraft draft, PlanningScenario scenario) {
    final required = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    if (draft.earlyBirdPriceEur >= required) {
      return 'passt';
    }
    if (draft.normalPriceEur >= required) {
      return 'nur mit spaeterem Normalpreis tragbar';
    }
    return 'mehr Unterstuetzung noetig';
  }
}

class PlanningDraft {
  final String id;
  final String title;
  final EventCategory category;
  final String targetAudience;
  final String format;
  final String shortDescription;
  final String planningStatus;
  final int minimumCapacity;
  final String seatingMode;
  final bool requiresStage;
  final bool requiresSound;
  final bool requiresLight;
  final bool requiresBackstage;
  final bool checkMedical;
  final bool checkSecurity;
  final bool checkToilets;
  final bool checkBarriers;
  final int earlyBirdPriceEvc;
  final int normalPriceEvc;
  final int presaleVotingPriceEvc;
  final double expectedEarlyBirdShare;
  final double leakagePercent;
  final double reservePercent;
  final double organizerMarginPercent;
  final double postBreakEvenMarginPercent;
  final double fixedSponsorAmountEur;
  final double supporterAmountEur;
  final double grantAmountEur;
  final List<PlanningScenario> scenarios;
  final List<PlanningPartnerProfile> partners;
  final List<PlanningUpgradeStage> upgradeStages;

  const PlanningDraft({
    required this.id,
    required this.title,
    required this.category,
    required this.targetAudience,
    required this.format,
    required this.shortDescription,
    required this.planningStatus,
    required this.minimumCapacity,
    required this.seatingMode,
    required this.requiresStage,
    required this.requiresSound,
    required this.requiresLight,
    required this.requiresBackstage,
    required this.checkMedical,
    required this.checkSecurity,
    required this.checkToilets,
    required this.checkBarriers,
    required this.earlyBirdPriceEvc,
    required this.normalPriceEvc,
    required this.presaleVotingPriceEvc,
    required this.expectedEarlyBirdShare,
    required this.leakagePercent,
    required this.reservePercent,
    required this.organizerMarginPercent,
    required this.postBreakEvenMarginPercent,
    required this.fixedSponsorAmountEur,
    required this.supporterAmountEur,
    required this.grantAmountEur,
    required this.scenarios,
    required this.partners,
    required this.upgradeStages,
  });

  double get earlyBirdPriceEur => EventCurrencyConfig.evcToEur(earlyBirdPriceEvc);

  double get normalPriceEur => EventCurrencyConfig.evcToEur(normalPriceEvc);

  double get presaleVotingPriceEur =>
      EventCurrencyConfig.evcToEur(presaleVotingPriceEvc);

  double get totalSupportEur =>
      fixedSponsorAmountEur + supporterAmountEur + grantAmountEur;

  String get partnerSummary {
    final advertising = partners
        .where((partner) => partner.type == PlanningPartnerType.advertisingPartner)
        .length;
    final sponsors = partners
        .where((partner) => partner.type == PlanningPartnerType.eventSponsor)
        .length;
    final supporters = partners
        .where((partner) => partner.type == PlanningPartnerType.supporter)
        .length;
    return '$advertising Werbepartner, $sponsors Event-Sponsoren, $supporters Unterstuetzer';
  }

  static const List<PlanningDraft> sandboxDrafts = [
    PlanningDraft(
      id: 'vengaboys',
      title: 'Vengaboys Konzert',
      category: EventCategory.concert,
      targetAudience: '20-40, 90er / 2000er Publikum',
      format: 'Live-Konzert mit Party-Anschluss',
      shortDescription:
          'Nostalgie-Konzert mit hohem Showfaktor und anschliessender Aftershow.',
      planningStatus: 'Kuenstler-Anfrage laeuft',
      minimumCapacity: 700,
      seatingMode: 'Stehend',
      requiresStage: true,
      requiresSound: true,
      requiresLight: true,
      requiresBackstage: true,
      checkMedical: true,
      checkSecurity: true,
      checkToilets: true,
      checkBarriers: true,
      earlyBirdPriceEvc: 39,
      normalPriceEvc: 49,
      presaleVotingPriceEvc: 45,
      expectedEarlyBirdShare: 0.35,
      leakagePercent: 0.04,
      reservePercent: 0.08,
      organizerMarginPercent: 0.06,
      postBreakEvenMarginPercent: 0.14,
      fixedSponsorAmountEur: 1500,
      supporterAmountEur: 2500,
      grantAmountEur: 1000,
      scenarios: [
        PlanningScenario(
          id: 'venue-small',
          name: 'Kleine Halle',
          locationName: 'Halle Nord',
          setupName: 'Stehkonzert kompakt',
          capacity: 500,
          targetOccupancyPercent: 0.5,
          baseRentEur: 3200,
          artistCostEur: 8500,
          technologyCostEur: 2600,
          securityCostEur: 1400,
          medicalCostEur: 600,
          toiletCostEur: 400,
          gemaCostEur: 900,
          insuranceCostEur: 320,
          marketingCostEur: 1200,
          organizerWorkEur: 1500,
          barriersCostEur: 350,
          staffingItems: [
            PlanningStaffingItem(
              id: 'venue-small-security-core',
              label: 'Security Basis',
              category: PlanningStaffingCategory.security,
              peopleCount: 5,
              hours: 8,
              hourlyRateEur: 35,
              note: 'Kompakter Konzertstart mit fester Grundbesetzung.',
            ),
            PlanningStaffingItem(
              id: 'venue-small-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 2,
              hours: 6,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'venue-small-staff',
              label: 'Eventhelfer / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 2,
              hours: 8,
              hourlyRateEur: 20,
            ),
          ],
          locationNotes:
              'Kompaktes Szenario mit hoeherem noetigem Ticketpreis, aber realistischer Auslastung.',
        ),
        PlanningScenario(
          id: 'venue-medium',
          name: 'Mittelgrosses Konzert',
          locationName: 'Metropol',
          setupName: 'Konzertflaeche stehend',
          capacity: 850,
          targetOccupancyPercent: 0.5,
          baseRentEur: 6400,
          artistCostEur: 8500,
          technologyCostEur: 3800,
          securityCostEur: 2200,
          medicalCostEur: 900,
          toiletCostEur: 0,
          gemaCostEur: 1200,
          insuranceCostEur: 450,
          marketingCostEur: 1600,
          organizerWorkEur: 1800,
          barriersCostEur: 500,
          staffingItems: [
            PlanningStaffingItem(
              id: 'venue-medium-security-core',
              label: 'Security Standard Metropol',
              category: PlanningStaffingCategory.security,
              peopleCount: 5,
              hours: 8,
              hourlyRateEur: 45,
              note: 'Im Metropol meist 5 Security als Standardblock.',
            ),
            PlanningStaffingItem(
              id: 'venue-medium-security-extra',
              label: 'Zusaetzliche Security',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 8,
              hourlyRateEur: 25,
              note: 'Bei hoeherer Auslastung oder Partycharakter kann auf 6 aufgestockt werden.',
              isOptional: true,
              enabledByDefault: false,
            ),
            PlanningStaffingItem(
              id: 'venue-medium-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 2,
              hours: 6,
              hourlyRateEur: 75,
            ),
            PlanningStaffingItem(
              id: 'venue-medium-staff',
              label: 'Eventhelfer / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 3,
              hours: 8,
              hourlyRateEur: 20,
            ),
          ],
          locationNotes:
              'Groessere Showmoeglichkeit, mehr Werbewirkung, aber hoeherer Gesamtblock.',
        ),
        PlanningScenario(
          id: 'venue-large',
          name: 'Grosse Eventhalle',
          locationName: 'Eissporthalle',
          setupName: 'Konzertflaeche gross',
          capacity: 2000,
          targetOccupancyPercent: 0.5,
          baseRentEur: 9800,
          artistCostEur: 8500,
          technologyCostEur: 6200,
          securityCostEur: 4200,
          medicalCostEur: 1600,
          toiletCostEur: 1800,
          gemaCostEur: 2200,
          insuranceCostEur: 900,
          marketingCostEur: 2800,
          organizerWorkEur: 2400,
          barriersCostEur: 1200,
          staffingItems: [
            PlanningStaffingItem(
              id: 'venue-large-security-team',
              label: 'Security Team',
              category: PlanningStaffingCategory.security,
              peopleCount: 10,
              hours: 8,
              hourlyRateEur: 45,
            ),
            PlanningStaffingItem(
              id: 'venue-large-security-lead',
              label: 'Security Leitung',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 8,
              hourlyRateEur: 75,
            ),
            PlanningStaffingItem(
              id: 'venue-large-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 4,
              hours: 8,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'venue-large-staff',
              label: 'Eventhelfer / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 5,
              hours: 8,
              hourlyRateEur: 20,
            ),
          ],
          locationNotes:
              'Niedriger Ticketpreis moeglich, aber nur bei wirklich tragfaehiger Nachfrage.',
        ),
      ],
      partners: [
        PlanningPartnerProfile(
          name: 'Media Markt',
          type: PlanningPartnerType.advertisingPartner,
          tier: PartnerTier.gold,
          audienceFocus: '20-35, technikaffin',
          expectedAmountEur: 1200,
          note:
              'Passt gut zu Konzert- und Partyformaten, wenn Reichweite und junges Publikum klar sind.',
        ),
        PlanningPartnerProfile(
          name: 'Lokaler Getraenkepartner',
          type: PlanningPartnerType.eventSponsor,
          tier: PartnerTier.silver,
          audienceFocus: 'Konzert / Party',
          expectedAmountEur: 1500,
          note:
              'Koennte Eventkosten direkt mittragen, wenn Schankrechte oder Sichtbarkeit vereinbart werden.',
        ),
        PlanningPartnerProfile(
          name: 'Foerderkreis Eventhilfe',
          type: PlanningPartnerType.supporter,
          tier: PartnerTier.custom,
          audienceFocus: 'Event findet statt',
          expectedAmountEur: 2500,
          note:
              'Direkte Unterstuetzung, damit der Ticketpreis tragbar bleibt und das Event stattfindet.',
        ),
      ],
      upgradeStages: [
        PlanningUpgradeStage(minimumBudgetEur: 500, label: 'Bessere Lichttechnik'),
        PlanningUpgradeStage(minimumBudgetEur: 1000, label: 'Showeffekte'),
        PlanningUpgradeStage(minimumBudgetEur: 1500, label: 'Freigetraenke-Budget'),
        PlanningUpgradeStage(minimumBudgetEur: 2000, label: 'Anteilige EVC-Erstattung'),
      ],
    ),
    PlanningDraft(
      id: 'nineties-party',
      title: '90er Party',
      category: EventCategory.party,
      targetAudience: '20-35, Party und Nostalgie',
      format: 'Themenparty mit DJ und Deko',
      shortDescription:
          '90er Clubnacht mit guter DJ-Besetzung und optionalen Show-Upgrades.',
      planningStatus: 'Location-Abstimmung',
      minimumCapacity: 300,
      seatingMode: 'Stehend',
      requiresStage: false,
      requiresSound: true,
      requiresLight: true,
      requiresBackstage: false,
      checkMedical: false,
      checkSecurity: true,
      checkToilets: false,
      checkBarriers: false,
      earlyBirdPriceEvc: 14,
      normalPriceEvc: 19,
      presaleVotingPriceEvc: 17,
      expectedEarlyBirdShare: 0.4,
      leakagePercent: 0.05,
      reservePercent: 0.08,
      organizerMarginPercent: 0.05,
      postBreakEvenMarginPercent: 0.12,
      fixedSponsorAmountEur: 500,
      supporterAmountEur: 750,
      grantAmountEur: 0,
      scenarios: [
        PlanningScenario(
          id: 'party-club',
          name: 'Club kompakt',
          locationName: 'Kleine Club-Location',
          setupName: 'Disco stehend',
          capacity: 240,
          targetOccupancyPercent: 0.5,
          baseRentEur: 1200,
          artistCostEur: 1100,
          technologyCostEur: 500,
          securityCostEur: 350,
          medicalCostEur: 0,
          toiletCostEur: 0,
          gemaCostEur: 240,
          insuranceCostEur: 120,
          marketingCostEur: 380,
          organizerWorkEur: 650,
          barriersCostEur: 0,
          staffingItems: [
            PlanningStaffingItem(
              id: 'party-club-security',
              label: 'Security Basis',
              category: PlanningStaffingCategory.security,
              peopleCount: 2,
              hours: 7,
              hourlyRateEur: 25,
            ),
            PlanningStaffingItem(
              id: 'party-club-staff',
              label: 'Eventhelfer / Kasse',
              category: PlanningStaffingCategory.staff,
              peopleCount: 2,
              hours: 7,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Kleiner Club mit engerer Kapazitaet, aber gut fuer sicheren Start.',
        ),
        PlanningScenario(
          id: 'party-mid',
          name: 'Mittelgrosse Party',
          locationName: 'Halle Nord',
          setupName: 'Stehparty',
          capacity: 450,
          targetOccupancyPercent: 0.5,
          baseRentEur: 2400,
          artistCostEur: 1800,
          technologyCostEur: 1200,
          securityCostEur: 900,
          medicalCostEur: 0,
          toiletCostEur: 0,
          gemaCostEur: 480,
          insuranceCostEur: 220,
          marketingCostEur: 650,
          organizerWorkEur: 900,
          barriersCostEur: 250,
          staffingItems: [
            PlanningStaffingItem(
              id: 'party-mid-security-core',
              label: 'Security Standard',
              category: PlanningStaffingCategory.security,
              peopleCount: 4,
              hours: 8,
              hourlyRateEur: 25,
            ),
            PlanningStaffingItem(
              id: 'party-mid-security-lead',
              label: 'Zusatzkraft / Leitung',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 4,
              hourlyRateEur: 25,
              note: 'Kann je nach Auslastung oder Ablauf als Zusatzkraft eingeplant werden.',
            ),
            PlanningStaffingItem(
              id: 'party-mid-staff',
              label: 'Eventhelfer / Kasse',
              category: PlanningStaffingCategory.staff,
              peopleCount: 3,
              hours: 8,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Starkes Partyszenario, braucht aber gute Vorab-Nachfrage fuer tragbare Preise.',
        ),
        PlanningScenario(
          id: 'party-large',
          name: 'Grosse Partyhalle',
          locationName: 'Eissporthalle',
          setupName: 'Sommer-Party stehend',
          capacity: 1200,
          targetOccupancyPercent: 0.5,
          baseRentEur: 5600,
          artistCostEur: 2200,
          technologyCostEur: 2200,
          securityCostEur: 2400,
          medicalCostEur: 650,
          toiletCostEur: 1200,
          gemaCostEur: 1100,
          insuranceCostEur: 380,
          marketingCostEur: 1400,
          organizerWorkEur: 1200,
          barriersCostEur: 900,
          staffingItems: [
            PlanningStaffingItem(
              id: 'party-large-security-team',
              label: 'Security Team',
              category: PlanningStaffingCategory.security,
              peopleCount: 5,
              hours: 8,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'party-large-security-extra',
              label: 'Zusaetzliche Security',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 8,
              hourlyRateEur: 50,
              note: 'Bei sehr starker Nachfrage oder aufwendigem Einlass zuschaltbar.',
              isOptional: true,
              enabledByDefault: false,
            ),
            PlanningStaffingItem(
              id: 'party-large-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 1,
              hours: 5,
              hourlyRateEur: 130,
            ),
            PlanningStaffingItem(
              id: 'party-large-staff',
              label: 'Eventhelfer / Kasse',
              category: PlanningStaffingCategory.staff,
              peopleCount: 5,
              hours: 8,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Niedrigerer noetiger Preis nur dann sinnvoll, wenn die Reichweite wirklich gross ist.',
        ),
      ],
      partners: [
        PlanningPartnerProfile(
          name: 'Media Markt',
          type: PlanningPartnerType.advertisingPartner,
          tier: PartnerTier.silver,
          audienceFocus: '20-35, Party / Technik',
          expectedAmountEur: 800,
          note:
              'Interessant fuer junge Party-Zielgruppe und hohe Sichtbarkeit in Vorab-Kampagnen.',
        ),
        PlanningPartnerProfile(
          name: 'Getraenkemarke',
          type: PlanningPartnerType.eventSponsor,
          tier: PartnerTier.gold,
          audienceFocus: 'Nightlife',
          expectedAmountEur: 1200,
          note:
              'Koennte direkten Zuschuss geben, wenn Markenplatzierung und Eventpraesenz stimmen.',
        ),
        PlanningPartnerProfile(
          name: 'Privater Unterstuetzerpool',
          type: PlanningPartnerType.supporter,
          tier: PartnerTier.custom,
          audienceFocus: 'Event findet statt',
          expectedAmountEur: 750,
          note:
              'Hilft vor allem, damit der Ticketpreis nicht zu stark nach oben muss.',
        ),
      ],
      upgradeStages: [
        PlanningUpgradeStage(minimumBudgetEur: 500, label: 'Bessere Lichttechnik'),
        PlanningUpgradeStage(minimumBudgetEur: 1000, label: 'Showeffekte'),
        PlanningUpgradeStage(minimumBudgetEur: 1500, label: 'Freigetraenke-Budget'),
        PlanningUpgradeStage(minimumBudgetEur: 2000, label: 'Anteilige EVC-Erstattung'),
      ],
    ),
    PlanningDraft(
      id: 'kids-cinema',
      title: 'Kinderkino',
      category: EventCategory.kids,
      targetAudience: 'Familien mit Kindern',
      format: 'Sitzendes Kinoevent am Nachmittag',
      shortDescription:
          'Familienfreundliches Kinoformat mit Snack- und Betreuungsbedarf.',
      planningStatus: 'Anforderungssammlung',
      minimumCapacity: 120,
      seatingMode: 'Sitzend',
      requiresStage: false,
      requiresSound: true,
      requiresLight: false,
      requiresBackstage: false,
      checkMedical: true,
      checkSecurity: false,
      checkToilets: true,
      checkBarriers: false,
      earlyBirdPriceEvc: 9,
      normalPriceEvc: 12,
      presaleVotingPriceEvc: 10,
      expectedEarlyBirdShare: 0.45,
      leakagePercent: 0.03,
      reservePercent: 0.06,
      organizerMarginPercent: 0.04,
      postBreakEvenMarginPercent: 0.08,
      fixedSponsorAmountEur: 700,
      supporterAmountEur: 500,
      grantAmountEur: 400,
      scenarios: [
        PlanningScenario(
          id: 'kids-small',
          name: 'Kleines Kinderkino',
          locationName: 'Seminarturnhalle',
          setupName: 'Filmabend sitzend',
          capacity: 140,
          targetOccupancyPercent: 0.5,
          baseRentEur: 900,
          artistCostEur: 0,
          technologyCostEur: 400,
          securityCostEur: 0,
          medicalCostEur: 250,
          toiletCostEur: 0,
          gemaCostEur: 130,
          insuranceCostEur: 90,
          marketingCostEur: 220,
          organizerWorkEur: 350,
          barriersCostEur: 0,
          staffingItems: [
            PlanningStaffingItem(
              id: 'kids-small-security',
              label: 'Einlass / Aufsicht',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 4,
              hourlyRateEur: 20,
              note: 'Fuer Kinoformate reicht oft 1 Kraft fuer Einlass und Aufsicht.',
            ),
            PlanningStaffingItem(
              id: 'kids-small-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 1,
              hours: 5,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'kids-small-staff',
              label: 'Betreuung / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 2,
              hours: 4,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Familienfreundlich und ueberschaubar, braucht aber sensible Preisgestaltung.',
        ),
        PlanningScenario(
          id: 'kids-medium',
          name: 'Mittelgrosses Kinderkino',
          locationName: 'Seminarturnhalle',
          setupName: 'Filmabend sitzend erweitert',
          capacity: 220,
          targetOccupancyPercent: 0.5,
          baseRentEur: 1200,
          artistCostEur: 0,
          technologyCostEur: 550,
          securityCostEur: 0,
          medicalCostEur: 250,
          toiletCostEur: 0,
          gemaCostEur: 180,
          insuranceCostEur: 110,
          marketingCostEur: 320,
          organizerWorkEur: 500,
          barriersCostEur: 0,
          staffingItems: [
            PlanningStaffingItem(
              id: 'kids-medium-security',
              label: 'Einlass / Aufsicht',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 5,
              hourlyRateEur: 20,
            ),
            PlanningStaffingItem(
              id: 'kids-medium-medical',
              label: 'Sanitaeter',
              category: PlanningStaffingCategory.medical,
              peopleCount: 1,
              hours: 5,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'kids-medium-staff',
              label: 'Betreuung / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 3,
              hours: 5,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Mehr Plaetze, aber nur sinnvoll, wenn Familiennachfrage frueh erkennbar ist.',
        ),
      ],
      partners: [
        PlanningPartnerProfile(
          name: 'McDonalds',
          type: PlanningPartnerType.advertisingPartner,
          tier: PartnerTier.gold,
          audienceFocus: 'Kids / Familien',
          expectedAmountEur: 900,
          note:
              'Werbung vor allem bei Kids-Events sinnvoll. Koennte Familienreichweite und Zuschuss bringen.',
        ),
        PlanningPartnerProfile(
          name: 'Lokaler Familienpartner',
          type: PlanningPartnerType.eventSponsor,
          tier: PartnerTier.silver,
          audienceFocus: 'Familien und Kinder',
          expectedAmountEur: 700,
          note:
              'Hilft, den Ticketpreis familienfreundlich zu halten und Betreuung mitzutragen.',
        ),
        PlanningPartnerProfile(
          name: 'Foerdertopf Familienevent',
          type: PlanningPartnerType.supporter,
          tier: PartnerTier.custom,
          audienceFocus: 'Event soll stattfinden',
          expectedAmountEur: 500,
          note:
              'Direkter Zuschuss, damit auch bei kleinerem Ticketpreis der Break-even naeher rueckt.',
        ),
      ],
      upgradeStages: [
        PlanningUpgradeStage(minimumBudgetEur: 500, label: 'Bessere Kinderdeko'),
        PlanningUpgradeStage(minimumBudgetEur: 1000, label: 'Zusatzprogramm vor dem Film'),
        PlanningUpgradeStage(minimumBudgetEur: 1500, label: 'Snack-Gutschein-Budget'),
        PlanningUpgradeStage(minimumBudgetEur: 2000, label: 'Anteilige EVC-Erstattung'),
      ],
    ),
    PlanningDraft(
      id: 'acoustic-session',
      title: 'Acoustic Session Planung',
      category: EventCategory.concert,
      targetAudience: 'Kleines Kultur- und Konzertpublikum',
      format: 'Bestuhltes Akustik-Konzert',
      shortDescription:
          'Intime Konzertreihe mit geringerer Kapazitaet und hohem Atmosphaere-Fokus.',
      planningStatus: 'Vorkalkulation laeuft',
      minimumCapacity: 140,
      seatingMode: 'Sitzend',
      requiresStage: true,
      requiresSound: true,
      requiresLight: true,
      requiresBackstage: true,
      checkMedical: false,
      checkSecurity: false,
      checkToilets: false,
      checkBarriers: false,
      earlyBirdPriceEvc: 19,
      normalPriceEvc: 24,
      presaleVotingPriceEvc: 22,
      expectedEarlyBirdShare: 0.4,
      leakagePercent: 0.03,
      reservePercent: 0.07,
      organizerMarginPercent: 0.05,
      postBreakEvenMarginPercent: 0.1,
      fixedSponsorAmountEur: 600,
      supporterAmountEur: 400,
      grantAmountEur: 0,
      scenarios: [
        PlanningScenario(
          id: 'acoustic-small',
          name: 'Kleines Clubkonzert',
          locationName: 'Kleine Club-Location',
          setupName: 'Konzert bestuhlt',
          capacity: 180,
          targetOccupancyPercent: 0.5,
          baseRentEur: 1600,
          artistCostEur: 2200,
          technologyCostEur: 800,
          securityCostEur: 200,
          medicalCostEur: 0,
          toiletCostEur: 0,
          gemaCostEur: 260,
          insuranceCostEur: 140,
          marketingCostEur: 380,
          organizerWorkEur: 650,
          barriersCostEur: 0,
          staffingItems: [
            PlanningStaffingItem(
              id: 'acoustic-small-security',
              label: 'Security / Einlass',
              category: PlanningStaffingCategory.security,
              peopleCount: 1,
              hours: 4,
              hourlyRateEur: 50,
            ),
            PlanningStaffingItem(
              id: 'acoustic-small-staff',
              label: 'Eventhelfer / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 2,
              hours: 5,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Intime Atmosphaere, aber wenig Puffer bei schwacher Auslastung.',
        ),
        PlanningScenario(
          id: 'acoustic-medium',
          name: 'Akustik im Saal',
          locationName: 'Metropol',
          setupName: 'Konzert bestuhlt',
          capacity: 420,
          targetOccupancyPercent: 0.5,
          baseRentEur: 4000,
          artistCostEur: 2200,
          technologyCostEur: 1400,
          securityCostEur: 600,
          medicalCostEur: 0,
          toiletCostEur: 0,
          gemaCostEur: 420,
          insuranceCostEur: 220,
          marketingCostEur: 700,
          organizerWorkEur: 900,
          barriersCostEur: 0,
          staffingItems: [
            PlanningStaffingItem(
              id: 'acoustic-medium-security',
              label: 'Security Standard',
              category: PlanningStaffingCategory.security,
              peopleCount: 3,
              hours: 5,
              hourlyRateEur: 40,
            ),
            PlanningStaffingItem(
              id: 'acoustic-medium-staff',
              label: 'Eventhelfer / Orga',
              category: PlanningStaffingCategory.staff,
              peopleCount: 3,
              hours: 6,
              hourlyRateEur: 18,
            ),
          ],
          locationNotes:
              'Groesserer Saal, aber nur sinnvoll, wenn das Format genug Nachfrage entwickelt.',
        ),
      ],
      partners: [
        PlanningPartnerProfile(
          name: 'Lokaler Kulturpartner',
          type: PlanningPartnerType.advertisingPartner,
          tier: PartnerTier.silver,
          audienceFocus: 'Kultur, Konzertpublikum',
          expectedAmountEur: 500,
          note:
              'Hilft bei lokaler Sichtbarkeit, besonders wenn das Event kulturell positioniert wird.',
        ),
        PlanningPartnerProfile(
          name: 'Akustik-Markenpartner',
          type: PlanningPartnerType.eventSponsor,
          tier: PartnerTier.gold,
          audienceFocus: 'Musik / Konzert',
          expectedAmountEur: 600,
          note:
              'Koennte Technik oder Direktzuschuss liefern, wenn klare Markennaehe vorhanden ist.',
        ),
        PlanningPartnerProfile(
          name: 'Kleine Unterstuetzergruppe',
          type: PlanningPartnerType.supporter,
          tier: PartnerTier.custom,
          audienceFocus: 'Event soll stattfinden',
          expectedAmountEur: 400,
          note:
              'Kleine Eventhilfe, um das Konzert auch bei begrenzter Kapazitaet darstellbar zu machen.',
        ),
      ],
      upgradeStages: [
        PlanningUpgradeStage(minimumBudgetEur: 500, label: 'Bessere Lichttechnik'),
        PlanningUpgradeStage(minimumBudgetEur: 1000, label: 'Support-Act mit einplanen'),
        PlanningUpgradeStage(minimumBudgetEur: 1500, label: 'Getraenkegutschein-Budget'),
        PlanningUpgradeStage(minimumBudgetEur: 2000, label: 'Anteilige EVC-Erstattung'),
      ],
    ),
  ];
}

class PlanningScenario {
  final String id;
  final String name;
  final String locationName;
  final String setupName;
  final int capacity;
  final double targetOccupancyPercent;
  final double baseRentEur;
  final double artistCostEur;
  final double technologyCostEur;
  final double securityCostEur;
  final double medicalCostEur;
  final double toiletCostEur;
  final double gemaCostEur;
  final double insuranceCostEur;
  final double marketingCostEur;
  final double organizerWorkEur;
  final double barriersCostEur;
  final String locationNotes;
  final List<PlanningStaffingItem> staffingItems;

  const PlanningScenario({
    required this.id,
    required this.name,
    required this.locationName,
    required this.setupName,
    required this.capacity,
    required this.targetOccupancyPercent,
    required this.baseRentEur,
    required this.artistCostEur,
    required this.technologyCostEur,
    required this.securityCostEur,
    required this.medicalCostEur,
    required this.toiletCostEur,
    required this.gemaCostEur,
    required this.insuranceCostEur,
    required this.marketingCostEur,
    required this.organizerWorkEur,
    required this.barriersCostEur,
    required this.locationNotes,
    this.staffingItems = const [],
  });
}

class PlanningStaffingItem {
  final String id;
  final String label;
  final PlanningStaffingCategory category;
  final int peopleCount;
  final double hours;
  final double hourlyRateEur;
  final String note;
  final bool isOptional;
  final bool enabledByDefault;

  const PlanningStaffingItem({
    required this.id,
    required this.label,
    required this.category,
    required this.peopleCount,
    required this.hours,
    required this.hourlyRateEur,
    this.note = '',
    this.isOptional = false,
    this.enabledByDefault = true,
  });

  double get totalCostEur => peopleCount * hours * hourlyRateEur;

  String get hoursText {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}';
    }
    return hours.toStringAsFixed(1);
  }
}

class PlanningPartnerProfile {
  final String name;
  final PlanningPartnerType type;
  final PartnerTier tier;
  final String audienceFocus;
  final double expectedAmountEur;
  final String note;

  const PlanningPartnerProfile({
    required this.name,
    required this.type,
    required this.tier,
    required this.audienceFocus,
    required this.expectedAmountEur,
    required this.note,
  });
}

class PlanningUpgradeStage {
  final double minimumBudgetEur;
  final String label;

  const PlanningUpgradeStage({
    required this.minimumBudgetEur,
    required this.label,
  });
}
