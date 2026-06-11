import 'package:sprouts_manager/core/event_currency_config.dart';

enum CalculationStatus {
  draft,
  inReview,
  breakEvenReached,
  lockedIn,
  completed,
}

extension CalculationStatusX on CalculationStatus {
  String get label {
    switch (this) {
      case CalculationStatus.draft:
        return 'Entwurf';
      case CalculationStatus.inReview:
        return 'In Prüfung';
      case CalculationStatus.breakEvenReached:
        return 'Break-even erreicht';
      case CalculationStatus.lockedIn:
        return 'Locked-in';
      case CalculationStatus.completed:
        return 'Abgeschlossen';
    }
  }
}

enum CostCategory {
  location,
  artist,
  supportAct,
  dj,
  stage,
  sound,
  light,
  showEffects,
  technician,
  security,
  medical,
  barriers,
  toilets,
  gema,
  insurance,
  advertising,
  printing,
  ticketing,
  wristbands,
  staff,
  catering,
  hospitality,
  travel,
  hotel,
  cleaning,
  waste,
  office,
  software,
  materials,
  ownWork,
  other,
}

extension CostCategoryX on CostCategory {
  String get label {
    switch (this) {
      case CostCategory.location:
        return 'Location';
      case CostCategory.artist:
        return 'Künstler';
      case CostCategory.supportAct:
        return 'Support-Act';
      case CostCategory.dj:
        return 'DJ';
      case CostCategory.stage:
        return 'Bühne';
      case CostCategory.sound:
        return 'Ton';
      case CostCategory.light:
        return 'Licht';
      case CostCategory.showEffects:
        return 'Showeffekte';
      case CostCategory.technician:
        return 'Technikpersonal';
      case CostCategory.security:
        return 'Security';
      case CostCategory.medical:
        return 'Sanitätsdienst';
      case CostCategory.barriers:
        return 'Absperrungen';
      case CostCategory.toilets:
        return 'Toiletten';
      case CostCategory.gema:
        return 'GEMA';
      case CostCategory.insurance:
        return 'Versicherung';
      case CostCategory.advertising:
        return 'Werbung';
      case CostCategory.printing:
        return 'Druck';
      case CostCategory.ticketing:
        return 'Ticketsystem';
      case CostCategory.wristbands:
        return 'Armbänder';
      case CostCategory.staff:
        return 'Personal';
      case CostCategory.catering:
        return 'Catering';
      case CostCategory.hospitality:
        return 'Hospitality';
      case CostCategory.travel:
        return 'Reise';
      case CostCategory.hotel:
        return 'Hotel';
      case CostCategory.cleaning:
        return 'Reinigung';
      case CostCategory.waste:
        return 'Entsorgung';
      case CostCategory.office:
        return 'Büro';
      case CostCategory.software:
        return 'Software';
      case CostCategory.materials:
        return 'Material';
      case CostCategory.ownWork:
        return 'Eigenleistung';
      case CostCategory.other:
        return 'Sonstiges';
    }
  }
}

enum UpgradeBudgetCategory {
  showUpgrade,
  soundUpgrade,
  lightUpgrade,
  decoration,
  freeDrinks,
  supportAct,
  guestBonus,
  evcRefund,
  reserve,
  organizerMargin,
  other,
}

extension UpgradeBudgetCategoryX on UpgradeBudgetCategory {
  String get label {
    switch (this) {
      case UpgradeBudgetCategory.showUpgrade:
        return 'Show-Upgrade';
      case UpgradeBudgetCategory.soundUpgrade:
        return 'Ton-Upgrade';
      case UpgradeBudgetCategory.lightUpgrade:
        return 'Licht-Upgrade';
      case UpgradeBudgetCategory.decoration:
        return 'Dekoration';
      case UpgradeBudgetCategory.freeDrinks:
        return 'Freigetränke';
      case UpgradeBudgetCategory.supportAct:
        return 'Zusätzlicher Support-Act';
      case UpgradeBudgetCategory.guestBonus:
        return 'Gastbonus';
      case UpgradeBudgetCategory.evcRefund:
        return 'Eventcoin-Erstattung';
      case UpgradeBudgetCategory.reserve:
        return 'Rücklage';
      case UpgradeBudgetCategory.organizerMargin:
        return 'Veranstalter-Marge';
      case UpgradeBudgetCategory.other:
        return 'Sonstiges';
    }
  }
}

class CalculationCostItem {
  final String id;
  final CostCategory category;
  final String label;
  final double quantity;
  final double unitNetEur;
  final double taxRate;
  final bool isRequiredForBreakEven;
  final String note;

  const CalculationCostItem({
    required this.id,
    required this.category,
    required this.label,
    required this.quantity,
    required this.unitNetEur,
    required this.taxRate,
    this.isRequiredForBreakEven = true,
    this.note = '',
  });

  double get netTotalEur => quantity * unitNetEur;
  double get taxAmountEur => netTotalEur * taxRate;
  double get grossTotalEur => netTotalEur + taxAmountEur;
  int get netTotalCents => EventCurrencyConfig.eurToCents(netTotalEur);
  int get taxAmountCents => EventCurrencyConfig.eurToCents(taxAmountEur);
  int get grossTotalCents => EventCurrencyConfig.eurToCents(grossTotalEur);

