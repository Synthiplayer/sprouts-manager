import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/event_currency_config.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';

part 'widgets/planning_artists_tab.dart';
part 'widgets/planning_costs_tab.dart';

enum PlanningWorkspaceTab {
  main,
  scenarios,
  costs,
  artists,
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
  static const String _sandboxFileName = 'planning_sandbox_state.json';

  final List<PlanningDraft> _drafts = PlanningDraft.sandboxDrafts;
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
  final Map<String, List<PlanningArtistCostItem>> _artistCostItemOverrides = {};
  String? _selectedDraftId;
  PlanningWorkspaceTab _tab = PlanningWorkspaceTab.main;
  bool _isLoadingSandboxState = true;

  @override
  void initState() {
    super.initState();
    if (_drafts.isNotEmpty) {
      _selectedDraftId = _drafts.first.id;
    }
    _loadPlanningSandboxState();
  }

  Future<File> _planningSandboxFile() async {
    final directory = _planningSandboxDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$_sandboxFileName');
  }

  Directory _planningSandboxDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData${Platform.pathSeparator}SproutsManager');
      }
    }

    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home${Platform.pathSeparator}.sprouts_manager');
    }

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}sprouts_manager',
    );
  }

  Future<void> _loadPlanningSandboxState() async {
    try {
      final file = await _planningSandboxFile();
      if (!file.existsSync()) {
        if (mounted) {
          setState(() {
            _isLoadingSandboxState = false;
          });
        }
        return;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _isLoadingSandboxState = false;
          });
        }
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _restorePlanningSandboxState(decoded);
        _isLoadingSandboxState = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSandboxState = false;
        });
      }
    }
  }

  Future<void> _savePlanningSandboxState() async {
    if (_isLoadingSandboxState) {
      return;
    }

    try {
      final file = await _planningSandboxFile();
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_planningSandboxStateJson()),
      );
    } catch (_) {
      // Sandbox persistence must never block planning UI work.
    }
  }

  Map<String, dynamic> _planningSandboxStateJson() {
    return {
      'selectedDraftId': _selectedDraftId,
      'selectedScenarioOverrides': _selectedScenarioOverrides,
      'scenarioOccupancyOverrides': _scenarioOccupancyOverrides,
      'scenarioVariableCostOverrides': _scenarioVariableCostOverrides,
      'scenarioVariableCostThresholdOverrides':
          _scenarioVariableCostThresholdOverrides,
      'staffingItemOverrides': _staffingItemOverrides,
      'staffingPeopleOverrides': _staffingPeopleOverrides,
      'staffingHoursOverrides': _staffingHoursOverrides,
      'staffingRateOverrides': _staffingRateOverrides,
      'normalPriceMarkupOverrides': _normalPriceMarkupOverrides,
      'leakagePercentOverrides': _leakagePercentOverrides,
      'reservePercentOverrides': _reservePercentOverrides,
      'organizerSharePercentOverrides': _organizerSharePercentOverrides,
      'partnerSharePercentOverrides': _partnerSharePercentOverrides,
      'draftOptionOverrides': _draftOptionOverrides.map(
        (draftId, options) => MapEntry(
          draftId,
          options.map((option, value) => MapEntry(option.name, value)),
        ),
      ),
      'artistCostItemOverrides': _artistCostItemOverrides.map(
        (draftId, items) => MapEntry(
          draftId,
          items.map((item) => item.toJson()).toList(),
        ),
      ),
    };
  }

  void _restorePlanningSandboxState(Map<String, dynamic> json) {
    final selectedDraftId = json['selectedDraftId'];
    if (selectedDraftId is String &&
        _drafts.any((draft) => draft.id == selectedDraftId)) {
      _selectedDraftId = selectedDraftId;
    }

    _selectedScenarioOverrides
      ..clear()
      ..addAll(_stringMap(json['selectedScenarioOverrides']));
    _scenarioOccupancyOverrides
      ..clear()
      ..addAll(_doubleMap(json['scenarioOccupancyOverrides']));
    _scenarioVariableCostOverrides
      ..clear()
      ..addAll(_doubleMap(json['scenarioVariableCostOverrides']));
    _scenarioVariableCostThresholdOverrides
      ..clear()
      ..addAll(_intMap(json['scenarioVariableCostThresholdOverrides']));
    _staffingItemOverrides
      ..clear()
      ..addAll(_boolMap(json['staffingItemOverrides']));
    _staffingPeopleOverrides
      ..clear()
      ..addAll(_intMap(json['staffingPeopleOverrides']));
    _staffingHoursOverrides
      ..clear()
      ..addAll(_doubleMap(json['staffingHoursOverrides']));
    _staffingRateOverrides
      ..clear()
      ..addAll(_doubleMap(json['staffingRateOverrides']));
    _normalPriceMarkupOverrides
      ..clear()
      ..addAll(_doubleMap(json['normalPriceMarkupOverrides']));
    _leakagePercentOverrides
      ..clear()
      ..addAll(_doubleMap(json['leakagePercentOverrides']));
    _reservePercentOverrides
      ..clear()
      ..addAll(_doubleMap(json['reservePercentOverrides']));
    _organizerSharePercentOverrides
      ..clear()
      ..addAll(_doubleMap(json['organizerSharePercentOverrides']));
    _partnerSharePercentOverrides
      ..clear()
      ..addAll(_doubleMap(json['partnerSharePercentOverrides']));

    _draftOptionOverrides
      ..clear()
      ..addAll(_draftOptionMap(json['draftOptionOverrides']));
    _artistCostItemOverrides
      ..clear()
      ..addAll(_artistCostItemMap(json['artistCostItemOverrides']));
  }

  Map<String, String> _stringMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry.toString()),
    );
  }

  Map<String, double> _doubleMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map((key, entry) {
      final parsed = entry is num ? entry.toDouble() : double.tryParse('$entry');
      return MapEntry(key.toString(), parsed ?? 0);
    });
  }

  Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map((key, entry) {
      final parsed = entry is num ? entry.toInt() : int.tryParse('$entry');
      return MapEntry(key.toString(), parsed ?? 0);
    });
  }

  Map<String, bool> _boolMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map((key, entry) => MapEntry(key.toString(), entry == true));
  }

  Map<String, Map<PlanningScenarioOption, bool>> _draftOptionMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    final result = <String, Map<PlanningScenarioOption, bool>>{};
    for (final draftEntry in value.entries) {
      final options = draftEntry.value;
      if (options is! Map) {
        continue;
      }
      final restoredOptions = <PlanningScenarioOption, bool>{};
      for (final optionEntry in options.entries) {
        final option = _planningScenarioOptionByName(optionEntry.key.toString());
        if (option == null) {
          continue;
        }
        restoredOptions[option] = optionEntry.value == true;
      }
      result[draftEntry.key.toString()] = restoredOptions;
    }
    return result;
  }

  PlanningScenarioOption? _planningScenarioOptionByName(String name) {
    for (final option in PlanningScenarioOption.values) {
      if (option.name == name) {
        return option;
      }
    }
    return null;
  }

  Map<String, List<PlanningArtistCostItem>> _artistCostItemMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    final result = <String, List<PlanningArtistCostItem>>{};
    for (final draftEntry in value.entries) {
      final items = draftEntry.value;
      if (items is! List) {
        continue;
      }
      result[draftEntry.key.toString()] = [
        for (final item in items)
          if (item is Map)
            PlanningArtistCostItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
      ];
    }
    return result;
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
                value: PlanningWorkspaceTab.costs,
                label: Text('Kosten'),
              ),
              ButtonSegment(
                value: PlanningWorkspaceTab.artists,
                label: Text('Kuenstler'),
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
            PlanningWorkspaceTab.tickets => _buildTicketsTab(context, draft),
            PlanningWorkspaceTab.sponsoring => _buildSponsoringTab(context, draft),
            PlanningWorkspaceTab.breakEven => _buildBreakEvenTab(context, draft),
          },
        ],
      ),
    );
  }

  Widget _buildMainTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final visibleStaffingItems = _visibleStaffingItems(draft, scenario);
    final earlyBirdPrice = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);

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
              _valueRow('Ausgewaehltes Szenario', '${scenario.name} - ${scenario.locationName}'),
              _valueRow(
                'Noetiger Early-Bird-Preis bei Zielauslastung',
                formatEuro(earlyBirdPrice),
              ),
              _valueRow(
                'Zielteilnehmer fuer Break-even',
                '${_scenarioTargetAttendees(scenario)}',
              ),
              _valueRow(
                'Normalpreis nach Break-even',
                '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
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
          title: 'Main / Kalkulationsabschluss',
          child: _buildCalculationMainOverview(
            context,
            draft,
            scenario,
            earlyBirdPrice: earlyBirdPrice,
            normalPrice: normalPrice,
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

  Widget _buildScenarioComparison(BuildContext context, PlanningDraft draft) {
    final selectedScenario = _selectedScenario(draft);

    return _scenarioComparisonContent(context, draft, selectedScenario);
  }

  Widget _scenarioComparisonContent(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario selectedScenario,
  ) {
    final headerStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('Szenario', style: headerStyle)),
              Expanded(child: Text('Kapazitaet', style: headerStyle)),
              Expanded(child: Text('Auslastung', style: headerStyle)),
              Expanded(child: Text('Besucher', style: headerStyle)),
              Expanded(child: Text('Early-Bird', style: headerStyle)),
              Expanded(child: Text('Var. Kosten', style: headerStyle)),
              Expanded(child: Text('Status', style: headerStyle)),
              const SizedBox(width: 112),
            ],
          ),
        ),
        ...draft.scenarios.map((scenario) {
          final isSelected = scenario.id == selectedScenario.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _selectedScenarioOverrides[draft.id] = scenario.id;
                });
                _savePlanningSandboxState();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? draft.category.color.withValues(alpha: 0.08)
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? draft.category.color
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        scenario.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text('${scenario.capacity}')),
                    Expanded(
                      child: Text(
                        '${(_scenarioOccupancy(scenario) * 100).round()} %',
                      ),
                    ),
                    Expanded(
                      child: Text('${_scenarioTargetAttendees(scenario)}'),
                    ),
                    Expanded(
                      child: Text(
                        formatEuro(
                          _requiredEarlyBirdPriceAtTargetOccupancy(
                            draft,
                            scenario,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatEuro(_scenarioVariableCostsEur(draft, scenario)),
                      ),
                    ),
                    Expanded(child: Text(_scenarioPriceLabel(draft, scenario))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 104,
                      child: OutlinedButton(
                        onPressed: isSelected
                            ? null
                            : () {
                              setState(() {
                                _selectedScenarioOverrides[draft.id] =
                                    scenario.id;
                              });
                              _savePlanningSandboxState();
                            },
                        child: Text(isSelected ? 'Aktiv' : 'Waehlen'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCalculationMainOverview(
    BuildContext context,
    PlanningDraft draft,
    PlanningScenario scenario, {
    required double earlyBirdPrice,
    required double normalPrice,
  }) {
    final attendees = _scenarioTargetAttendees(scenario);
    final fixedEventCosts = _scenarioBaseCostsEur(draft, scenario);
    final variableEventCosts = _scenarioVariableCostsEur(draft, scenario);
    final totalEventCosts = _scenarioEventCostsEur(draft, scenario);
    final grossTicketsBeforeEvent = attendees * earlyBirdPrice;
    final totalIncomeBeforeEvent =
        grossTicketsBeforeEvent + draft.totalSupportEur;
    final organizerSharePercent = _organizerSharePercent(draft);
    final partnerSharePercent = _partnerSharePercent(draft);
    final totalSharePercent = organizerSharePercent + partnerSharePercent;
    final organizerShareAmount = totalIncomeBeforeEvent * organizerSharePercent;
    final partnerShareAmount = totalIncomeBeforeEvent * partnerSharePercent;
    final totalShareAmount = organizerShareAmount + partnerShareAmount;
    final leakagePercent = _leakagePercent(draft);
    final reservePercent = _reservePercent(draft);
    final leakageAmount = totalIncomeBeforeEvent * leakagePercent;
    final reserveAmount = totalIncomeBeforeEvent * reservePercent;
    final totalDeductions =
        totalShareAmount + leakageAmount + reserveAmount;
    final availableEventBudget =
        totalIncomeBeforeEvent - totalDeductions;
    final normalPhaseGross = _normalPhaseGrossSurplusAtTarget(draft, scenario);
    final organizerAfterBreakEven =
        _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
            _organizerMarginPerNormalTicketAfterBreakEven(draft, scenario);
    final featureBudget = _featureBudgetAtTargetAfterBreakEven(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _breakEvenWideBlock(
          context,
          title: 'Szenariovergleich',
          child: _scenarioComparisonContent(context, draft, scenario),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _breakEvenOverviewBlock(
              context,
              title: 'Projekt / Main',
              rows: [
                ('Projekt', draft.title),
                ('Szenario', scenario.name),
                ('Kapazitaet', '${scenario.capacity}'),
                (
                  'Auslastung',
                  '${(_scenarioOccupancy(scenario) * 100).round()} %',
                ),
                ('Besucher', '$attendees'),
                (
                  'Early-Bird',
                  '${earlyBirdPrice.round()} EVC / ${formatEuro(earlyBirdPrice)}',
                ),
                (
                  'Normalpreis',
                  '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
                ),
              ],
              footer: _compactOccupancySlider(draft, scenario),
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Einnahmen vor Veranstaltung',
              rows: [
                ('Tickets', formatEuro(grossTicketsBeforeEvent)),
                ('Sponsoring', formatEuro(draft.fixedSponsorAmountEur)),
                ('Unterstuetzer', formatEuro(draft.supporterAmountEur)),
                ('Foerderung', formatEuro(draft.grantAmountEur)),
                ('Summe Einnahmen', formatEuro(totalIncomeBeforeEvent)),
              ],
              emphasizeLast: true,
            ),
            _editablePercentageBlock(
              context,
              title: 'Abzuege vor Eventfinanzierung',
              rows: [
                (
                  'Veranstaltergewinn',
                  _percentField(
                    initialValue: _editablePercentValue(organizerSharePercent),
                    onChangedValue: (value) => _updateOrganizerSharePercent(draft, value),
                  ),
                  formatEuro(organizerShareAmount),
                ),
                (
                  'Partner',
                  _percentField(
                    initialValue: _editablePercentValue(partnerSharePercent),
                    onChangedValue: (value) => _updatePartnerSharePercent(draft, value),
                  ),
                  formatEuro(partnerShareAmount),
                ),
                (
                  'Risiko / Leckage',
                  _percentField(
                    initialValue: _editablePercentValue(leakagePercent),
                    onChangedValue: (value) => _updateLeakagePercent(draft, value),
                  ),
                  formatEuro(leakageAmount),
                ),
                (
                  'Reserve',
                  _percentField(
                    initialValue: _editablePercentValue(reservePercent),
                    onChangedValue: (value) => _updateReservePercent(draft, value),
                  ),
                  formatEuro(reserveAmount),
                ),
                (
                  'Summe Abzuege',
                  Text('${((totalSharePercent + leakagePercent + reservePercent) * 100).toStringAsFixed(1)} %'),
                  formatEuro(totalDeductions),
                ),
              ],
              emphasizeLast: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _breakEvenOverviewBlock(
              context,
              title: 'Verfuegbar fuer Eventfinanzierung',
              rows: [
                ('Einnahmen gesamt', formatEuro(totalIncomeBeforeEvent)),
                ('abzgl. Abzuege', formatEuro(totalDeductions)),
                ('Budget fuer Eventkosten', formatEuro(availableEventBudget)),
              ],
              emphasizeLast: true,
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Kostenstruktur',
              rows: [
                ('Fixe Grundkosten', formatEuro(fixedEventCosts)),
                ('Variable Wachstumskosten', formatEuro(variableEventCosts)),
                ('Eventkosten gesamt', formatEuro(totalEventCosts)),
                (
                  'Rest nach Eventkosten',
                  formatEuro(availableEventBudget - totalEventCosts),
                ),
              ],
              emphasizeLast: true,
            ),
            _breakEvenOverviewBlock(
              context,
              title: 'Nach Break-even',
              rows: [
                (
                  'Normalpreis-Aufschlag',
                  '${(_normalPriceMarkupPercent(draft) * 100).round()} %',
                ),
                (
                  'Normalpreis-Tickets',
                  '${_normalTicketsAfterBreakEvenAtTarget(draft, scenario)}',
                ),
                ('Ueberschuss brutto', formatEuro(normalPhaseGross)),
                (
                  'Veranstalter-Marge danach',
                  formatEuro(organizerAfterBreakEven),
                ),
                ('Feature-Budget', formatEuro(featureBudget)),
              ],
              emphasizeLast: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _breakEvenOverviewBlock(
    BuildContext context, {
    required String title,
    required List<(String, String)> rows,
    bool emphasizeLast = false,
    Widget? footer,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 420,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLast = index == rows.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _valueRow(
                  row.$1,
                  row.$2,
                  valueStyle: emphasizeLast && isLast
                      ? const TextStyle(fontWeight: FontWeight.w700)
                      : null,
                  ),
                );
              }),
            if (footer != null) ...[
              const SizedBox(height: 8),
              footer,
            ],
          ],
        ),
      ),
    );
  }

  Widget _breakEvenWideBlock(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _compactOccupancySlider(PlanningDraft draft, PlanningScenario scenario) {
    final occupancy = _scenarioOccupancy(scenario);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auslastung feinjustieren: ${(occupancy * 100).round()} %',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(
          width: 260,
          child: Slider(
            value: occupancy,
            min: 0.3,
            max: 1.0,
            divisions: 14,
            label: '${(occupancy * 100).round()} %',
            onChanged: (value) {
              setState(() {
                _scenarioOccupancyOverrides[scenario.id] = value;
                _selectedScenarioOverrides[draft.id] = scenario.id;
              });
              _savePlanningSandboxState();
            },
          ),
        ),
      ],
    );
  }

  Widget _editablePercentageBlock(
    BuildContext context, {
    required String title,
    required List<(String, Widget, String)> rows,
    bool emphasizeLast = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 420,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLast = index == rows.length - 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: row.$2,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: Text(
                        row.$3,
                        textAlign: TextAlign.right,
                        style: emphasizeLast && isLast
                            ? const TextStyle(fontWeight: FontWeight.w700)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _percentField({
    required String initialValue,
    required ValueChanged<String> onChangedValue,
  }) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          setState(() {});
        }
      },
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          suffixText: '%',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChangedValue,
        onEditingComplete: () => setState(() {}),
        onFieldSubmitted: (_) => setState(() {}),
      ),
    );
  }

  String _editablePercentValue(double value) {
    final percent = value * 100;
    if (percent == percent.roundToDouble()) {
      return percent.toStringAsFixed(0);
    }
    return percent.toStringAsFixed(1).replaceAll('.', ',');
  }

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
                setState(() {
                  _selectedScenarioOverrides[draft.id] = scenario.id;
                });
                _savePlanningSandboxState();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? draft.category.color
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
                            onEditingComplete: () => setState(() {}),
                            onFieldSubmitted: (_) => setState(() {}),
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
                            onEditingComplete: () => setState(() {}),
                            onFieldSubmitted: (_) => setState(() {}),
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
                    _valueRow(
                      'Zu deckender Betrag nach Unterstuetzung',
                      formatEuro(_amountToCoverAfterSupportEur(draft, scenario)),
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
                      setState(() {
                        _updateNormalPriceMarkup(draft, value);
                      });
                    },
                    onEditingComplete: () => setState(() {}),
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
    _savePlanningSandboxState();
  }

  bool _isStaffingItemEnabled(PlanningStaffingItem item) {
    return _staffingItemOverrides[item.id] ?? item.enabledByDefault;
  }

  void _setStaffingItemEnabled(PlanningStaffingItem item, bool value) {
    _staffingItemOverrides[item.id] = value;
    _savePlanningSandboxState();
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
    _savePlanningSandboxState();
  }

  void _updateStaffingHours(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingHoursOverrides[item.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateStaffingRate(PlanningStaffingItem item, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _staffingRateOverrides[item.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateScenarioVariableCostPerAttendee(
    PlanningScenario scenario,
    String value,
  ) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _scenarioVariableCostOverrides[scenario.id] = parsed;
    _savePlanningSandboxState();
  }

  void _updateScenarioVariableCostThreshold(
    PlanningScenario scenario,
    String value,
  ) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return;
    }
    _scenarioVariableCostThresholdOverrides[scenario.id] = parsed;
    _savePlanningSandboxState();
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

  List<PlanningArtistCostItem> _artistCostItemsForDraft(PlanningDraft draft) {
    return _artistCostItemOverrides[draft.id] ?? draft.artistCostItems;
  }

  double _artistCostTotalEurForDraft(PlanningDraft draft) {
    return _artistCostItemsForDraft(draft).fold<double>(
      0,
      (total, item) => total + item.grossAmountEur,
    );
  }

  double _artistCostForScenario(PlanningDraft draft, PlanningScenario scenario) {
    final plannedArtistCosts = _artistCostTotalEurForDraft(draft);
    if (plannedArtistCosts <= 0) {
      return scenario.artistCostEur;
    }
    return plannedArtistCosts;
  }

  List<PlanningCostOverviewItem> _costOverviewItemsForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final items = <PlanningCostOverviewItem>[
      PlanningCostOverviewItem(
        label: 'Location / Halle',
        amountEur: scenario.baseRentEur,
        source: scenario.locationName,
      ),
      PlanningCostOverviewItem(
        label: 'Kuenstler',
        amountEur: _artistCostForScenario(draft, scenario),
        source: _artistCostItemsForDraft(draft).isEmpty
            ? 'Szenario-Platzhalter'
            : 'Kuenstler-Tab',
      ),
      PlanningCostOverviewItem(
        label: 'Technik',
        amountEur: scenario.technologyCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Security',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.security,
        ),
        source: 'aktive Security-Bloecke',
      ),
      PlanningCostOverviewItem(
        label: 'Personal',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.staff,
        ),
        source: 'aktive Personal-Bloecke',
      ),
      PlanningCostOverviewItem(
        label: 'Sanitaeter',
        amountEur: _visibleStaffingCostByCategory(
          draft,
          scenario,
          PlanningStaffingCategory.medical,
        ),
        source: 'aktive Sanitaeter-Bloecke',
      ),
      PlanningCostOverviewItem(
        label: 'GEMA',
        amountEur: scenario.gemaCostEur,
        source: 'Szenario / Location',
      ),
      PlanningCostOverviewItem(
        label: 'Werbung',
        amountEur: scenario.marketingCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Versicherung',
        amountEur: scenario.insuranceCostEur,
        source: 'Szenario',
      ),
      PlanningCostOverviewItem(
        label: 'Veranstalterarbeit',
        amountEur: scenario.organizerWorkEur,
        source: 'Planung',
      ),
    ];

    if (_isOptionEnabled(draft, PlanningScenarioOption.toilets)) {
      items.add(
        PlanningCostOverviewItem(
          label: 'Toiletten',
          amountEur: scenario.toiletCostEur,
          source: 'aktiver Chip',
        ),
      );
    }

    if (_isOptionEnabled(draft, PlanningScenarioOption.barriers)) {
      items.add(
        PlanningCostOverviewItem(
          label: 'Absperrgitter',
          amountEur: scenario.barriersCostEur,
          source: 'aktiver Chip',
        ),
      );
    }

    items.add(
      PlanningCostOverviewItem(
        label: 'Variable Wachstumskosten',
        amountEur: _scenarioVariableCostsEur(draft, scenario),
        source: 'Auslastung / Szenario',
        isVariable: true,
      ),
    );

    return items.where((item) => item.amountEur > 0).toList();
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
        _artistCostForScenario(draft, scenario) +
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

  double _scenarioVariableCostsEur(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final costPerAttendee = _scenarioVariableCostPerAttendee(scenario);
    if (costPerAttendee <= 0) {
      return 0;
    }

    final threshold = _scenarioVariableCostThreshold(scenario);
    final variableAttendees = _scenarioTargetAttendees(scenario) - threshold;

    if (variableAttendees <= 0) {
      return 0;
    }

    return variableAttendees * costPerAttendee;
  }

  double _scenarioVariableCostPerAttendee(PlanningScenario scenario) {
    return _scenarioVariableCostOverrides[scenario.id] ??
        scenario.variableCostPerAttendeeEur;
  }

  int _scenarioVariableCostThreshold(PlanningScenario scenario) {
    return _scenarioVariableCostThresholdOverrides[scenario.id] ??
        (scenario.variableCostThresholdAttendees > 0
            ? scenario.variableCostThresholdAttendees
            : (scenario.capacity * 0.5).round());
  }

  double _scenarioEventCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    return _scenarioBaseCostsEur(draft, scenario) +
        _scenarioVariableCostsEur(draft, scenario);
  }

  double _totalPlannedCostsEur(PlanningDraft draft, PlanningScenario scenario) {
    return _requiredGrossRevenueBeforeEvent(draft, scenario);
  }

  double _amountToCoverAfterSupportEur(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final result =
        _requiredGrossRevenueBeforeEvent(draft, scenario) - draft.totalSupportEur;
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

  double _normalPriceMarkupPercent(PlanningDraft draft) {
    return _normalPriceMarkupOverrides[draft.id] ?? 0.5;
  }

  double _leakagePercent(PlanningDraft draft) {
    return _leakagePercentOverrides[draft.id] ?? draft.leakagePercent;
  }

  double _reservePercent(PlanningDraft draft) {
    return _reservePercentOverrides[draft.id] ?? draft.reservePercent;
  }

  double _organizerSharePercent(PlanningDraft draft) {
    return _organizerSharePercentOverrides[draft.id] ??
        draft.organizerMarginPercent;
  }

  double _partnerSharePercent(PlanningDraft draft) {
    return _partnerSharePercentOverrides[draft.id] ?? 0.03;
  }

  double _preEventSharePercent(PlanningDraft draft) {
    return _organizerSharePercent(draft) + _partnerSharePercent(draft);
  }

  double _requiredGrossRevenueBeforeEvent(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final eventCosts = _scenarioEventCostsEur(draft, scenario);
    final deductionFactor =
        1 -
        _preEventSharePercent(draft) -
        _leakagePercent(draft) -
        _reservePercent(draft);

    if (deductionFactor <= 0) {
      return eventCosts;
    }

    return eventCosts / deductionFactor;
  }

  void _updateNormalPriceMarkup(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _normalPriceMarkupOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateLeakagePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _leakagePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateReservePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _reservePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updateOrganizerSharePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _organizerSharePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  void _updatePartnerSharePercent(PlanningDraft draft, String value) {
    final parsed = _parsePlanningNumber(value);
    if (parsed == null || parsed < 0) {
      return;
    }
    _partnerSharePercentOverrides[draft.id] = parsed / 100;
    _savePlanningSandboxState();
  }

  double _roundUpToFullEuro(double value) {
    return value.ceilToDouble();
  }

  double _normalPriceEurForScenario(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final earlyBird = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    return _roundUpToFullEuro(
      earlyBird * (1 + _normalPriceMarkupPercent(draft)),
    );
  }

  int _breakEvenEarlyBirdTickets(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final earlyBirdPrice =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);

    if (earlyBirdPrice <= 0) {
      return 0;
    }

    return (_amountToCoverAfterSupportEur(draft, scenario) / earlyBirdPrice)
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

  double _normalPriceSurplusPerTicketAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalPriceEurForScenario(draft, scenario);
  }

  double _organizerMarginPerNormalTicketAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalPriceEurForScenario(draft, scenario) *
        draft.postBreakEvenMarginPercent;
  }

  double _normalPhaseGrossSurplusAtTarget(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    return _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
        _normalPriceSurplusPerTicketAfterBreakEven(draft, scenario);
  }

  double _featureBudgetAtTargetAfterBreakEven(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final gross = _normalPhaseGrossSurplusAtTarget(draft, scenario);
    final organizerPart =
        _normalTicketsAfterBreakEvenAtTarget(draft, scenario) *
            _organizerMarginPerNormalTicketAfterBreakEven(draft, scenario);
    final result = gross - organizerPart;
    return result < 0 ? 0 : result;
  }

  String _scenarioPriceLabel(PlanningDraft draft, PlanningScenario scenario) {
    final required = _requiredTicketPriceAtTargetOccupancy(draft, scenario);
    if (required <= 50) {
      return 'Preis niedrig';
    }
    if (required <= 75) {
      return 'Preis pruefen';
    }
    return 'Preis hoch';
  }

  String _riskStatusLabel(PlanningDraft draft, PlanningScenario scenario) {
    return _scenarioPriceLabel(draft, scenario);
  }

  PlanningScenario _selectedScenario(PlanningDraft draft) {
    final selectedId = _selectedScenarioOverrides[draft.id];
    if (selectedId == null) {
      return _recommendedScenario(draft);
    }

    return draft.scenarios.firstWhere(
      (scenario) => scenario.id == selectedId,
      orElse: () => _recommendedScenario(draft),
    );
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
    return _riskStatusLabel(draft, _selectedScenario(draft));
  }

  String _mainDecisionSummary(PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final required =
        _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);
    return 'Das ausgewaehlte Szenario braucht bei ${_scenarioTargetAttendees(scenario)} zahlenden Early Birds ${formatEuro(required)} bis Break-even. Danach liegt der Normalpreis bei ${formatEuro(normalPrice)}.';
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
  final List<PlanningArtistCostItem> artistCostItems;
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
    this.artistCostItems = const [],
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
          artistCostEur: 0,
          technologyCostEur: 2600,
          securityCostEur: 1400,
          medicalCostEur: 600,
          toiletCostEur: 400,
          gemaCostEur: 900,
          insuranceCostEur: 320,
          marketingCostEur: 1200,
          organizerWorkEur: 1500,
          barriersCostEur: 350,
          variableCostPerAttendeeEur: 1.2,
          variableCostThresholdAttendees: 250,
          variableCostNote:
              'Mehrgaeste ab 50 % Auslastung fuer Personal, Material und Ablaufpuffer.',
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
          artistCostEur: 0,
          technologyCostEur: 3800,
          securityCostEur: 2200,
          medicalCostEur: 900,
          toiletCostEur: 0,
          gemaCostEur: 1200,
          insuranceCostEur: 450,
          marketingCostEur: 1600,
          organizerWorkEur: 1800,
          barriersCostEur: 500,
          variableCostPerAttendeeEur: 1.8,
          variableCostThresholdAttendees: 425,
          variableCostNote:
              'Wachstumskosten fuer zusaetzliches Personal, GEMA-Staffel und Verbrauch.',
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
          artistCostEur: 0,
          technologyCostEur: 6200,
          securityCostEur: 4200,
          medicalCostEur: 1600,
          toiletCostEur: 1800,
          gemaCostEur: 2200,
          insuranceCostEur: 900,
          marketingCostEur: 2800,
          organizerWorkEur: 2400,
          barriersCostEur: 1200,
          variableCostPerAttendeeEur: 2.5,
          variableCostThresholdAttendees: 1000,
          variableCostNote:
              'Groessere Auslastung braucht mehr Personal, Toiletten, GEMA und Logistik.',
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
          variableCostPerAttendeeEur: 0.8,
          variableCostThresholdAttendees: 120,
          variableCostNote:
              'Mehrgaeste verursachen vor allem Einlass-, Material- und Ablaufkosten.',
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
          variableCostPerAttendeeEur: 1.2,
          variableCostThresholdAttendees: 225,
          variableCostNote:
              'Mehrgaeste koennen zusaetzliche Security, Personal und Verbrauch ausloesen.',
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
          variableCostPerAttendeeEur: 1.8,
          variableCostThresholdAttendees: 600,
          variableCostNote:
              'Bei Wachstum steigen Security, Toiletten, GEMA, Reinigung und Material.',
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
          variableCostPerAttendeeEur: 0.6,
          variableCostThresholdAttendees: 70,
          variableCostNote:
              'Mehr Familien bedeuten zusaetzliche Betreuung, Verbrauch und Ablaufpuffer.',
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
          variableCostPerAttendeeEur: 0.8,
          variableCostThresholdAttendees: 110,
          variableCostNote:
              'Mehrgaeste koennen Betreuung, Verbrauch und Aufsichtskosten erhoehen.',
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
          variableCostPerAttendeeEur: 0.7,
          variableCostThresholdAttendees: 90,
          variableCostNote:
              'Mehrgaeste erzeugen kleinere Zusatzkosten fuer Einlass und Verbrauch.',
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
          variableCostPerAttendeeEur: 1.0,
          variableCostThresholdAttendees: 210,
          variableCostNote:
              'Mehrgaeste koennen zusaetzliches Personal, GEMA und Verbrauch ausloesen.',
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

