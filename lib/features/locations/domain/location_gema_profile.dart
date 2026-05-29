class LocationGemaProfile {
  final String id;
  final String areaName;
  final bool isEventArea;
  final int allowedPersons;
  final double areaSizeSqm;
  final double concertFee;
  final double partyFee;
  final double privateEventFee;
  final String notes;

  const LocationGemaProfile({
    required this.id,
    required this.areaName,
    required this.isEventArea,
    required this.allowedPersons,
    required this.areaSizeSqm,
    required this.concertFee,
    required this.partyFee,
    required this.privateEventFee,
    this.notes = '',
  });

  LocationGemaProfile copyWith({
    String? id,
    String? areaName,
    bool? isEventArea,
    int? allowedPersons,
    double? areaSizeSqm,
    double? concertFee,
    double? partyFee,
    double? privateEventFee,
    String? notes,
  }) {
    return LocationGemaProfile(
      id: id ?? this.id,
      areaName: areaName ?? this.areaName,
      isEventArea: isEventArea ?? this.isEventArea,
      allowedPersons: allowedPersons ?? this.allowedPersons,
      areaSizeSqm: areaSizeSqm ?? this.areaSizeSqm,
      concertFee: concertFee ?? this.concertFee,
      partyFee: partyFee ?? this.partyFee,
      privateEventFee: privateEventFee ?? this.privateEventFee,
      notes: notes ?? this.notes,
    );
  }
}
