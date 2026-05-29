import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/event_calculation_model.dart';

final eventCalculationProvider =
    StateNotifierProvider<EventCalculationNotifier, EventCalculationModel>(
  (ref) => EventCalculationNotifier(),
);

class EventCalculationNotifier extends StateNotifier<EventCalculationModel> {
  EventCalculationNotifier() : super(const EventCalculationModel());

  void updateArtistCost(double value) => state = state.copyWith(artistCost: value);
  void updateLocationCost(double value) => state = state.copyWith(locationCost: value);
  void updateTechnologyCost(double value) => state = state.copyWith(technologyCost: value);
  void updateSecurityCost(double value) => state = state.copyWith(securityCost: value);
  void updateStaffCost(double value) => state = state.copyWith(staffCost: value);
  void updateLicenseCost(double value) => state = state.copyWith(licenseCost: value);
  void updateMarketingCost(double value) => state = state.copyWith(marketingCost: value);
  void updateInsuranceCost(double value) => state = state.copyWith(insuranceCost: value);
  void updateOtherCosts(double value) => state = state.copyWith(otherCosts: value);
  void updateEarlyBirdPrice(double value) => state = state.copyWith(earlyBirdPriceEvc: value);
  void updateNormalPrice(double value) => state = state.copyWith(normalPriceEvc: value);
  void updateExpectedParticipants(int value) =>
      state = state.copyWith(expectedParticipants: value);
  void updateMaxParticipants(int value) => state = state.copyWith(maxParticipants: value);
  void updateSponsorContribution(double value) =>
      state = state.copyWith(sponsorContribution: value);
  void updateFreeTickets(int value) => state = state.copyWith(freeTickets: value);

  double get totalCosts {
    final gross = state.artistCost +
        state.locationCost +
        state.technologyCost +
        state.securityCost +
        state.staffCost +
        state.licenseCost +
        state.marketingCost +
        state.insuranceCost +
        state.otherCosts;
    return max(0, gross - state.sponsorContribution);
  }

  int get payingParticipants => max(0, state.expectedParticipants - state.freeTickets);

  double get expectedRevenue => payingParticipants * state.normalPriceEvc;

  int get breakEvenParticipants {
    if (state.normalPriceEvc <= 0) {
      return 0;
    }
    return (totalCosts / state.normalPriceEvc).ceil();
  }

  int get suggestedMinimumParticipants => breakEvenParticipants;

  double get expectedBalance => expectedRevenue - totalCosts;

  String get riskHint {
    if (state.normalPriceEvc <= 0 || state.expectedParticipants <= 0) {
      return 'Risiko hoch: Preise und Teilnehmerplanung prüfen.';
    }
    if (expectedBalance >= 0) {
      return 'Risiko gering bis mittel: Planung aktuell positiv.';
    }
    if (state.maxParticipants > 0 && breakEvenParticipants > state.maxParticipants) {
      return 'Risiko hoch: Break-even liegt über maximalen Teilnehmern.';
    }
    return 'Risiko mittel bis hoch: erwarteter Fehlbetrag, Parameter anpassen.';
  }
}