  CalculationCostItem copyWith({
    String? id,
    CostCategory? category,
    String? label,
    double? quantity,
    double? unitNetEur,
    double? taxRate,
    bool? isRequiredForBreakEven,
    String? note,
  }) {
    return CalculationCostItem(
      id: id ?? this.id,
      category: category ?? this.category,
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      unitNetEur: unitNetEur ?? this.unitNetEur,
      taxRate: taxRate ?? this.taxRate,
      isRequiredForBreakEven: isRequiredForBreakEven ?? this.isRequiredForBreakEven,
      note: note ?? this.note,
    );
  }
}

class UpgradeBudgetItem {
  final String id;
  final UpgradeBudgetCategory category;
  final String label;
  final double estimatedCostEur;
  final int priority;
  final bool isGuestValueItem;
  final String note;

  const UpgradeBudgetItem({
    required this.id,
    required this.category,
    required this.label,
    required this.estimatedCostEur,
    required this.priority,
    this.isGuestValueItem = true,
    this.note = '',
  });

  UpgradeBudgetItem copyWith({
    String? id,
    UpgradeBudgetCategory? category,
    String? label,
    double? estimatedCostEur,
    int? priority,
    bool? isGuestValueItem,
    String? note,
  }) {
    return UpgradeBudgetItem(
      id: id ?? this.id,
      category: category ?? this.category,
      label: label ?? this.label,
      estimatedCostEur: estimatedCostEur ?? this.estimatedCostEur,
      priority: priority ?? this.priority,
      isGuestValueItem: isGuestValueItem ?? this.isGuestValueItem,
      note: note ?? this.note,
    );
  }
}

class EventCalculationModel {
  final String id;
  final String eventId;
  final String title;
  final CalculationStatus calculationStatus;
  final int expectedParticipants;
  final int minParticipants;
  final int maxParticipants;
  final int normalTicketPriceEvc;
  final int earlyBirdTicketPriceEvc;
  final int expectedEarlyBirdTickets;
  final int expectedRegularTickets;
  final double sponsorAmountEur;
  final double grantAmountEur;
  final List<CalculationCostItem> costItems;
  final List<UpgradeBudgetItem> upgradeBudgetItems;
  final double reservePercent;
  final double evcRefundPercent;
  final double guestValuePercent;
  final double organizerMarginPercent;
  final String notes;

  const EventCalculationModel({
    this.id = '',
    this.eventId = '',
    this.title = '',
    this.calculationStatus = CalculationStatus.draft,
    this.expectedParticipants = 0,
    this.minParticipants = 0,
    this.maxParticipants = 0,
    this.normalTicketPriceEvc = 0,
    this.earlyBirdTicketPriceEvc = 0,
    this.expectedEarlyBirdTickets = 0,
    this.expectedRegularTickets = 0,
    this.sponsorAmountEur = 0,
    this.grantAmountEur = 0,
    this.costItems = const [],
    this.upgradeBudgetItems = const [],
    this.reservePercent = 0,
    this.evcRefundPercent = 0,
    this.guestValuePercent = 0,
    this.organizerMarginPercent = 0,
    this.notes = '',
  });

  int get evcToEurCentsRate => EventCurrencyConfig.centsPerEvc;
  double get evcToEurRate => EventCurrencyConfig.eurPerEvc;

  int get expectedTicketCount => expectedEarlyBirdTickets + expectedRegularTickets;

  int get normalTicketValueCents =>
      EventCurrencyConfig.evcToCents(normalTicketPriceEvc);

  int get earlyBirdTicketValueCents =>
      EventCurrencyConfig.evcToCents(earlyBirdTicketPriceEvc);

  double get normalTicketValueEur =>
      EventCurrencyConfig.centsToEur(normalTicketValueCents);

  double get earlyBirdTicketValueEur =>
      EventCurrencyConfig.centsToEur(earlyBirdTicketValueCents);

  double get averageTicketPriceEvc {
    if (expectedTicketCount <= 0) {
      return normalTicketPriceEvc.toDouble();
    }

    final weightedRevenue = (expectedEarlyBirdTickets * earlyBirdTicketPriceEvc) +
        (expectedRegularTickets * normalTicketPriceEvc);
    return weightedRevenue / expectedTicketCount;
  }

  int get averageTicketValueCents {
    if (expectedTicketCount <= 0) {
      return normalTicketValueCents;
    }

    final weightedRevenue = (expectedEarlyBirdTickets * earlyBirdTicketValueCents) +
        (expectedRegularTickets * normalTicketValueCents);
    return (weightedRevenue / expectedTicketCount).round();
  }

  double get averageTicketValueEur =>
      EventCurrencyConfig.centsToEur(averageTicketValueCents);

  double get currentCostNetEur =>
      costItems.fold(0, (sum, item) => sum + item.netTotalEur);

  double get currentCostTaxEur =>
      costItems.fold(0, (sum, item) => sum + item.taxAmountEur);

