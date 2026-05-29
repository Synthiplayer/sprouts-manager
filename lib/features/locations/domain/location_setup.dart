import 'location_enums.dart';

class LocationSetup {
  final String id;
  final String name;
  final LocationSetupType setupType;
  final int capacity;
  final double defaultBaseRent;
  final String defaultGemaProfileId;
  final GemaEventType defaultGemaEventType;
  final String securityNote;
  final String technicalNote;
  final String seatingNote;
  final String costNote;
  final String generalNote;

  const LocationSetup({
    required this.id,
    required this.name,
    this.setupType = LocationSetupType.custom,
    this.capacity = 0,
    this.defaultBaseRent = 0,
    this.defaultGemaProfileId = '',
    this.defaultGemaEventType = GemaEventType.none,
    this.securityNote = '',
    this.technicalNote = '',
    this.seatingNote = '',
    this.costNote = '',
    this.generalNote = '',
  });

  LocationSetup copyWith({
    String? id,
    String? name,
    LocationSetupType? setupType,
    int? capacity,
    double? defaultBaseRent,
    String? defaultGemaProfileId,
    GemaEventType? defaultGemaEventType,
    String? securityNote,
    String? technicalNote,
    String? seatingNote,
    String? costNote,
    String? generalNote,
  }) {
    return LocationSetup(
      id: id ?? this.id,
      name: name ?? this.name,
      setupType: setupType ?? this.setupType,
      capacity: capacity ?? this.capacity,
      defaultBaseRent: defaultBaseRent ?? this.defaultBaseRent,
      defaultGemaProfileId: defaultGemaProfileId ?? this.defaultGemaProfileId,
      defaultGemaEventType: defaultGemaEventType ?? this.defaultGemaEventType,
      securityNote: securityNote ?? this.securityNote,
      technicalNote: technicalNote ?? this.technicalNote,
      seatingNote: seatingNote ?? this.seatingNote,
      costNote: costNote ?? this.costNote,
      generalNote: generalNote ?? this.generalNote,
    );
  }
}
