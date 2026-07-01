part of '../planning_screen.dart';

class _PlanningCatalogDragData {
  final VoidCallback onDrop;

  const _PlanningCatalogDragData({required this.onDrop});
}

class _CostPositionEditResult {
  final String label;
  final double amountEur;
  final Set<String> selectedAreaNames;
  final int? staffPeopleCount;
  final double? staffHours;
  final double? staffHourlyRateEur;

  const _CostPositionEditResult({
    required this.label,
    required this.amountEur,
    this.selectedAreaNames = const {},
    this.staffPeopleCount,
    this.staffHours,
    this.staffHourlyRateEur,
  });
}

class _NameAmountQuantityEditResult {
  final String label;
  final int quantity;
  final double unitAmountEur;

  const _NameAmountQuantityEditResult({
    required this.label,
    required this.quantity,
    required this.unitAmountEur,
  });
}

class _PlanningLocationArea {
  final String name;
  final double squareMeters;
  final double amountEur;

  const _PlanningLocationArea({
    required this.name,
    required this.squareMeters,
    this.amountEur = 0,
  });
}

const String _staffCostKeyPrefix = 'staff::';
const String _costBlockKeyPrefix = 'cost::';
const String _locationCostKey = 'location';
const String _programCostKey = 'program';
const String _technologyCostKey = 'technology';

String _staffCostKeyForBuildingBlock(BuildingBlock block) {
  return '$_staffCostKeyPrefix${block.id}';
}

String _newStaffCostKeyForBuildingBlock(BuildingBlock block) {
  return '${_staffCostKeyForBuildingBlock(block)}::${DateTime.now().microsecondsSinceEpoch}';
}

String _staffBlockIdFromCostKey(String costKey) {
  final withoutPrefix = costKey.substring(_staffCostKeyPrefix.length);
  return withoutPrefix.split('::').first;
}

String _costKeyForBuildingBlock(BuildingBlock block) {
  return '$_costBlockKeyPrefix${block.id}';
}

String _costBlockIdFromCostKey(String costKey) {
  return costKey.substring(_costBlockKeyPrefix.length);
}

bool _isCostBlockKey(String costKey) {
  return costKey.startsWith(_costBlockKeyPrefix);
}