  double get currentCostGrossEur =>
      costItems.fold(0, (sum, item) => sum + item.grossTotalEur);

  int get currentCostNetCents =>
      costItems.fold(0, (sum, item) => sum + item.netTotalCents);

  int get currentCostTaxCents =>
      costItems.fold(0, (sum, item) => sum + item.taxAmountCents);

  int get currentCostGrossCents =>
      costItems.fold(0, (sum, item) => sum + item.grossTotalCents);

  double get baseCostGrossEur =>
      EventCurrencyConfig.centsToEur(baseCostGrossCents);

  int get baseCostGrossCents => costItems
      .where((item) => item.isRequiredForBreakEven)
      .fold(0, (sum, item) => sum + item.grossTotalCents);

  double get sponsorAndGrantTotalEur => sponsorAmountEur + grantAmountEur;

  int get sponsorAndGrantTotalCents =>
      EventCurrencyConfig.eurToCents(sponsorAndGrantTotalEur);

  double get amountToCoverEur =>
      EventCurrencyConfig.centsToEur(amountToCoverCents);

  int get amountToCoverCents {
    final result = baseCostGrossCents - sponsorAndGrantTotalCents;
    return result < 0 ? 0 : result;
  }

  int get breakEvenParticipants {
    if (averageTicketValueEur <= 0) {
      return 0;
    }

    return (amountToCoverEur / averageTicketValueEur).ceil();
  }

  int get expectedRevenueEvc =>
      (expectedEarlyBirdTickets * earlyBirdTicketPriceEvc) +
      (expectedRegularTickets * normalTicketPriceEvc);

  int get expectedRevenueCents =>
      (expectedEarlyBirdTickets * earlyBirdTicketValueCents) +
      (expectedRegularTickets * normalTicketValueCents);

  double get expectedRevenueEur =>
      EventCurrencyConfig.centsToEur(expectedRevenueCents);

  double get fullCapacityRevenueEvc {
    final capacity = maxParticipants > 0 ? maxParticipants : expectedParticipants;
    return capacity * averageTicketPriceEvc;
  }

  int get fullCapacityRevenueCents {
    final capacity = maxParticipants > 0 ? maxParticipants : expectedParticipants;
    return capacity * averageTicketValueCents;
  }

  double get fullCapacityRevenueEur =>
      EventCurrencyConfig.centsToEur(fullCapacityRevenueCents);

  int get revenueAboveBreakEvenCents {
    final result = expectedRevenueCents - EventCurrencyConfig.eurToCents(amountToCoverEur);
    return result < 0 ? 0 : result;
  }

  double get revenueAboveBreakEvenEur =>
      expectedRevenueEur - amountToCoverEur < 0 ? 0 : expectedRevenueEur - amountToCoverEur;

  int get upgradeBudgetAfterBreakEvenCents => revenueAboveBreakEvenCents;

  double get upgradeBudgetAfterBreakEvenEur =>
      EventCurrencyConfig.centsToEur(upgradeBudgetAfterBreakEvenCents);

  EventCalculationModel copyWith({
    String? id,
    String? eventId,
    String? title,
    CalculationStatus? calculationStatus,
    int? expectedParticipants,
    int? minParticipants,
    int? maxParticipants,
    int? normalTicketPriceEvc,
    int? earlyBirdTicketPriceEvc,
    int? expectedEarlyBirdTickets,
    int? expectedRegularTickets,
    double? sponsorAmountEur,
    double? grantAmountEur,
    List<CalculationCostItem>? costItems,
    List<UpgradeBudgetItem>? upgradeBudgetItems,
    double? reservePercent,
    double? evcRefundPercent,
    double? guestValuePercent,
    double? organizerMarginPercent,
    String? notes,
  }) {
    return EventCalculationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      calculationStatus: calculationStatus ?? this.calculationStatus,
      expectedParticipants: expectedParticipants ?? this.expectedParticipants,
      minParticipants: minParticipants ?? this.minParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      normalTicketPriceEvc: normalTicketPriceEvc ?? this.normalTicketPriceEvc,
      earlyBirdTicketPriceEvc: earlyBirdTicketPriceEvc ?? this.earlyBirdTicketPriceEvc,
      expectedEarlyBirdTickets:
          expectedEarlyBirdTickets ?? this.expectedEarlyBirdTickets,
      expectedRegularTickets: expectedRegularTickets ?? this.expectedRegularTickets,
      sponsorAmountEur: sponsorAmountEur ?? this.sponsorAmountEur,
      grantAmountEur: grantAmountEur ?? this.grantAmountEur,
      costItems: costItems ?? this.costItems,
      upgradeBudgetItems: upgradeBudgetItems ?? this.upgradeBudgetItems,
      reservePercent: reservePercent ?? this.reservePercent,
      evcRefundPercent: evcRefundPercent ?? this.evcRefundPercent,
      guestValuePercent: guestValuePercent ?? this.guestValuePercent,
      organizerMarginPercent:
          organizerMarginPercent ?? this.organizerMarginPercent,
      notes: notes ?? this.notes,
    );
  }
}
