import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/event_currency_config.dart';

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

class PlanningDraft {
  final String id;
  final String title;
  final EventCategory category;
  final String format;
  final String shortDescription;
  final String planningStatus;
  final String eventDate;
  final String startTime;
  final String endTime;
  final String registrationDeadline;
  final int minimumCapacity;
  final String seatingMode;
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
  final List<PlanningProgramCostItem> programCostItems;
  final List<PlanningTechnologyCostItem> technologyCostItems;
  final List<PlanningScenario> scenarios;
  final List<PlanningPartnerProfile> partners;
  final List<PlanningUpgradeStage> upgradeStages;

  const PlanningDraft({
    required this.id,
    required this.title,
    required this.category,
    required this.format,
    required this.shortDescription,
    required this.planningStatus,
    this.eventDate = '',
    this.startTime = '',
    this.endTime = '',
    this.registrationDeadline = '',
    required this.minimumCapacity,
    required this.seatingMode,
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
    this.programCostItems = const [],
    this.technologyCostItems = const [],
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
}

enum PlanningProgramCostType {
  act,
  dj,
  filmLicense,
  other,
}

extension PlanningProgramCostTypeX on PlanningProgramCostType {
  String get label {
    switch (this) {
      case PlanningProgramCostType.act:
        return 'Künstler / Act';
      case PlanningProgramCostType.dj:
        return 'DJ';
      case PlanningProgramCostType.filmLicense:
        return 'Film / Lizenz';
      case PlanningProgramCostType.other:
        return 'Programm';
    }
  }
}

class PlanningProgramCostItem {
  final String id;
  final String label;
  final PlanningProgramCostType type;
  final double grossAmountEur;
  final String buildingBlockId;
  final String note;

  const PlanningProgramCostItem({
    required this.id,
    required this.label,
    required this.type,
    required this.grossAmountEur,
    this.buildingBlockId = '',
    this.note = '',
  });

  PlanningProgramCostItem copyWith({
    String? label,
    PlanningProgramCostType? type,
    double? grossAmountEur,
    String? buildingBlockId,
    String? note,
  }) {
    return PlanningProgramCostItem(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      grossAmountEur: grossAmountEur ?? this.grossAmountEur,
      buildingBlockId: buildingBlockId ?? this.buildingBlockId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'grossAmountEur': grossAmountEur,
      'buildingBlockId': buildingBlockId,
      'note': note,
    };
  }

  factory PlanningProgramCostItem.fromJson(Map<String, dynamic> json) {
    return PlanningProgramCostItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: _programCostTypeByName(json['type']?.toString()) ??
          PlanningProgramCostType.act,
      grossAmountEur: json['grossAmountEur'] is num
          ? (json['grossAmountEur'] as num).toDouble()
          : double.tryParse('${json['grossAmountEur']}') ?? 0,
      buildingBlockId: json['buildingBlockId']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

PlanningProgramCostType? _programCostTypeByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final type in PlanningProgramCostType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return null;
}

enum PlanningTechnologyCostType {
  stage,
  sound,
  truss,
  light,
  screenProjector,
  surroundSound,
  other,
}

extension PlanningTechnologyCostTypeX on PlanningTechnologyCostType {
  String get label {
    switch (this) {
      case PlanningTechnologyCostType.stage:
        return 'Buehne';
      case PlanningTechnologyCostType.sound:
        return 'Ton';
      case PlanningTechnologyCostType.truss:
        return 'Traversen';
      case PlanningTechnologyCostType.light:
        return 'Licht';
      case PlanningTechnologyCostType.screenProjector:
        return 'Leinwand / Beamer';
      case PlanningTechnologyCostType.surroundSound:
        return 'Surround-Ton';
      case PlanningTechnologyCostType.other:
        return 'Sonstiges';
    }
  }
}

class PlanningTechnologyCostItem {
  final String id;
  final String label;
  final PlanningTechnologyCostType type;
  final int quantity;
  final double grossUnitAmountEur;
  final String buildingBlockId;
  final String note;

  const PlanningTechnologyCostItem({
    required this.id,
    required this.label,
    required this.type,
    required this.quantity,
    required this.grossUnitAmountEur,
    this.buildingBlockId = '',
    this.note = '',
  });

  double get grossTotalEur => quantity * grossUnitAmountEur;

  PlanningTechnologyCostItem copyWith({
    String? label,
    PlanningTechnologyCostType? type,
    int? quantity,
    double? grossUnitAmountEur,
    String? buildingBlockId,
    String? note,
  }) {
    return PlanningTechnologyCostItem(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      grossUnitAmountEur: grossUnitAmountEur ?? this.grossUnitAmountEur,
      buildingBlockId: buildingBlockId ?? this.buildingBlockId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'quantity': quantity,
      'grossUnitAmountEur': grossUnitAmountEur,
      'buildingBlockId': buildingBlockId,
      'note': note,
    };
  }

  factory PlanningTechnologyCostItem.fromJson(Map<String, dynamic> json) {
    return PlanningTechnologyCostItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: _technologyCostTypeByName(json['type']?.toString()) ??
          PlanningTechnologyCostType.sound,
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse('${json['quantity']}') ?? 1,
      grossUnitAmountEur: json['grossUnitAmountEur'] is num
          ? (json['grossUnitAmountEur'] as num).toDouble()
          : double.tryParse('${json['grossUnitAmountEur']}') ?? 0,
      buildingBlockId: json['buildingBlockId']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }
}

PlanningTechnologyCostType? _technologyCostTypeByName(String? name) {
  if (name == null) {
    return null;
  }
  for (final type in PlanningTechnologyCostType.values) {
    if (type.name == name) {
      return type;
    }
  }
  return null;
}

class PlanningCostOverviewItem {
  final String label;
  final double amountEur;
  final String description;
  final String calculationHint;
  final bool isVariable;

  const PlanningCostOverviewItem({
    required this.label,
    required this.amountEur,
    this.description = '',
    this.calculationHint = '',
    this.isVariable = false,
  });
}

enum PlanningBoxItemCategory {
  location,
  technology,
  program,
  staff,
  cost,
}

extension PlanningBoxItemCategoryX on PlanningBoxItemCategory {
  String get label {
    switch (this) {
      case PlanningBoxItemCategory.location:
        return 'Location';
      case PlanningBoxItemCategory.technology:
        return 'Technik';
      case PlanningBoxItemCategory.program:
        return 'Programm';
      case PlanningBoxItemCategory.staff:
        return 'Personal';
      case PlanningBoxItemCategory.cost:
        return 'Kosten';
    }
  }
}

enum PlanningBoxItemKind {
  costPosition,
  technologyDetail,
  programDetail,
}

class PlanningBoxItem {
  final String id;
  final PlanningBoxItemCategory category;
  final PlanningBoxItemKind kind;
  final String label;
  final double amountEur;
  final String description;
  final String calculationHint;
  final String buildingBlockId;
  final String costKey;
  final String? detailItemId;
  final bool isVariable;
  final bool canEdit;
  final bool canRemove;

  const PlanningBoxItem({
    required this.id,
    required this.category,
    required this.kind,
    required this.label,
    required this.amountEur,
    this.description = '',
    this.calculationHint = '',
    this.buildingBlockId = '',
    required this.costKey,
    this.detailItemId,
    this.isVariable = false,
    this.canEdit = true,
    this.canRemove = false,
  });
}

class PlanningScenario {
  final String id;
  final String name;
  final String locationBlockId;
  final String locationName;
  final String setupName;
  final int capacity;
  final double targetOccupancyPercent;
  final double baseRentEur;
  final double variableCostPerAttendeeEur;
  final int variableCostThresholdAttendees;
  final String variableCostNote;
  final String locationNotes;

  const PlanningScenario({
    required this.id,
    required this.name,
    this.locationBlockId = '',
    required this.locationName,
    required this.setupName,
    required this.capacity,
    required this.targetOccupancyPercent,
    required this.baseRentEur,
    this.variableCostPerAttendeeEur = 0,
    this.variableCostThresholdAttendees = 0,
    this.variableCostNote = '',
    required this.locationNotes,
  });
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
