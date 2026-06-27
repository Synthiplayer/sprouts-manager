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
        return 'Sanitäter';
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
        return 'Sanitäter';
      case PlanningStaffingCategory.staff:
        return 'Personal';
    }
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
  final List<PlanningTechnologyCostItem> technologyCostItems;
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

enum PlanningArtistCostType {
  mainActFee,
  supportActFee,
  djFee,
  travel,
  hotel,
  backstage,
  catering,
  shuttle,
  filmLicense,
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
      case PlanningArtistCostType.filmLicense:
        return 'Film / Lizenz';
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
  final String note;

  const PlanningTechnologyCostItem({
    required this.id,
    required this.label,
    required this.type,
    required this.quantity,
    required this.grossUnitAmountEur,
    this.note = '',
  });

  double get grossTotalEur => quantity * grossUnitAmountEur;

  PlanningTechnologyCostItem copyWith({
    String? label,
    PlanningTechnologyCostType? type,
    int? quantity,
    double? grossUnitAmountEur,
    String? note,
  }) {
    return PlanningTechnologyCostItem(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      grossUnitAmountEur: grossUnitAmountEur ?? this.grossUnitAmountEur,
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
