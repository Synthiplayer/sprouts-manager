part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildMainTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final earlyBirdPrice = _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario);
    final normalPrice = _normalPriceEurForScenario(draft, scenario);
    final preEventBalance =
        _mainAvailableEventBudgetBeforeEvent(draft, scenario) -
            _scenarioEventCostsEur(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
            context,
            title: 'Main / Entscheidungsansicht',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _planningCategory(draft).toChip(filled: false),
                    _pill(context, _mainDecisionStatus(draft)),
                    _pill(context, scenario.name),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 14,
                  children: [
                    _infoPair('Projekt', draft.title),
                    _infoPair('Format', draft.format),
                    _infoPair('Zielgruppe', draft.targetAudience),
                    _infoPair('Location', _planningLocationName(draft, scenario)),
                    _infoPair('Setup', scenario.setupName),
                    _infoPair('Besucher Ziel', '${_scenarioTargetAttendees(scenario)}'),
                    _infoPair(
                      'Early-Bird bis Break-even',
                      '${earlyBirdPrice.round()} EVC / ${formatEuro(earlyBirdPrice)}',
                    ),
                    _infoPair(
                      'Normalpreis danach',
                      '${normalPrice.round()} EVC / ${formatEuro(normalPrice)}',
                    ),
                    _infoPair(
                      preEventBalance >= 0
                          ? 'Puffer vor Veranstaltung'
                          : 'Fehlbetrag vor Veranstaltung',
                      formatEuro(preEventBalance),
                    ),
                    _infoPair(
                      'Feature-Budget danach',
                      formatEuro(
                        _featureBudgetAtTargetAfterBreakEven(draft, scenario),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_mainDecisionSummary(draft)),
              ],
            )),
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
      ],
    );
  }

  Widget _buildConfigurationTab(BuildContext context, PlanningDraft draft) {
    final scenario = _selectedScenario(draft);
    final planningBoxItems = _planningBoxItemsForScenario(draft, scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Planungs-Konfiguration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<EventCategory>(
                      initialValue: _planningCategory(draft),
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: EventCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: (category) {
                        if (category == null) {
                          return;
                        }
                        _refreshPlanningUi(() {
                          _draftCategoryOverrides[draft.id] = category;
                        });
                        _savePlanningSandboxState();
                      },
                    ),
                  ),
                  _infoPair('Mindestkapazitaet', '${draft.minimumCapacity}'),
                  _infoPair('Raumkonzept', draft.seatingMode),
                  _infoPair('Location', _planningLocationName(draft, scenario)),
                  _infoPair('Setup', scenario.setupName),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Die Planung nutzt Bausteine aus der zentralen Baustein-Verwaltung. Neue Location-, Technik-, Programm- oder Kostenkarten werden dort angelegt und erscheinen anschließend hier.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final catalog = _buildPlanningCardCatalog(context, draft);
            final planningBox = _buildPlanningBox(
              context,
              draft,
              planningBoxItems,
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  catalog,
                  const SizedBox(height: 12),
                  planningBox,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 340, child: catalog),
                const SizedBox(width: 12),
                Expanded(child: planningBox),
              ],
            );
          },
        ),
      ],
    );
  }

  double _mainAvailableEventBudgetBeforeEvent(
    PlanningDraft draft,
    PlanningScenario scenario,
  ) {
    final income = _requiredGrossRevenueBeforeEvent(draft, scenario);
    final deductions = income *
        (_preEventSharePercent(draft) +
            _leakagePercent(draft) +
            _reservePercent(draft));
    return income - deductions;
  }

  PlanningTechnologyCostItem? _technologyItemById(
    PlanningDraft draft,
    String? itemId,
  ) {
    if (itemId == null) {
      return null;
    }
    for (final item in _plannedTechnologyCostItemsForDraft(draft)) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  PlanningArtistCostItem? _programItemById(
    PlanningDraft draft,
    String? itemId,
  ) {
    if (itemId == null) {
      return null;
    }
    for (final item in _plannedArtistCostItemsForDraft(draft)) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  void _removeTechnologyItem(PlanningDraft draft, String? itemId) {
    if (itemId == null) {
      return;
    }
    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        for (final current in _plannedTechnologyCostItemsForDraft(draft))
          if (current.id != itemId) current,
      ];
    });
    _savePlanningSandboxState();
  }

  void _removeProgramItem(PlanningDraft draft, String? itemId) {
    if (itemId == null) {
      return;
    }
    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        for (final current in _plannedArtistCostItemsForDraft(draft))
          if (current.id != itemId) current,
      ];
    });
    _savePlanningSandboxState();
  }

  List<_PlanningLocationArea> _locationAreasForName(String locationName) {
    final locationBlock = _locationBuildingBlockForName(locationName);
    if (locationBlock == null) {
      return const [];
    }

    return [
      for (final area in locationBlock.areas)
        _PlanningLocationArea(
          name: area.name,
          squareMeters: area.squareMeters,
          amountEur: area.amountEur,
        ),
    ];
  }

  BuildingBlock? _locationBuildingBlockForName(String locationName) {
    for (final block in buildingBlockCatalogStore.value) {
      if (block.category == BuildingBlockCategory.location &&
          block.name == locationName) {
        return block;
      }
    }
    return null;
  }

  Set<String> _defaultLocationAreaNames(String locationName) {
    final block = _locationBuildingBlockForName(locationName);
    if (block == null || block.areas.isEmpty) {
      return {};
    }
    if (block.selectedAreaNames.isNotEmpty) {
      return {...block.selectedAreaNames};
    }
    return {block.areas.first.name};
  }

  double _locationAmountForAreaNames(
    String locationName,
    Set<String> selectedAreaNames,
    double fallbackAmountEur,
  ) {
    final block = _locationBuildingBlockForName(locationName);
    if (block == null || block.areas.isEmpty) {
      return fallbackAmountEur;
    }

    final selectedAreas = block.areas
        .where((area) => selectedAreaNames.contains(area.name))
        .toList();
    final areaAmount = selectedAreas.fold<double>(
      0,
      (total, area) => total + area.amountEur,
    );
    if (selectedAreas.isNotEmpty) {
      return areaAmount;
    }
    if (block.defaultAmountEur > 0) {
      return block.defaultAmountEur;
    }
    return fallbackAmountEur;
  }

  Future<void> _showCostPositionEditDialog(
    BuildContext context,
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) async {
    final currentLocationName = _planningLocationName(
      draft,
      _selectedScenario(draft),
    );
    final isLocationItem = item.label == 'Location / Halle';
    final isStaffItem = item.label.startsWith(_staffCostKeyPrefix);
    final displayLabel = _costPositionDisplayLabel(draft, item);
    final labelController = TextEditingController(
      text: isLocationItem
          ? currentLocationName
          : displayLabel,
    );
    final locationAreas = item.label == 'Location / Halle'
        ? _locationAreasForName(currentLocationName)
        : const <_PlanningLocationArea>[];
    final storedAreaNames = isLocationItem
        ? _locationAreaSelectionOverrides[draft.id] ??
            _defaultLocationAreaNames(currentLocationName)
        : null;
    final selectedAreaNames = {
      ...(storedAreaNames == null || storedAreaNames.isEmpty
          ? locationAreas.map((area) => area.name)
          : storedAreaNames),
    };
    final amountController = TextEditingController(
      text: _editableMoneyValue(
        item.amountEur,
      ),
    );
    final staffPeopleController = TextEditingController(
      text: isStaffItem ? '${_staffPeopleCount(draft, item.label)}' : '1',
    );
    final staffHoursController = TextEditingController(
      text: isStaffItem ? _editableMoneyValue(_staffHours(draft, item.label)) : '1',
    );
    final staffRateController = TextEditingController(
      text: isStaffItem
          ? _editableMoneyValue(
              _staffHourlyRateEur(draft, item.label, item.amountEur),
            )
          : _editableMoneyValue(item.amountEur),
    );

    _CostPositionEditResult currentResult() {
      final parsedPeopleCount =
          int.tryParse(staffPeopleController.text.trim()) ?? 1;
      final staffPeopleCount =
          parsedPeopleCount < 1 ? 1 : parsedPeopleCount;
      final parsedStaffHours = parseEuroInput(staffHoursController.text);
      final staffHours = parsedStaffHours < 0 ? 0.0 : parsedStaffHours;
      final parsedStaffHourlyRate = parseEuroInput(staffRateController.text);
      final staffHourlyRateEur =
          parsedStaffHourlyRate < 0 ? 0.0 : parsedStaffHourlyRate;
      final amountEur = isStaffItem
          ? staffPeopleCount * staffHours * staffHourlyRateEur
          : parseEuroInput(amountController.text);

      return _CostPositionEditResult(
        label: labelController.text.trim(),
        amountEur: amountEur,
        selectedAreaNames: selectedAreaNames,
        staffPeopleCount: isStaffItem ? staffPeopleCount : null,
        staffHours: isStaffItem ? staffHours : null,
        staffHourlyRateEur: isStaffItem ? staffHourlyRateEur : null,
      );
    }

    void refreshStaffTotal(StateSetter setDialogState) {
      if (!isStaffItem) {
        return;
      }
      setDialogState(() {
        amountController.text = _editableMoneyValue(currentResult().amountEur);
      });
    }

    final result = await showDialog<_CostPositionEditResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isLocationItem
                ? '$currentLocationName bearbeiten'
                : '$displayLabel bearbeiten',
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  readOnly: isStaffItem,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Betrag brutto',
                    suffixText: 'EUR',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(currentResult());
                  },
                ),
                if (isStaffItem) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: staffPeopleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Personen',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => refreshStaffTotal(setDialogState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: staffHoursController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Stunden',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => refreshStaffTotal(setDialogState),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: staffRateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Satz brutto pro Stunde',
                      suffixText: 'EUR',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => refreshStaffTotal(setDialogState),
                  ),
                ],
                if (locationAreas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bereiche',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final area in locationAreas)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selectedAreaNames.contains(area.name),
                      onChanged: selectedAreaNames.length == 1 &&
                              selectedAreaNames.contains(area.name)
                          ? null
                          : (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedAreaNames.add(area.name);
                                } else {
                                  selectedAreaNames.remove(area.name);
                                }
                                amountController.text = _editableMoneyValue(
                                  _locationAmountForAreaNames(
                                    currentLocationName,
                                    selectedAreaNames,
                                    parseEuroInput(amountController.text),
                                  ),
                                );
                              });
                            },
                      title: Text(
                        area.amountEur <= 0
                            ? '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m²'
                            : '${area.name} · ${area.squareMeters.toStringAsFixed(0)} m² · ${formatEuro(area.amountEur)}',
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(currentResult());
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.amountEur < 0) {
      return;
    }

    _refreshPlanningUi(() {
      final label = result.label.isEmpty ? item.label : result.label;
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, item.label)
      ] = label;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, item.label)
      ] = result.amountEur;
      if (isStaffItem) {
        _staffPeopleCountOverrides[
          _costPositionOverrideKey(draft, item.label)
        ] = result.staffPeopleCount ?? 1;
        _staffHoursOverrides[
          _costPositionOverrideKey(draft, item.label)
        ] = result.staffHours ?? 1;
        _staffHourlyRateOverrides[
          _costPositionOverrideKey(draft, item.label)
        ] = result.staffHourlyRateEur ?? result.amountEur;
      }
      if (item.label == 'Location / Halle') {
        if (locationAreas.isEmpty) {
          _locationNameOverrides[draft.id] = label;
        } else {
          _locationNameOverrides.remove(draft.id);
        }
        if (locationAreas.isNotEmpty) {
          _locationAreaSelectionOverrides[draft.id] =
              result.selectedAreaNames.isEmpty
                  ? {locationAreas.first.name}
                  : result.selectedAreaNames;
        }
      }
    });
    _savePlanningSandboxState();
  }

  String _costPositionDisplayLabel(
    PlanningDraft draft,
    PlanningCostOverviewItem item,
  ) {
    final overrideLabel = _costPositionLabelOverrides[
      _costPositionOverrideKey(draft, item.label)
    ];
    if (overrideLabel != null) {
      return overrideLabel;
    }
    if (item.label.startsWith(_staffCostKeyPrefix)) {
      return _planningBoxLabelForCostKey(
        draft,
        _selectedScenario(draft),
        item.label,
      );
    }
    return item.label;
  }

  void _selectLocationScenario(PlanningDraft draft, String locationName) {
    PlanningScenario? matchingScenario;
    for (final scenario in draft.scenarios) {
      if (scenario.locationName == locationName) {
        matchingScenario = scenario;
        break;
      }
    }

    if (matchingScenario == null) {
      _showCreateLocationCardDialog(draft, initialLabel: locationName);
      return;
    }

    final selectedScenario = matchingScenario;
    _refreshPlanningUi(() {
      _selectedScenarioOverrides[draft.id] = selectedScenario.id;
      _locationNameOverrides.remove(draft.id);
      _costPositionLabelOverrides.remove(
        _costPositionOverrideKey(draft, 'Location / Halle'),
      );
      final selectedAreaNames = _defaultLocationAreaNames(locationName);
      if (selectedAreaNames.isEmpty) {
        _locationAreaSelectionOverrides.remove(draft.id);
        _costPositionAmountOverrides.remove(
          _costPositionOverrideKey(draft, 'Location / Halle'),
        );
      } else {
        _locationAreaSelectionOverrides[draft.id] = selectedAreaNames;
        _costPositionAmountOverrides[
          _costPositionOverrideKey(draft, 'Location / Halle')
        ] = _locationAmountForAreaNames(
          locationName,
          selectedAreaNames,
          selectedScenario.baseRentEur,
        );
      }
    });
    _savePlanningSandboxState();
  }

  Future<void> _showCreateLocationCardDialog(
    PlanningDraft draft, {
    required String initialLabel,
  }) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Location bearbeiten',
      initialLabel: initialLabel,
      initialAmountEur: 0,
    );

    if (result == null) {
      return;
    }

    _applyLocationOverride(
      draft,
      label: result.label.isEmpty ? initialLabel : result.label,
      amountEur: result.amountEur,
    );
  }

  void _applyLocationOverride(
    PlanningDraft draft, {
    required String label,
    required double amountEur,
  }) {
    _refreshPlanningUi(() {
      _locationNameOverrides[draft.id] = label;
      _costPositionLabelOverrides[
        _costPositionOverrideKey(draft, 'Location / Halle')
      ] = label;
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, 'Location / Halle')
      ] = amountEur;
    });
    _savePlanningSandboxState();
  }

  Future<void> _showEditTechnologyCardDialog(
    PlanningDraft draft,
    PlanningTechnologyCostItem item,
  ) async {
    final result = await _showNameAmountQuantityDialog(
      context: context,
      title: 'Technik bearbeiten',
      initialLabel: item.label.isEmpty ? item.type.label : item.label,
      initialQuantity: item.quantity,
      initialUnitAmountEur: item.grossUnitAmountEur,
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        for (final current in _plannedTechnologyCostItemsForDraft(draft))
          if (current.id == item.id)
            current.copyWith(
              label: result.label.isEmpty ? current.label : result.label,
              quantity: result.quantity,
              grossUnitAmountEur: result.unitAmountEur,
            )
          else
            current,
      ];
    });
    _savePlanningSandboxState();
  }

  Future<void> _showEditProgramCardDialog(
    PlanningDraft draft,
    PlanningArtistCostItem item,
  ) async {
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Programm bearbeiten',
      initialLabel: item.label.isEmpty ? item.type.label : item.label,
      initialAmountEur: item.grossAmountEur,
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        for (final current in _plannedArtistCostItemsForDraft(draft))
          if (current.id == item.id)
            current.copyWith(
              label: result.label.isEmpty ? current.label : result.label,
              grossAmountEur: result.amountEur,
            )
          else
            current,
      ];
    });
    _savePlanningSandboxState();
  }

  Future<_CostPositionEditResult?> _showNameAmountDialog({
    required BuildContext context,
    required String title,
    required String initialLabel,
    required double initialAmountEur,
  }) async {
    final labelController = TextEditingController(text: initialLabel);
    final amountController = TextEditingController(
      text: _editableMoneyValue(initialAmountEur),
    );

    final result = await showDialog<_CostPositionEditResult>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Betrag brutto',
                suffixText: 'EUR',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(
                  _CostPositionEditResult(
                    label: labelController.text.trim(),
                    amountEur: parseEuroInput(value),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _CostPositionEditResult(
                  label: labelController.text.trim(),
                  amountEur: parseEuroInput(amountController.text),
                ),
              );
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == null || result.amountEur < 0) {
      return null;
    }

    return result;
  }

  Future<_NameAmountQuantityEditResult?> _showNameAmountQuantityDialog({
    required BuildContext context,
    required String title,
    required String initialLabel,
    required int initialQuantity,
    required double initialUnitAmountEur,
  }) async {
    final labelController = TextEditingController(text: initialLabel);
    final quantityController = TextEditingController(
      text: '${initialQuantity < 1 ? 1 : initialQuantity}',
    );
    final unitAmountController = TextEditingController(
      text: _editableMoneyValue(initialUnitAmountEur),
    );
    final totalController = TextEditingController(
      text: _editableMoneyValue(
        (initialQuantity < 1 ? 1 : initialQuantity) * initialUnitAmountEur,
      ),
    );

    int quantityValue() {
      final parsed = int.tryParse(quantityController.text.trim()) ?? 1;
      return parsed < 1 ? 1 : parsed;
    }

    double unitAmountValue() {
      final parsed = parseEuroInput(unitAmountController.text);
      return parsed < 0 ? 0.0 : parsed;
    }

    _NameAmountQuantityEditResult currentResult() {
      return _NameAmountQuantityEditResult(
        label: labelController.text.trim(),
        quantity: quantityValue(),
        unitAmountEur: unitAmountValue(),
      );
    }

    void refreshTotal(StateSetter setDialogState) {
      setDialogState(() {
        totalController.text = _editableMoneyValue(
          quantityValue() * unitAmountValue(),
        );
      });
    }

    final result = await showDialog<_NameAmountQuantityEditResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Anzahl',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => refreshTotal(setDialogState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: unitAmountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Einzelpreis brutto',
                        suffixText: 'EUR',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => refreshTotal(setDialogState),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Gesamt brutto',
                  suffixText: 'EUR',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(currentResult());
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  void _addTechnologyCatalogItem(
    PlanningDraft draft, {
    required String label,
    required PlanningTechnologyCostType type,
    required double amountEur,
    required String sourceBlockName,
  }) {
    final currentItems = [..._plannedTechnologyCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _technologyCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningTechnologyCostItem(
          id: 'technology-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          quantity: 1,
          grossUnitAmountEur: amountEur,
          note: sourceBlockName,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _addProgramCatalogItem(
    PlanningDraft draft, {
    required String label,
    required PlanningArtistCostType type,
    required double amountEur,
    required String sourceBlockName,
  }) {
    final currentItems = [..._plannedArtistCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _artistCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningArtistCostItem(
          id: 'program-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          grossAmountEur: amountEur,
          note: sourceBlockName,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _removeCostPosition(
    PlanningDraft draft,
    String label,
  ) {
    _refreshPlanningUi(() {
      _costPositionLabelOverrides.remove(_costPositionOverrideKey(draft, label));
      _costPositionAmountOverrides.remove(_costPositionOverrideKey(draft, label));
      _staffPeopleCountOverrides.remove(_costPositionOverrideKey(draft, label));
      _staffHoursOverrides.remove(_costPositionOverrideKey(draft, label));
      _staffHourlyRateOverrides.remove(_costPositionOverrideKey(draft, label));
    });
    _savePlanningSandboxState();
  }
}
