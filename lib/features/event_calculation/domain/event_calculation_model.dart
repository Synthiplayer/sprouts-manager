class EventCalculationModel {
  final double artistCost;
  final double locationCost;
  final double technologyCost;
  final double securityCost;
  final double staffCost;
  final double licenseCost;
  final double marketingCost;
  final double insuranceCost;
  final double otherCosts;

  final double earlyBirdPriceEvc;
  final double normalPriceEvc;
  final int expectedParticipants;
  final int maxParticipants;
  final double sponsorContribution;
  final int freeTickets;

  const EventCalculationModel({
    this.artistCost = 0,
    this.locationCost = 0,
    this.technologyCost = 0,
    this.securityCost = 0,
    this.staffCost = 0,
    this.licenseCost = 0,
    this.marketingCost = 0,
    this.insuranceCost = 0,
    this.otherCosts = 0,
    this.earlyBirdPriceEvc = 0,
    this.normalPriceEvc = 0,
    this.expectedParticipants = 0,
    this.maxParticipants = 0,
    this.sponsorContribution = 0,
    this.freeTickets = 0,
  });

  EventCalculationModel copyWith({
    double? artistCost,
    double? locationCost,
    double? technologyCost,
    double? securityCost,
    double? staffCost,
    double? licenseCost,
    double? marketingCost,
    double? insuranceCost,
    double? otherCosts,
    double? earlyBirdPriceEvc,
    double? normalPriceEvc,
    int? expectedParticipants,
    int? maxParticipants,
    double? sponsorContribution,
    int? freeTickets,
  }) {
    return EventCalculationModel(
      artistCost: artistCost ?? this.artistCost,
      locationCost: locationCost ?? this.locationCost,
      technologyCost: technologyCost ?? this.technologyCost,
      securityCost: securityCost ?? this.securityCost,
      staffCost: staffCost ?? this.staffCost,
      licenseCost: licenseCost ?? this.licenseCost,
      marketingCost: marketingCost ?? this.marketingCost,
      insuranceCost: insuranceCost ?? this.insuranceCost,
      otherCosts: otherCosts ?? this.otherCosts,
      earlyBirdPriceEvc: earlyBirdPriceEvc ?? this.earlyBirdPriceEvc,
      normalPriceEvc: normalPriceEvc ?? this.normalPriceEvc,
      expectedParticipants: expectedParticipants ?? this.expectedParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      sponsorContribution: sponsorContribution ?? this.sponsorContribution,
      freeTickets: freeTickets ?? this.freeTickets,
    );
  }
}
