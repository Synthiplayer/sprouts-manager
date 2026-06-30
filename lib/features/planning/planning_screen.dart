import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/features/building_blocks/domain/building_block_catalog.dart';
import 'package:sprouts_manager/features/planning/data/planning_sandbox_drafts.dart';
import 'package:sprouts_manager/features/planning/domain/planning_models.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';

part 'widgets/planning_artists_tab.dart';
part 'widgets/planning_technology_tab.dart';
part 'widgets/planning_costs_tab.dart';
part 'widgets/planning_main_tab.dart';
part 'widgets/planning_scenarios_tab.dart';
part 'widgets/planning_tickets_tab.dart';
part 'widgets/planning_sponsoring_tab.dart';
part 'widgets/planning_break_even_tab.dart';
part 'widgets/planning_shared_widgets.dart';
part 'widgets/planning_overview_widgets.dart';
part 'logic/planning_persistence.dart';
part 'logic/planning_calculation_logic.dart';

enum PlanningWorkspaceTab {
  main,
  configuration,
  scenarios,
  costs,
  artists,
  technology,
  tickets,
  sponsoring,
  breakEven,
}

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  static const String _sandboxFileName = 'planning_sandbox_state.json';

  final List<PlanningDraft> _drafts = planningSandboxDrafts;
  final Map<String, Map<PlanningScenarioOption, bool>> _draftOptionOverrides = {};
  final Map<String, double> _scenarioOccupancyOverrides = {};
  final Map<String, bool> _staffingItemOverrides = {};
  final Map<String, int> _staffingPeopleOverrides = {};
  final Map<String, double> _staffingHoursOverrides = {};
  final Map<String, double> _staffingRateOverrides = {};
  final Map<String, double> _scenarioVariableCostOverrides = {};
  final Map<String, int> _scenarioVariableCostThresholdOverrides = {};
  final Map<String, double> _normalPriceMarkupOverrides = {};
  final Map<String, double> _leakagePercentOverrides = {};
  final Map<String, double> _reservePercentOverrides = {};
  final Map<String, double> _organizerSharePercentOverrides = {};
  final Map<String, double> _partnerSharePercentOverrides = {};
  final Map<String, String> _selectedScenarioOverrides = {};
  final Map<String, EventCategory> _draftCategoryOverrides = {};
  final Map<String, String> _locationNameOverrides = {};
  final Map<String, Set<String>> _locationAreaSelectionOverrides = {};
  final Map<String, double> _costPositionAmountOverrides = {};
  final Map<String, String> _costPositionLabelOverrides = {};
  final Map<String, int> _selectedMainCostRowIndexes = {};
  final Map<String, List<PlanningArtistCostItem>> _artistCostItemOverrides = {};
  final Map<String, List<PlanningTechnologyCostItem>>
      _technologyCostItemOverrides = {};
  String? _selectedDraftId;
  PlanningWorkspaceTab _tab = PlanningWorkspaceTab.main;
  bool _isLoadingSandboxState = true;

  @override
  void initState() {
    super.initState();
    if (_drafts.isNotEmpty) {
      _selectedDraftId = _drafts.first.id;
    }
    buildingBlockCatalogStore.load();
    _loadPlanningSandboxState();
  }

  void _refreshPlanningUi([VoidCallback? update]) {
    if (!mounted) {
      return;
    }
    setState(() {
      update?.call();
    });
  }

  EventCategory _planningCategory(PlanningDraft draft) {
    return _draftCategoryOverrides[draft.id] ?? draft.category;
  }

  String _planningLocationName(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final locationOverride = _locationNameOverrides[draft.id];
    if (locationOverride == null || locationOverride == 'Location / Halle') {
      return scenario.locationName;
    }
    return locationOverride;
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
              FilledButton.icon(
                onPressed: () => _showPlaceholderDialog(
                  context,
                  title: 'Neue Planung',
                  message:
                      'Als naechstes oeffnet dieser Button die Template-Auswahl mit Kacheln und der Option komplett frei zu planen.',
                ),
                icon: const Icon(Icons.add),
                label: const Text('Neue Planung'),
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
                      color: _planningCategory(draft).color.withValues(alpha: 0.18),
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
                color: isSelected ? _planningCategory(draft).color : Colors.transparent,
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
                _savePlanningSandboxState();
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
                        _planningCategory(draft).toChip(),
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
                      'Bester Preis: ${recommendedScenario.name}',
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
                      'Normalpreis danach: ${_normalPriceEurForScenario(draft, recommendedScenario).round()} EVC / ${formatEuro(_normalPriceEurForScenario(draft, recommendedScenario))}',
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
              _planningCategory(draft).toChip(),
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
                value: PlanningWorkspaceTab.configuration,
                label: Text('Konfiguration'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.scenarios,
                label: Text('Szenarien'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.costs,
                label: Text('Kosten'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.artists,
                label: Text('Programm'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.technology,
                label: Text('Technik'),
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
            PlanningWorkspaceTab.configuration =>
              _buildConfigurationTab(context, draft),
            PlanningWorkspaceTab.scenarios => _buildScenariosTab(context, draft),
            PlanningWorkspaceTab.costs => PlanningCostsTab(
                draft: draft,
                scenario: _selectedScenario(draft),
                items: _costOverviewItemsForScenario(
                  draft,
                  _selectedScenario(draft),
                ),
              ),
            PlanningWorkspaceTab.artists => PlanningArtistsTab(
                draft: draft,
                scenario: _selectedScenario(draft),
                items: _artistCostItemsForDraft(draft),
                onItemsChanged: (items) {
                  setState(() {
                    _artistCostItemOverrides[draft.id] = items;
                  });
                  _savePlanningSandboxState();
                },
              ),
            PlanningWorkspaceTab.technology => PlanningTechnologyTab(
                draft: draft,
                scenario: _selectedScenario(draft),
                items: _technologyCostItemsForDraft(draft),
                onItemsChanged: (items) {
                  setState(() {
                    _technologyCostItemOverrides[draft.id] = items;
                  });
                  _savePlanningSandboxState();
                },
              ),
            PlanningWorkspaceTab.tickets => _buildTicketsTab(context, draft),
            PlanningWorkspaceTab.sponsoring => _buildSponsoringTab(context, draft),
            PlanningWorkspaceTab.breakEven => _buildBreakEvenTab(context, draft),
          },
        ],
      ),
    );
  }


}

