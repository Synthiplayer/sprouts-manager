import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprouts_manager/models/event.dart';

import '../domain/event_calculation_model.dart';

final eventCalculationProvider =
    StateNotifierProvider<EventCalculationNotifier, EventCalculationModel>(
  (ref) => EventCalculationNotifier(),
);

final eventCalculationPreviewProvider =
    Provider.family<EventCalculationModel, Event>(
  (ref, event) => EventCalculationNotifier.buildDraftForEvent(event),
);

class EventCalculationNotifier extends StateNotifier<EventCalculationModel> {
  EventCalculationNotifier() : super(const EventCalculationModel());

  static EventCalculationModel buildDraftForEvent(Event event) {
    final normalPrice = event.anmeldePreise['Normal'] ?? 0;
    final earlyBirdPrice = event.anmeldePreise['EarlyBird'] ?? 0;
    final currentParticipants = event.teilnehmerliste.length;
    final isParty = event.category.name == 'party';
    final isKids = event.category.name == 'kids';
    final expectedParticipants = max(
      event.minimaleTeilnehmerzahl,
      max(
        currentParticipants,
        min(event.maximaleTeilnehmerzahl, currentParticipants + 40),
      ),
    );
    final expectedEarlyBirdTickets = earlyBirdPrice > 0
        ? min(expectedParticipants, max(0, (expectedParticipants * 0.35).round()))
        : 0;
    final expectedRegularTickets =
        max(0, expectedParticipants - expectedEarlyBirdTickets);

    return EventCalculationModel(
      id: 'calc_${event.eventId}',
      eventId: event.eventId,
      title: event.veranstaltungsname,
      calculationStatus: event.lockedIn
          ? CalculationStatus.lockedIn
          : event.hasReachedBreakEven
              ? CalculationStatus.breakEvenReached
              : CalculationStatus.draft,
      expectedParticipants: expectedParticipants,
      minParticipants: event.minimaleTeilnehmerzahl,
      maxParticipants: event.maximaleTeilnehmerzahl,
      normalTicketPriceEvc: normalPrice,
      earlyBirdTicketPriceEvc: earlyBirdPrice,
      expectedEarlyBirdTickets: expectedEarlyBirdTickets,
      expectedRegularTickets: expectedRegularTickets,
      sponsorAmountEur: isParty ? 350 : 500,
      grantAmountEur: isKids ? 450 : 0,
      costItems: _buildDraftCostItems(event),
      upgradeBudgetItems: _buildUpgradeBudgetItems(event),
      reservePercent: 8,
      evcRefundPercent: 10,
      guestValuePercent: 60,
      organizerMarginPercent: 12,
      notes:
          'Sandbox-Vorschau auf Basis der aktuellen Eventstammdaten. Nachkalkulation und Kassenlogik folgen später separat.',
    );
  }

  static List<CalculationCostItem> _buildDraftCostItems(Event event) {
    final participantBase = max(event.minimaleTeilnehmerzahl, 1);
    final isConcert = event.category.name == 'concert';
    final isParty = event.category.name == 'party';
    final isMovie = event.category.name == 'movie';
    final isKids = event.category.name == 'kids';

    return [
      CalculationCostItem(
        id: '${event.eventId}_location',
        category: CostCategory.location,
        label: 'Location / Halle',
        quantity: 1,
        unitNetEur: isConcert ? 2200 : 1800,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_artist',
        category: isParty ? CostCategory.dj : CostCategory.artist,
        label: isParty ? 'DJ / Headliner' : 'Künstlergagen',
        quantity: 1,
        unitNetEur: isMovie ? 450 : (isConcert ? 2600 : 1400),
        taxRate: 0.07,
      ),
      CalculationCostItem(
        id: '${event.eventId}_sound',
        category: CostCategory.sound,
        label: 'Tonanlage',
        quantity: 1,
        unitNetEur: isConcert ? 950 : 600,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_light',
        category: CostCategory.light,
        label: 'Lichttechnik',
        quantity: 1,
        unitNetEur: isMovie ? 180 : 520,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_security',
        category: CostCategory.security,
        label: 'Security',
        quantity: isKids ? 1 : max(1, (participantBase / 120).ceil()).toDouble(),
        unitNetEur: 180,
        taxRate: 0.19,
        note: 'Je nach Besucherzahl und Auflage prüfen.',
      ),
      CalculationCostItem(
        id: '${event.eventId}_staff',
        category: CostCategory.staff,
        label: 'Eventpersonal',
        quantity: max(2, (participantBase / 90).ceil()).toDouble(),
        unitNetEur: 95,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_gema',
        category: CostCategory.gema,
        label: 'GEMA / Lizenz',
        quantity: 1,
        unitNetEur: isMovie ? 160 : 320,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_advertising',
        category: CostCategory.advertising,
        label: 'Werbung',
        quantity: 1,
        unitNetEur: isKids ? 220 : 350,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_ticketing',
        category: CostCategory.ticketing,
        label: 'Ticketing / Vorverkauf',
        quantity: 1,
        unitNetEur: 120,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_insurance',
        category: CostCategory.insurance,
        label: 'Versicherung',
        quantity: 1,
        unitNetEur: 210,
        taxRate: 0.19,
      ),
      CalculationCostItem(
        id: '${event.eventId}_materials',
        category: CostCategory.materials,
        label: 'Verbrauchsmaterial',
        quantity: 1,
        unitNetEur: 140,
        taxRate: 0.19,
      ),
    ];
  }

