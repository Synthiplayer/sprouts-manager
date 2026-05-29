import 'location_gema_profile.dart';

class LocationModel {
  final String id;
  final String name;
  final String street;
  final String zipCode;
  final String city;
  final String description;
  final bool isIndoor;
  final bool isOutdoor;
  final bool isAccessible;

  final int standingCapacity;
  final int seatingCapacity;
  final String mixedCapacityNote;

  final double baseRent;
  final double revenueSharePercent;
  final double minimumRent;
  final double deposit;
  final double cleaningFee;
  final double utilityFee;
  final String variableCostNote;

  final bool requiresToiletTrailer;
  final bool requiresFirstAid;
  final bool requiresSecurity;
  final bool requiresBarriers;
  final bool requiresStage;
  final bool requiresTechnicalSetup;
  final bool hasCateringRestriction;

  final String infrastructureNote;
  final String parkingNote;
  final String accessNote;

  final List<LocationGemaProfile> gemaProfiles;

  const LocationModel({
    required this.id,
    required this.name,
    required this.street,
    required this.zipCode,
    required this.city,
    this.description = '',
    this.isIndoor = true,
    this.isOutdoor = false,
    this.isAccessible = false,
    this.standingCapacity = 0,
    this.seatingCapacity = 0,
    this.mixedCapacityNote = '',
    this.baseRent = 0,
    this.revenueSharePercent = 0,
    this.minimumRent = 0,
    this.deposit = 0,
    this.cleaningFee = 0,
    this.utilityFee = 0,
    this.variableCostNote = '',
    this.requiresToiletTrailer = false,
    this.requiresFirstAid = false,
    this.requiresSecurity = false,
    this.requiresBarriers = false,
    this.requiresStage = false,
    this.requiresTechnicalSetup = false,
    this.hasCateringRestriction = false,
    this.infrastructureNote = '',
    this.parkingNote = '',
    this.accessNote = '',
    this.gemaProfiles = const [],
  });

  LocationModel copyWith({
    String? id,
    String? name,
    String? street,
    String? zipCode,
    String? city,
    String? description,
    bool? isIndoor,
    bool? isOutdoor,
    bool? isAccessible,
    int? standingCapacity,
    int? seatingCapacity,
    String? mixedCapacityNote,
    double? baseRent,
    double? revenueSharePercent,
    double? minimumRent,
    double? deposit,
    double? cleaningFee,
    double? utilityFee,
    String? variableCostNote,
    bool? requiresToiletTrailer,
    bool? requiresFirstAid,
    bool? requiresSecurity,
    bool? requiresBarriers,
    bool? requiresStage,
    bool? requiresTechnicalSetup,
    bool? hasCateringRestriction,
    String? infrastructureNote,
    String? parkingNote,
    String? accessNote,
    List<LocationGemaProfile>? gemaProfiles,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      description: description ?? this.description,
      isIndoor: isIndoor ?? this.isIndoor,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      isAccessible: isAccessible ?? this.isAccessible,
      standingCapacity: standingCapacity ?? this.standingCapacity,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      mixedCapacityNote: mixedCapacityNote ?? this.mixedCapacityNote,
      baseRent: baseRent ?? this.baseRent,
      revenueSharePercent: revenueSharePercent ?? this.revenueSharePercent,
      minimumRent: minimumRent ?? this.minimumRent,
      deposit: deposit ?? this.deposit,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      utilityFee: utilityFee ?? this.utilityFee,
      variableCostNote: variableCostNote ?? this.variableCostNote,
      requiresToiletTrailer: requiresToiletTrailer ?? this.requiresToiletTrailer,
      requiresFirstAid: requiresFirstAid ?? this.requiresFirstAid,
      requiresSecurity: requiresSecurity ?? this.requiresSecurity,
      requiresBarriers: requiresBarriers ?? this.requiresBarriers,
      requiresStage: requiresStage ?? this.requiresStage,
      requiresTechnicalSetup: requiresTechnicalSetup ?? this.requiresTechnicalSetup,
      hasCateringRestriction: hasCateringRestriction ?? this.hasCateringRestriction,
      infrastructureNote: infrastructureNote ?? this.infrastructureNote,
      parkingNote: parkingNote ?? this.parkingNote,
      accessNote: accessNote ?? this.accessNote,
      gemaProfiles: gemaProfiles ?? this.gemaProfiles,
    );
  }

  List<LocationGemaProfile> get eventRelevantGemaProfiles =>
      gemaProfiles.where((profile) => profile.isEventArea).toList();
}
