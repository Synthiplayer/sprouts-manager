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
                    _infoPair('Projekt', _draftTitle(draft)),
                    _infoPair('Format', _draftFormat(draft)),
                    _infoPair(
                      'Mindestalter',
                      _draftMinimumAge(draft) == 0
                          ? '0 Jahre'
                          : '${_draftMinimumAge(draft)}+',
                    ),
                    _infoPair(
                      'Datum',
                      _draftEventDate(draft).isEmpty
                          ? 'Noch offen'
                          : _draftEventDate(draft),
                    ),
                    _infoPair('Uhrzeit', _draftEventTimeText(draft)),
                    _infoPair(
                      'Anmeldeschluss',
                      _draftRegistrationDeadline(draft).isEmpty
                          ? 'Noch offen'
                          : _draftRegistrationDeadline(draft),
                    ),
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
    final income =
        (_scenarioTargetAttendees(scenario) *
            _requiredEarlyBirdPriceAtTargetOccupancy(draft, scenario)) +
        _totalSupportEur(draft);
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

  PlanningProgramCostItem? _programItemById(
    PlanningDraft draft,
    String? itemId,
  ) {
    if (itemId == null) {
      return null;
    }
    for (final item in _plannedProgramCostItemsForDraft(draft)) {
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
      _programCostItemOverrides[draft.id] = [
        for (final current in _plannedProgramCostItemsForDraft(draft))
          if (current.id != itemId) current,
      ];
    });
    _savePlanningSandboxState();
  }

  List<_PlanningLocationArea> _locationAreasForBlock(BuildingBlock block) {
    return [
      for (final area in block.areas)
        _PlanningLocationArea(
          name: area.name,
          squareMeters: area.squareMeters,
          amountEur: area.amountEur,
        ),
    ];
  }

  Set<String> _defaultLocationAreaNames(BuildingBlock? block) {
    if (block == null || block.areas.isEmpty) {
      return {};
    }
    if (block.selectedAreaNames.isNotEmpty) {
      return {...block.selectedAreaNames};
    }
    return {block.areas.first.name};
  }

  double _locationAmountForAreaNames(
    BuildingBlock? block,
    Set<String> selectedAreaNames,
    double fallbackAmountEur,
  ) {
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
    PlanningBoxItem item,
  ) async {
    final scenario = _selectedScenario(draft);
    final currentLocationBlock = _planningLocationBlock(draft, scenario);
    final currentLocationName = _planningLocationName(draft, scenario);
    final isLocationItem = item.category == PlanningBoxItemCategory.location;
    final isStaffItem = item.category == PlanningBoxItemCategory.staff &&
        item.costKey.startsWith(_staffCostKeyPrefix);
    final displayLabel = item.label;
    final labelController = TextEditingController(
      text: isLocationItem
          ? currentLocationName
          : displayLabel,
    );
    final locationAreas = isLocationItem && currentLocationBlock != null
        ? _locationAreasForBlock(currentLocationBlock)
        : const <_PlanningLocationArea>[];
    final storedAreaNames = isLocationItem
        ? _locationAreaSelectionOverrides[draft.id] ??
            _defaultLocationAreaNames(currentLocationBlock)
        : null;
    final selectedAreaNames = {
      ...(storedAreaNames == null || storedAreaNames.isEmpty
          ? locationAreas.map((area) => area.name)
          : storedAreaNames),
    };
    final amountController = TextEditingController(
      text: item.amountEur == 0 ? '' : _editableMoneyValue(item.amountEur),
    );
    final staffPeopleController = TextEditingController(
      text: isStaffItem ? '${_staffPeopleCount(draft, item.costKey)}' : '1',
    );
    final staffHoursController = TextEditingController(
      text:
          isStaffItem ? _editableMoneyValue(_staffHours(draft, item.costKey)) : '1',
    );
    final staffRateController = TextEditingController(
      text: isStaffItem
          ? _editableMoneyValue(
              _staffHourlyRateEur(draft, item.costKey, item.amountEur),
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
                  readOnly: isLocationItem,
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
                    hintText: '0',
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
                                    currentLocationBlock,
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
      if (!isLocationItem) {
        _costPositionLabelOverrides[
          _costPositionOverrideKey(draft, item.costKey)
        ] = label;
      }
      _costPositionAmountOverrides[
        _costPositionOverrideKey(draft, item.costKey)
      ] = result.amountEur;
      if (isStaffItem) {
        _staffPeopleCountOverrides[
          _costPositionOverrideKey(draft, item.costKey)
        ] = result.staffPeopleCount ?? 1;
        _staffHoursOverrides[
          _costPositionOverrideKey(draft, item.costKey)
        ] = result.staffHours ?? 1;
        _staffHourlyRateOverrides[
          _costPositionOverrideKey(draft, item.costKey)
        ] = result.staffHourlyRateEur ?? result.amountEur;
      }
      if (isLocationItem) {
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

  void _selectLocationBlock(PlanningDraft draft, BuildingBlock block) {
    _refreshPlanningUi(() {
      _locationBlockIdOverrides[draft.id] = block.id;
      _costPositionLabelOverrides.remove(_costPositionOverrideKey(
        draft,
        _locationCostKey,
      ));
      final selectedAreaNames = _defaultLocationAreaNames(block);
      if (selectedAreaNames.isEmpty) {
        _locationAreaSelectionOverrides.remove(draft.id);
        _costPositionAmountOverrides.remove(
          _costPositionOverrideKey(draft, _locationCostKey),
        );
      } else {
        _locationAreaSelectionOverrides[draft.id] = selectedAreaNames;
        _costPositionAmountOverrides[
          _costPositionOverrideKey(draft, _locationCostKey)
        ] = _locationAmountForAreaNames(
          block,
          selectedAreaNames,
          block.defaultAmountEur,
        );
      }
    });
    _savePlanningSandboxState();
  }

  Future<void> _showEditTechnologyCardDialog(
    PlanningDraft draft,
    PlanningTechnologyCostItem item,
  ) async {
    final fallbackLabel = item.type.label;
    final initialLabel = item.label.isEmpty ? fallbackLabel : item.label;
    final useLabelAsHint =
        item.grossUnitAmountEur == 0 && initialLabel == fallbackLabel;
    final result = await _showNameAmountQuantityDialog(
      context: context,
      title: 'Technik bearbeiten',
      initialLabel: useLabelAsHint ? '' : initialLabel,
      labelHint: useLabelAsHint ? initialLabel : null,
      initialQuantity: item.quantity,
      initialUnitAmountEur: item.grossUnitAmountEur,
      showZeroAmountAsHint: true,
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
    PlanningProgramCostItem item,
  ) async {
    final fallbackLabel = item.type.label;
    final initialLabel = item.label.isEmpty ? fallbackLabel : item.label;
    final useLabelAsHint =
        item.grossAmountEur == 0 && initialLabel == fallbackLabel;
    final result = await _showNameAmountDialog(
      context: context,
      title: 'Programm bearbeiten',
      initialLabel: useLabelAsHint ? '' : initialLabel,
      labelHint: useLabelAsHint ? initialLabel : null,
      initialAmountEur: item.grossAmountEur,
      showZeroAmountAsHint: true,
    );

    if (result == null) {
      return;
    }

    _refreshPlanningUi(() {
      _programCostItemOverrides[draft.id] = [
        for (final current in _plannedProgramCostItemsForDraft(draft))
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
    String? labelHint,
    bool showZeroAmountAsHint = false,
  }) async {
    final labelController = TextEditingController(text: initialLabel);
    final amountController = TextEditingController(
      text: showZeroAmountAsHint && initialAmountEur == 0
          ? ''
          : _editableMoneyValue(initialAmountEur),
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
              ).copyWith(hintText: labelHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Betrag brutto',
                hintText: showZeroAmountAsHint && initialAmountEur == 0
                    ? '0'
                    : null,
                suffixText: 'EUR',
                border: const OutlineInputBorder(),
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
    String? labelHint,
    bool showZeroAmountAsHint = false,
  }) async {
    final labelController = TextEditingController(text: initialLabel);
    final quantityController = TextEditingController(
      text: '${initialQuantity < 1 ? 1 : initialQuantity}',
    );
    final unitAmountController = TextEditingController(
      text: showZeroAmountAsHint && initialUnitAmountEur == 0
          ? ''
          : _editableMoneyValue(initialUnitAmountEur),
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
                ).copyWith(hintText: labelHint),
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
                      decoration: InputDecoration(
                        labelText: 'Einzelpreis brutto',
                        hintText:
                            showZeroAmountAsHint && initialUnitAmountEur == 0
                                ? '0'
                                : null,
                        suffixText: 'EUR',
                        border: const OutlineInputBorder(),
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
    required String buildingBlockId,
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
          buildingBlockId: buildingBlockId,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _addProgramCatalogItem(
    PlanningDraft draft, {
    required String label,
    required PlanningProgramCostType type,
    required double amountEur,
    required String buildingBlockId,
  }) {
    final currentItems = [..._plannedProgramCostItemsForDraft(draft)];
    _refreshPlanningUi(() {
      _programCostItemOverrides[draft.id] = [
        ...currentItems,
        PlanningProgramCostItem(
          id: 'program-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          type: type,
          grossAmountEur: amountEur,
          buildingBlockId: buildingBlockId,
        ),
      ];
    });
    _savePlanningSandboxState();
  }

  void _removeCostPosition(
    PlanningDraft draft,
    String costKey,
  ) {
    _refreshPlanningUi(() {
      final overrideKey = _costPositionOverrideKey(draft, costKey);
      _costPositionLabelOverrides.remove(overrideKey);
      _costPositionAmountOverrides.remove(overrideKey);
      _staffPeopleCountOverrides.remove(overrideKey);
      _staffHoursOverrides.remove(overrideKey);
      _staffHourlyRateOverrides.remove(overrideKey);
    });
    _savePlanningSandboxState();
  }
}
