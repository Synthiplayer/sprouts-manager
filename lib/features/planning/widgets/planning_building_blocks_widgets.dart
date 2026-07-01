part of '../planning_screen.dart';

class _PlanningCatalogDragData {
  final VoidCallback onDrop;

  const _PlanningCatalogDragData({required this.onDrop});
}

class _CostPositionEditResult {
  final String label;
  final double amountEur;
  final Set<String> selectedAreaNames;

  const _CostPositionEditResult({
    required this.label,
    required this.amountEur,
    this.selectedAreaNames = const {},
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

String _staffCostKeyForBuildingBlock(BuildingBlock block) {
  return '$_staffCostKeyPrefix${block.id}';
}

String _costKeyForBuildingBlock(BuildingBlock block) {
  if (block.costProfile == BuildingBlockCostProfile.gema ||
      block.name.toLowerCase() == 'gema') {
    return 'GEMA';
  }
  return block.name;
}
