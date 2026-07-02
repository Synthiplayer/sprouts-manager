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

part 'widgets/planning_costs_tab.dart';
part 'widgets/planning_event_details_tab.dart';
part 'widgets/planning_main_tab.dart';
part 'widgets/planning_configuration_building_blocks.dart';
part 'widgets/planning_building_blocks_widgets.dart';
part 'widgets/planning_scenarios_tab.dart';
part 'widgets/planning_tickets_tab.dart';
part 'widgets/planning_sponsoring_tab.dart';
part 'widgets/planning_break_even_tab.dart';
part 'widgets/planning_shared_widgets.dart';
part 'widgets/planning_overview_widgets.dart';
part 'logic/planning_persistence.dart';
part 'logic/planning_calculation_logic.dart';

enum PlanningWorkspaceTab {
  eventDetails,
  main,
  configuration,
  scenarios,
  costs,
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
  static const List<String> _planningStatusOptions = [
    'Idee',
    'Early-Bird Phase',
    'Bestätigung läuft',
    'Bestätigt',
    'Abgesagt',
  ];
  static const List<int> _minimumAgeOptions = [0, 6, 12, 14, 16, 18];

  final List<PlanningDraft> _drafts = List<PlanningDraft>.from(
    planningSandboxDrafts,
  );
  final Map<String, double> _scenarioOccupancyOverrides = {};
  final Map<String, double> _scenarioVariableCostOverrides = {};
  final Map<String, int> _scenarioVariableCostThresholdOverrides = {};
  final Map<String, double> _normalPriceMarkupOverrides = {};
  final Map<String, double> _leakagePercentOverrides = {};
  final Map<String, double> _reservePercentOverrides = {};
  final Map<String, double> _organizerSharePercentOverrides = {};
  final Map<String, double> _partnerSharePercentOverrides = {};
  final Map<String, List<PlanningFundingItem>> _fundingItemOverrides = {};
  final Map<String, String> _selectedScenarioOverrides = {};
  final Map<String, EventCategory> _draftCategoryOverrides = {};
  final Map<String, String> _draftTitleOverrides = {};
  final Map<String, String> _draftPlanningStatusOverrides = {};
  final Map<String, String> _draftFormatOverrides = {};
  final Map<String, String> _draftShortDescriptionOverrides = {};
  final Map<String, String> _draftEventDateOverrides = {};
  final Map<String, String> _draftStartTimeOverrides = {};
  final Map<String, String> _draftEndTimeOverrides = {};
  final Map<String, String> _draftRegistrationDeadlineOverrides = {};
  final Map<String, int> _draftMinimumAgeOverrides = {};
  final Map<String, String> _locationBlockIdOverrides = {};
  final Map<String, Set<String>> _locationAreaSelectionOverrides = {};
  final Map<String, double> _costPositionAmountOverrides = {};
  final Map<String, String> _costPositionLabelOverrides = {};
  final Map<String, int> _staffPeopleCountOverrides = {};
  final Map<String, double> _staffHoursOverrides = {};
  final Map<String, double> _staffHourlyRateOverrides = {};
  final Map<String, int> _selectedMainCostRowIndexes = {};
  final Map<String, List<PlanningProgramCostItem>> _programCostItemOverrides =
      {};
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

  List<PlanningFundingItem> _fundingItemsForDraft(PlanningDraft draft) {
    return _fundingItemOverrides[draft.id] ?? draft.fundingItems;
  }

  List<(String, String)> _fundingDisplayRows(PlanningDraft draft) {
    return [
      for (final item in _fundingItemsForDraft(draft))
        (
          item.name.trim().isEmpty
              ? _fundingTypeAndLevelLabel(item)
              : '${item.name.trim()} (${_fundingTypeAndLevelLabel(item)})',
          formatEuro(item.amountEur),
        ),
    ];
  }

  String _fundingTypeAndLevelLabel(PlanningFundingItem item) {
    if (item.level == PlanningSponsorshipLevel.none) {
      return item.type.label;
    }
    return '${item.type.label} · ${item.level.label}';
  }

  void _upsertFundingItem(PlanningDraft draft, PlanningFundingItem item) {
    final items = [..._fundingItemsForDraft(draft)];
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    _fundingItemOverrides[draft.id] = items;
  }

  void _removeFundingItem(PlanningDraft draft, String itemId) {
    _fundingItemOverrides[draft.id] = [
      for (final item in _fundingItemsForDraft(draft))
        if (item.id != itemId) item,
    ];
  }

  EventCategory _planningCategory(PlanningDraft draft) {
    return _draftCategoryOverrides[draft.id] ?? draft.category;
  }

  String _draftTitle(PlanningDraft draft) {
    return _draftTextValue(_draftTitleOverrides, draft.id, draft.title);
  }

  String _draftPlanningStatus(PlanningDraft draft) {
    final status = _draftTextValue(
      _draftPlanningStatusOverrides,
      draft.id,
      draft.planningStatus,
    );
    if (_planningStatusOptions.contains(status)) {
      return status;
    }
    return _planningStatusOptions.first;
  }

  String _draftFormat(PlanningDraft draft) {
    return _draftTextValue(_draftFormatOverrides, draft.id, draft.format);
  }

  String _draftShortDescription(PlanningDraft draft) {
    return _draftTextValue(
      _draftShortDescriptionOverrides,
      draft.id,
      draft.shortDescription,
    );
  }