  static List<UpgradeBudgetItem> _buildUpgradeBudgetItems(Event event) {
    return [
      UpgradeBudgetItem(
        id: '${event.eventId}_show_upgrade',
        category: UpgradeBudgetCategory.showUpgrade,
        label: 'Zusätzliche Showeffekte',
        estimatedCostEur: 450,
        priority: 1,
        isGuestValueItem: true,
      ),
      UpgradeBudgetItem(
        id: '${event.eventId}_sound_upgrade',
        category: UpgradeBudgetCategory.soundUpgrade,
        label: 'Bessere Tonanlage',
        estimatedCostEur: 380,
        priority: 2,
        isGuestValueItem: true,
      ),
      UpgradeBudgetItem(
        id: '${event.eventId}_guest_bonus',
        category: UpgradeBudgetCategory.guestBonus,
        label: 'Gastbonus / Freigetränk',
        estimatedCostEur: 250,
        priority: 3,
        isGuestValueItem: true,
      ),
      UpgradeBudgetItem(
        id: '${event.eventId}_reserve',
        category: UpgradeBudgetCategory.reserve,
        label: 'Risiko- und Sicherheitsrücklage',
        estimatedCostEur: 300,
        priority: 1,
        isGuestValueItem: false,
      ),
      UpgradeBudgetItem(
        id: '${event.eventId}_refund',
        category: UpgradeBudgetCategory.evcRefund,
        label: 'Teilweise Eventcoin-Erstattung',
        estimatedCostEur: 200,
        priority: 4,
        isGuestValueItem: true,
      ),
    ];
  }

  void replaceCalculation(EventCalculationModel value) {
    state = value;
  }

  void updateArtistCost(double value) {
    _upsertCostItem(
      id: 'manual_artist',
      category: CostCategory.artist,
      label: 'Künstler / DJ / Band',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.07,
    );
  }

  void updateLocationCost(double value) {
    _upsertCostItem(
      id: 'manual_location',
      category: CostCategory.location,
      label: 'Location',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateTechnologyCost(double value) {
    _upsertCostItem(
      id: 'manual_technology',
      category: CostCategory.sound,
      label: 'Technik',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateSecurityCost(double value) {
    _upsertCostItem(
      id: 'manual_security',
      category: CostCategory.security,
      label: 'Security',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateStaffCost(double value) {
    _upsertCostItem(
      id: 'manual_staff',
      category: CostCategory.staff,
      label: 'Personal',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateLicenseCost(double value) {
    _upsertCostItem(
      id: 'manual_license',
      category: CostCategory.gema,
      label: 'GEMA / Lizenz',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateMarketingCost(double value) {
    _upsertCostItem(
      id: 'manual_marketing',
      category: CostCategory.advertising,
      label: 'Werbung',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateInsuranceCost(double value) {
    _upsertCostItem(
      id: 'manual_insurance',
      category: CostCategory.insurance,
      label: 'Versicherung',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateOtherCosts(double value) {
    _upsertCostItem(
      id: 'manual_other',
      category: CostCategory.other,
      label: 'Sonstige Kosten',
      quantity: 1,
      unitNetEur: value,
      taxRate: 0.19,
    );
  }

  void updateEarlyBirdPrice(double value) =>
      state = state.copyWith(earlyBirdTicketPriceEvc: value.round());

  void updateNormalPrice(double value) =>
      state = state.copyWith(normalTicketPriceEvc: value.round());

  void updateExpectedParticipants(int value) {
    final safeValue = max(0, value);
    final earlyBirdTickets = min(state.expectedEarlyBirdTickets, safeValue);
    state = state.copyWith(
      expectedParticipants: safeValue,
      expectedRegularTickets: max(0, safeValue - earlyBirdTickets),
    );
  }

  void updateMaxParticipants(int value) =>
      state = state.copyWith(maxParticipants: max(0, value));

  void updateSponsorContribution(double value) =>
      state = state.copyWith(sponsorAmountEur: max(0, value));

  void updateFreeTickets(int value) {
    final safeValue = max(0, value);
    final remaining = max(0, state.expectedParticipants - safeValue);
    state = state.copyWith(
      expectedEarlyBirdTickets: 0,
      expectedRegularTickets: remaining,
    );
  }

  double get totalCosts => state.currentCostGrossEur;

  int get payingParticipants => state.expectedTicketCount;

  int get expectedRevenue => state.expectedRevenueEvc;

  double get expectedRevenueEur => state.expectedRevenueEur;

  int get breakEvenParticipants => state.breakEvenParticipants;

  int get suggestedMinimumParticipants =>
      max(state.minParticipants, state.breakEvenParticipants);

  double get expectedBalance => state.expectedRevenueEur - state.amountToCoverEur;

  String get riskHint {
    if (state.averageTicketValueEur <= 0 || state.expectedParticipants <= 0) {
      return 'Risiko hoch: Preise und Teilnehmerplanung prüfen.';
    }
    if (state.maxParticipants > 0 &&
        state.breakEvenParticipants > state.maxParticipants) {
      return 'Risiko hoch: Break-even liegt über der geplanten Kapazität.';
    }
    if (expectedBalance < 0) {
      return 'Risiko mittel bis hoch: Deckungslücke vor Break-even sichtbar.';
    }
    if (state.upgradeBudgetAfterBreakEvenEur > 0) {
      return 'Spielraum vorhanden: Überschüsse können als Upgrade-Budget genutzt werden.';
    }
    return 'Planung stabil: Break-even ist erreichbar, weitere Reserven prüfen.';
  }

  void _upsertCostItem({
    required String id,
    required CostCategory category,
    required String label,
    required double quantity,
    required double unitNetEur,
    required double taxRate,
  }) {
    final items = [...state.costItems];
    final index = items.indexWhere((item) => item.id == id);
    final item = CalculationCostItem(
      id: id,
      category: category,
      label: label,
      quantity: quantity,
      unitNetEur: unitNetEur,
      taxRate: taxRate,
    );

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    state = state.copyWith(costItems: items);
  }
}