enum PlanningArtistCostType {
  mainActFee,
  supportActFee,
  djFee,
  travel,
  hotel,
  backstage,
  catering,
  shuttle,
  other,
}

extension PlanningArtistCostTypeX on PlanningArtistCostType {
  String get label {
    switch (this) {
      case PlanningArtistCostType.mainActFee:
        return 'Hauptact';
      case PlanningArtistCostType.supportActFee:
        return 'Support';
      case PlanningArtistCostType.djFee:
        return 'DJ';
      case PlanningArtistCostType.travel:
        return 'Reise';
      case PlanningArtistCostType.hotel:
        return 'Hotel';
      case PlanningArtistCostType.backstage:
        return 'Backstage';
      case PlanningArtistCostType.catering:
        return 'Catering';
      case PlanningArtistCostType.shuttle:
        return 'Shuttle';
      case PlanningArtistCostType.other:
        return 'Sonstiges';
    }
  }
}

class PlanningArtistCostItem {
  final String id;
  final String label;
  final PlanningArtistCostType type;
  final double grossAmountEur;
  final String note;

  const PlanningArtistCostItem({
    required this.id,
    required this.label,
    required this.type,
    required this.grossAmountEur,
    this.note = '',
  });

  PlanningArtistCostItem copyWith({
    String? label,
    PlanningArtistCostType? type,
    double? grossAmountEur,
    String? note,
  }) {
    return PlanningArtistCostItem(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      grossAmountEur: grossAmountEur ?? this.grossAmountEur,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'grossAmountEur': grossAmountEur,
      'note': note,
    };
  }

  factory PlanningArtistCostItem.fromJson(Map<String, dynamic> json) {
    return PlanningArtistCostItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: _artistCostTypeByName(json['type']?.toString()) ??
          PlanningArtistCostType.mainActFee,
      grossAmountEur: json['grossAmountEur'] is num
          ? (json['grossAmountEur'] as num).toDouble()
          : double.tryParse('${json['grossAmountEur']}') ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}

PlanningArtistCostType? _artistCostTypeByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final type in PlanningArtistCostType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return null;
}

class PlanningCostOverviewItem {
  final String label;
  final double amountEur;
  final String source;
  final bool isVariable;

  const PlanningCostOverviewItem({
    required this.label,
    required this.amountEur,
    required this.source,
    this.isVariable = false,
  });
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
  final double variableCostPerAttendeeEur;
  final int variableCostThresholdAttendees;
  final String variableCostNote;
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
    this.variableCostPerAttendeeEur = 0,
    this.variableCostThresholdAttendees = 0,
    this.variableCostNote = '',
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
