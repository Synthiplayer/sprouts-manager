import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/location_gema_profile.dart';
import '../domain/location_model.dart';

final locationListProvider =
    StateNotifierProvider<LocationListNotifier, List<LocationModel>>(
  (ref) => LocationListNotifier()..loadDummyLocations(),
);

class LocationListNotifier extends StateNotifier<List<LocationModel>> {
  LocationListNotifier() : super(const []);

  void loadDummyLocations() {
    if (state.isNotEmpty) {
      return;
    }

    state = [
      LocationModel(
        id: 'loc_club_1',
        name: 'Kleine Club-Location',
        street: 'Nachtweg 8',
        zipCode: '10115',
        city: 'Berlin',
        description: 'Kleine Indoor-Location für Clubnächte und Showcases.',
        isIndoor: true,
        isOutdoor: false,
        isAccessible: false,
        standingCapacity: 120,
        seatingCapacity: 40,
        baseRent: 1200,
        revenueSharePercent: 8,
        minimumRent: 1000,
        deposit: 500,
        cleaningFee: 140,
        utilityFee: 90,
        requiresSecurity: true,
        requiresTechnicalSetup: true,
        infrastructureNote: 'Kompakte Bühne vorhanden, Lichttechnik begrenzt.',
        parkingNote: 'Nur wenige Stellplätze.',
        accessNote: 'Anlieferung über Hintereingang bis 17:00 Uhr.',
        gemaProfiles: const [
          LocationGemaProfile(
            id: 'gema_clubraum',
            areaName: 'Clubraum',
            isEventArea: true,
            allowedPersons: 120,
            areaSizeSqm: 180,
            concertFee: 180,
            partyFee: 230,
            privateEventFee: 140,
            notes: 'Hauptfläche für Gäste.',
          ),
        ],
      ),
      LocationModel(
        id: 'loc_metropol',
        name: 'Metropol',
        street: 'Metropolring 12',
        zipCode: '20095',
        city: 'Hamburg',
        description: 'Mehrbereichslocation mit dokumentierten Nebenflächen.',
        isIndoor: true,
        isOutdoor: false,
        isAccessible: true,
        standingCapacity: 850,
        seatingCapacity: 420,
        baseRent: 6400,
        revenueSharePercent: 12,
        minimumRent: 5000,
        deposit: 2500,
        cleaningFee: 550,
        utilityFee: 420,
        requiresSecurity: true,
        requiresStage: true,
        requiresTechnicalSetup: true,
        hasCateringRestriction: true,
        mixedCapacityNote: 'Flexible Bestuhlung je nach Setup.',
        infrastructureNote: 'Feste Bühne, professionelles Licht- und Tonteam optional.',
        parkingNote: 'Tiefgarage verfügbar, Höhe 2,10m.',
        accessNote: 'Rollstuhlgerechter Haupteingang vorhanden.',
        gemaProfiles: const [
          LocationGemaProfile(
            id: 'gema_saal',
            areaName: 'Saal',
            isEventArea: true,
            allowedPersons: 850,
            areaSizeSqm: 900,
            concertFee: 980,
            partyFee: 1240,
            privateEventFee: 760,
            notes: 'Einziger für Veranstaltungsgäste zugelassener Bereich.',
          ),
          LocationGemaProfile(
            id: 'gema_garderobe',
            areaName: 'Garderobe',
            isEventArea: false,
            allowedPersons: 80,
            areaSizeSqm: 90,
            concertFee: 0,
            partyFee: 0,
            privateEventFee: 0,
            notes: 'Dokumentiert, aber keine Gästefläche für Events.',
          ),
          LocationGemaProfile(
            id: 'gema_lager_1',
            areaName: 'Lagerraum 1',
            isEventArea: false,
            allowedPersons: 10,
            areaSizeSqm: 35,
            concertFee: 0,
            partyFee: 0,
            privateEventFee: 0,
            notes: 'Interner Bereich, nicht für Gäste.',
          ),
        ],
      ),
      LocationModel(
        id: 'loc_eishalle',
        name: 'Eissporthalle',
        street: 'Arenaallee 3',
        zipCode: '50667',
        city: 'Köln',
        description: 'Großlocation für saisonale Events und Sommerformate.',
        isIndoor: false,
        isOutdoor: true,
        isAccessible: true,
        standingCapacity: 3200,
        seatingCapacity: 1600,
        baseRent: 12000,
        revenueSharePercent: 15,
        minimumRent: 9000,
        deposit: 4000,
        cleaningFee: 1400,
        utilityFee: 1100,
        requiresToiletTrailer: true,
        requiresFirstAid: true,
        requiresBarriers: true,
        requiresSecurity: true,
        requiresStage: true,
        requiresTechnicalSetup: true,
        variableCostNote: 'Saisonabhängig stark schwankende Nebenkosten.',
        infrastructureNote: 'Sommerbetrieb nur mit zusätzlicher Infrastruktur.',
        parkingNote: 'Große Parkflächen für Besucher und Crew.',
        accessNote: 'Mehrere Zugänge, Crowd-Management erforderlich.',
        gemaProfiles: const [
          LocationGemaProfile(
            id: 'gema_hallenflaeche',
            areaName: 'Hallenfläche',
            isEventArea: true,
            allowedPersons: 3200,
            areaSizeSqm: 5000,
            concertFee: 2200,
            partyFee: 2800,
            privateEventFee: 1700,
            notes: 'Zentrale Gästefläche für Großevents.',
          ),
        ],
      ),
    ];
  }

  void addLocation(LocationModel location) {
    state = [...state, location];
  }

  void updateLocation(LocationModel location) {
    final index = state.indexWhere((item) => item.id == location.id);
    if (index == -1) {
      return;
    }

    final updated = [...state];
    updated[index] = location;
    state = updated;
  }

  void deleteLocation(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}
