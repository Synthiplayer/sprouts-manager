part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Future<File> _planningSandboxFile() async {
    final directory = _planningSandboxDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return File(
      '${directory.path}${Platform.pathSeparator}${_PlanningScreenState._sandboxFileName}',
    );
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
          _refreshPlanningUi(() {
            _isLoadingSandboxState = false;
          });
        }
        return;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        if (mounted) {
          _refreshPlanningUi(() {
            _isLoadingSandboxState = false;
          });
        }
        return;
      }

      if (!mounted) {
        return;
      }

      _refreshPlanningUi(() {
        _restorePlanningSandboxState(decoded);
        _isLoadingSandboxState = false;
      });
    } catch (_) {
      if (mounted) {
        _refreshPlanningUi(() {
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
      'draftCategoryOverrides': _draftCategoryOverrides.map(
        (draftId, category) => MapEntry(draftId, category.name),
      ),
      'draftTitleOverrides': _draftTitleOverrides,
      'draftPlanningStatusOverrides': _draftPlanningStatusOverrides,
      'draftFormatOverrides': _draftFormatOverrides,
      'draftTargetAudienceOverrides': _draftTargetAudienceOverrides,
      'draftShortDescriptionOverrides': _draftShortDescriptionOverrides,
      'draftMinimumAgeOverrides': _draftMinimumAgeOverrides,
      'locationBlockIdOverrides': _locationBlockIdOverrides,
      'locationAreaSelectionOverrides': _locationAreaSelectionOverrides.map(
        (draftId, areas) => MapEntry(draftId, areas.toList()),
      ),
      'costPositionAmountOverrides': _costPositionAmountOverrides,
      'costPositionLabelOverrides': _costPositionLabelOverrides,
      'staffPeopleCountOverrides': _staffPeopleCountOverrides,
      'staffHoursOverrides': _staffHoursOverrides,
      'staffHourlyRateOverrides': _staffHourlyRateOverrides,
      'scenarioOccupancyOverrides': _scenarioOccupancyOverrides,
      'scenarioVariableCostOverrides': _scenarioVariableCostOverrides,
      'scenarioVariableCostThresholdOverrides':
          _scenarioVariableCostThresholdOverrides,
      'normalPriceMarkupOverrides': _normalPriceMarkupOverrides,
      'leakagePercentOverrides': _leakagePercentOverrides,
      'reservePercentOverrides': _reservePercentOverrides,
      'organizerSharePercentOverrides': _organizerSharePercentOverrides,
      'partnerSharePercentOverrides': _partnerSharePercentOverrides,
      'artistCostItemOverrides': _artistCostItemOverrides.map(
        (draftId, items) => MapEntry(
          draftId,
          items.map((item) => item.toJson()).toList(),
        ),
      ),
      'technologyCostItemOverrides': _technologyCostItemOverrides.map(
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
    _draftCategoryOverrides
      ..clear()
      ..addAll(_eventCategoryMap(json['draftCategoryOverrides']));
    _draftTitleOverrides
      ..clear()
      ..addAll(_stringMap(json['draftTitleOverrides']));
    _draftPlanningStatusOverrides
      ..clear()
      ..addAll(_stringMap(json['draftPlanningStatusOverrides']));
    _draftFormatOverrides
      ..clear()
      ..addAll(_stringMap(json['draftFormatOverrides']));
    _draftTargetAudienceOverrides
      ..clear()
      ..addAll(_stringMap(json['draftTargetAudienceOverrides']));
    _draftShortDescriptionOverrides
      ..clear()
      ..addAll(_stringMap(json['draftShortDescriptionOverrides']));
    _draftMinimumAgeOverrides
      ..clear()
      ..addAll(_intMap(json['draftMinimumAgeOverrides']));
    _locationBlockIdOverrides
      ..clear()
      ..addAll(_stringMap(json['locationBlockIdOverrides']));
    _locationAreaSelectionOverrides
      ..clear()
      ..addAll(_stringSetMap(json['locationAreaSelectionOverrides']));
    _costPositionAmountOverrides
      ..clear()
      ..addAll(_doubleMap(json['costPositionAmountOverrides']));
    _costPositionLabelOverrides
      ..clear()
      ..addAll(_stringMap(json['costPositionLabelOverrides']));
    _staffPeopleCountOverrides
      ..clear()
      ..addAll(_intMap(json['staffPeopleCountOverrides']));
    _staffHoursOverrides
      ..clear()
      ..addAll(_doubleMap(json['staffHoursOverrides']));
    _staffHourlyRateOverrides
      ..clear()
      ..addAll(_doubleMap(json['staffHourlyRateOverrides']));
    _scenarioOccupancyOverrides
      ..clear()
      ..addAll(_doubleMap(json['scenarioOccupancyOverrides']));
    _scenarioVariableCostOverrides
      ..clear()
      ..addAll(_doubleMap(json['scenarioVariableCostOverrides']));
    _scenarioVariableCostThresholdOverrides
      ..clear()
      ..addAll(_intMap(json['scenarioVariableCostThresholdOverrides']));
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

    _artistCostItemOverrides
      ..clear()
      ..addAll(_artistCostItemMap(json['artistCostItemOverrides']));
    _technologyCostItemOverrides
      ..clear()
      ..addAll(_technologyCostItemMap(json['technologyCostItemOverrides']));

    _removeObsoletePlanningOverrideKeys();
  }

  void _removeObsoletePlanningOverrideKeys() {
    _costPositionLabelOverrides.removeWhere(
      (key, _) => !_isSupportedCostOverrideKey(key),
    );
    _costPositionAmountOverrides.removeWhere(
      (key, _) => !_isSupportedCostOverrideKey(key),
    );
    _staffPeopleCountOverrides.removeWhere(
      (key, _) => !_isSupportedStaffOverrideKey(key),
    );
    _staffHoursOverrides.removeWhere(
      (key, _) => !_isSupportedStaffOverrideKey(key),
    );
    _staffHourlyRateOverrides.removeWhere(
      (key, _) => !_isSupportedStaffOverrideKey(key),
    );
  }

  bool _isSupportedCostOverrideKey(String overrideKey) {
    final costKey = _costKeyFromOverrideKey(overrideKey);
    return costKey == _locationCostKey ||
        costKey.startsWith(_staffCostKeyPrefix) ||
        costKey.startsWith(_costBlockKeyPrefix);
  }

  bool _isSupportedStaffOverrideKey(String overrideKey) {
    return _costKeyFromOverrideKey(overrideKey).startsWith(_staffCostKeyPrefix);
  }

  String _costKeyFromOverrideKey(String overrideKey) {
    final separatorIndex = overrideKey.indexOf('::');
    if (separatorIndex < 0) {
      return '';
    }
    return overrideKey.substring(separatorIndex + 2);
  }

  Map<String, String> _stringMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map(
      (key, entry) => MapEntry(key.toString(), entry.toString()),
    );
  }

  Map<String, Set<String>> _stringSetMap(Object? value) {
    if (value is! Map) {
      return {};
    }

    final result = <String, Set<String>>{};
    for (final entry in value.entries) {
      final rawAreas = entry.value;
      if (rawAreas is! List) {
        continue;
      }
      result[entry.key.toString()] = {
        for (final area in rawAreas) area.toString(),
      };
    }
    return result;
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

  Map<String, EventCategory> _eventCategoryMap(Object? value) {
    if (value is! Map) {
      return {};
    }
    return value.map(
      (key, entry) => MapEntry(
        key.toString(),
        EventCategoryX.fromStoredValue(entry?.toString()),
      ),
    );
  }

  Map<String, List<PlanningTechnologyCostItem>> _technologyCostItemMap(
    Object? value,
  ) {
    if (value is! Map) {
      return {};
    }

    final result = <String, List<PlanningTechnologyCostItem>>{};
    for (final draftEntry in value.entries) {
      final items = draftEntry.value;
      if (items is! List) {
        continue;
      }
      result[draftEntry.key.toString()] = [
        for (final item in items)
          if (item is Map)
            PlanningTechnologyCostItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
      ];
    }
    return result;
  }
}
