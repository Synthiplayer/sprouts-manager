import 'location_enums.dart';
import 'location_gema_profile.dart';
import 'location_setup.dart';

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
  final int allowedCapacity;
  final CapacityMode capacityMode;

  final AssemblyVenueReviewStatus assemblyVenueReviewStatus;
  final String authorityNote;

  final bool requiresToiletTrailer;
  final bool requiresFirstAid;
  final bool requiresBarriers;
  final bool requiresStage;
  final bool requiresTechnicalSetup;
  final bool hasCateringRestriction;
  final String securityReviewNote;

  final String infrastructureNote;
  final String parkingNote;
  final String accessNote;

  final List<LocationGemaProfile> gemaProfiles;
  final List<LocationSetup> setups;

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
    this.allowedCapacity = 0,
    this.capacityMode = CapacityMode.unknown,
    this.assemblyVenueReviewStatus = AssemblyVenueReviewStatus.unclear,
    this.authorityNote = '',
    this.requiresToiletTrailer = false,
    this.requiresFirstAid = false,
    this.requiresBarriers = false,
    this.requiresStage = false,
    this.requiresTechnicalSetup = false,
    this.hasCateringRestriction = false,
    this.securityReviewNote = 'Securitybedarf je Event prüfen.',
    this.infrastructureNote = '',
    this.parkingNote = '',
    this.accessNote = '',
    this.gemaProfiles = const [],
    this.setups = const [],
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
    int? allowedCapacity,
    CapacityMode? capacityMode,
    AssemblyVenueReviewStatus? assemblyVenueReviewStatus,
    String? authorityNote,
    bool? requiresToiletTrailer,
    bool? requiresFirstAid,
    bool? requiresBarriers,
    bool? requiresStage,
    bool? requiresTechnicalSetup,
    bool? hasCateringRestriction,
    String? securityReviewNote,
    String? infrastructureNote,
    String? parkingNote,
    String? accessNote,
    List<LocationGemaProfile>? gemaProfiles,
    List<LocationSetup>? setups,
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
      allowedCapacity: allowedCapacity ?? this.allowedCapacity,
      capacityMode: capacityMode ?? this.capacityMode,
      assemblyVenueReviewStatus:
          assemblyVenueReviewStatus ?? this.assemblyVenueReviewStatus,
      authorityNote: authorityNote ?? this.authorityNote,
      requiresToiletTrailer: requiresToiletTrailer ?? this.requiresToiletTrailer,
      requiresFirstAid: requiresFirstAid ?? this.requiresFirstAid,
      requiresBarriers: requiresBarriers ?? this.requiresBarriers,
      requiresStage: requiresStage ?? this.requiresStage,
      requiresTechnicalSetup:
          requiresTechnicalSetup ?? this.requiresTechnicalSetup,
      hasCateringRestriction:
          hasCateringRestriction ?? this.hasCateringRestriction,
      securityReviewNote: securityReviewNote ?? this.securityReviewNote,
      infrastructureNote: infrastructureNote ?? this.infrastructureNote,
      parkingNote: parkingNote ?? this.parkingNote,
      accessNote: accessNote ?? this.accessNote,
      gemaProfiles: gemaProfiles ?? this.gemaProfiles,
      setups: setups ?? this.setups,
    );
  }

  List<LocationGemaProfile> get eventRelevantGemaProfiles =>
      gemaProfiles.where((profile) => profile.isEventArea).toList();
}