  String _draftEventDate(PlanningDraft draft) {
    return _draftOptionalTextValue(
      _draftEventDateOverrides,
      draft.id,
      draft.eventDate,
    );
  }

  String _draftStartTime(PlanningDraft draft) {
    return _draftOptionalTextValue(
      _draftStartTimeOverrides,
      draft.id,
      draft.startTime,
    );
  }

  String _draftEndTime(PlanningDraft draft) {
    return _draftOptionalTextValue(
      _draftEndTimeOverrides,
      draft.id,
      draft.endTime,
    );
  }

  String _draftRegistrationDeadline(PlanningDraft draft) {
    return _draftOptionalTextValue(
      _draftRegistrationDeadlineOverrides,
      draft.id,
      draft.registrationDeadline,
    );
  }

  String _draftEventTimeText(PlanningDraft draft) {
    final startTime = _draftStartTime(draft);
    final endTime = _draftEndTime(draft);
    if (startTime.isEmpty && endTime.isEmpty) {
      return 'Noch offen';
    }
    if (endTime.isEmpty) {
      return 'ab $startTime';
    }
    if (startTime.isEmpty) {
      return 'bis $endTime';
    }
    return '$startTime - $endTime';
  }

  String _draftEventScheduleText(PlanningDraft draft) {
    final date = _draftEventDate(draft);
    final time = _draftEventTimeText(draft);
    final registrationDeadline = _draftRegistrationDeadline(draft);
    String schedule;
    if (date.isEmpty && time == 'Noch offen') {
      schedule = 'Termin offen';
    } else if (date.isEmpty) {
      schedule = time;
    } else if (time == 'Noch offen') {
      schedule = date;
    } else {
      schedule = '$date, $time';
    }
    if (registrationDeadline.isEmpty) {
      return schedule;
    }
    return '$schedule | Anmeldung bis $registrationDeadline';
  }

  int _draftMinimumAge(PlanningDraft draft) {
    final age = _draftMinimumAgeOverrides[draft.id];
    if (age != null && _minimumAgeOptions.contains(age)) {
      return age;
    }
    return 18;
  }

  String _draftTextValue(
    Map<String, String> overrides,
    String draftId,
    String fallback,
  ) {
    final value = overrides[draftId]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  String _draftOptionalTextValue(
    Map<String, String> overrides,
    String draftId,
    String fallback,
  ) {
    if (!overrides.containsKey(draftId)) {
      return fallback;
    }
    return overrides[draftId]?.trim() ?? '';
  }

  String _planningLocationName(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _planningLocationBlock(draft, scenario)?.name ??
        scenario.locationName;
  }

  BuildingBlock? _planningLocationBlock(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final blockId = _planningLocationBlockId(draft, scenario);
    if (blockId.isEmpty) {
      return null;
    }
    for (final block in buildingBlockCatalogStore.value) {
      if (block.category == BuildingBlockCategory.location &&
          block.id == blockId) {
        return block;
      }
    }
    return null;
  }

  String _planningLocationBlockId(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final overrideId = _locationBlockIdOverrides[draft.id];
    if (overrideId != null && overrideId.isNotEmpty) {
      return overrideId;
    }
    return scenario.locationBlockId;
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
                onPressed: null,
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
        final cardScenario =
            isSelected ? _selectedScenario(draft) : _recommendedScenario(draft);
        final scenarioLabel =
            isSelected ? 'Aktuelles Szenario' : 'Guenstigstes Szenario';

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
                        _pill(context, _draftPlanningStatus(draft)),
                        _pill(context, _mainDecisionStatus(draft)),
                        if (isSelected) _pill(context, 'Aktive Planung'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _draftTitle(draft),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _draftShortDescription(draft),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _draftEventScheduleText(draft),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$scenarioLabel: ${cardScenario.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Kapazitaet: ${cardScenario.capacity} | Zielauslastung: ${(_scenarioOccupancy(cardScenario) * 100).round()} %',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Noetiger Early-Bird-Preis: ${formatEuro(_requiredEarlyBirdPriceAtTargetOccupancy(draft, cardScenario))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Normalpreis danach: ${_normalPriceEurForScenario(draft, cardScenario).round()} EVC / ${formatEuro(_normalPriceEurForScenario(draft, cardScenario))}',
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
            _draftTitle(draft),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _planningCategory(draft).toChip(),
              _pill(context, _draftPlanningStatus(draft)),
              _pill(context, _mainDecisionStatus(draft)),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<PlanningWorkspaceTab>(
            segments: const [
              ButtonSegment(
                value: PlanningWorkspaceTab.eventDetails,
                label: Text('Eventdaten'),
              ),
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
          const SizedBox(height: 16),
          switch (_tab) {
            PlanningWorkspaceTab.eventDetails =>
              _buildEventDetailsTab(context, draft),
            PlanningWorkspaceTab.main => _buildMainTab(context, draft),
            PlanningWorkspaceTab.configuration =>
              _buildConfigurationTab(context, draft),
            PlanningWorkspaceTab.scenarios => _buildScenariosTab(context, draft),
            PlanningWorkspaceTab.costs => PlanningCostsTab(
                draft: draft,
                scenario: _selectedScenario(draft),
                draftTitle: _draftTitle(draft),
                items: _costOverviewItemsForScenario(
                  draft,
                  _selectedScenario(draft),
                ),
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

