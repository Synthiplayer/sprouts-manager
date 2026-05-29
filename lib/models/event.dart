import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp importieren

class Event {
  final String eventId;
  final String kategorie;
  final String veranstaltungsname;
  final String kurzbeschreibung;
  final String? bildAsset;
  final DateTime datum;
  final String uhrzeitStart;
  final String uhrzeitEnde;
  final int altersbeschraenkung;
  final DateTime anmeldeschluss;
  final Map<String, int>
      anmeldePreise; // Einfacher Map für EarlyBird und Normal
  final int minimaleTeilnehmerzahl;
  final int maximaleTeilnehmerzahl;
  final String raumAufbau;
  final String veranstalter;
  final bool featureFlag;
  final List<String>? addons;
  final Map<String, int>? addonPreise;
  final List<String> teilnehmerliste;
  final List<String>
      eingecheckteListe; // Neues Feld für die eingecheckten Teilnehmer
  final String? langbeschreibung;
  final String? status;
  final List<Map<String, dynamic>>? bewertungen;
  bool lockedIn;

  Event({
    required this.eventId,
    required this.kategorie,
    required this.veranstaltungsname,
    required this.kurzbeschreibung,
    required this.datum,
    required this.uhrzeitStart,
    required this.uhrzeitEnde,
    required this.altersbeschraenkung,
    required this.anmeldeschluss,
    required this.anmeldePreise, // Einfacher Map für Normal und EarlyBird
    required this.minimaleTeilnehmerzahl,
    required this.maximaleTeilnehmerzahl,
    required this.raumAufbau,
    required this.veranstalter,
    required this.featureFlag,
    this.bildAsset,
    this.addons,
    this.addonPreise,
    this.langbeschreibung,
    this.status,
    this.teilnehmerliste = const [],
    this.eingecheckteListe = const [], // Standardwert als leere Liste
    this.bewertungen,
    this.lockedIn = false,
  });

  // Methode zum Konvertieren eines Event-Objekts in JSON
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'kategorie': kategorie,
      'veranstaltungsname': veranstaltungsname,
      'kurzbeschreibung': kurzbeschreibung,
      'bildAsset': bildAsset,
      'datum': datum.toIso8601String(),
      'uhrzeitStart': uhrzeitStart,
      'uhrzeitEnde': uhrzeitEnde,
      'altersbeschraenkung': altersbeschraenkung,
      'anmeldeschluss': anmeldeschluss.toIso8601String(),
      'anmeldePreise': anmeldePreise, // Einfacher Map
      'minimaleTeilnehmerzahl': minimaleTeilnehmerzahl,
      'maximaleTeilnehmerzahl': maximaleTeilnehmerzahl,
      'raumAufbau': raumAufbau,
      'veranstalter': veranstalter,
      'featureFlag': featureFlag,
      'addons': addons,
      'addonPreise': addonPreise,
      'teilnehmerliste': teilnehmerliste,
      'eingecheckteListe':
          eingecheckteListe, // Neue Liste der eingecheckten Teilnehmer
      'langbeschreibung': langbeschreibung,
      'status': status,
      'bewertungen': bewertungen,
      'lockedIn': lockedIn,
    };
  }

  // Factory-Methode zum Erstellen eines Event-Objekts aus JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'] as String? ?? '',
      kategorie: json['kategorie'] as String? ?? '',
      veranstaltungsname: json['veranstaltungsname'] as String? ?? '',
      kurzbeschreibung: json['kurzbeschreibung'] as String? ?? '',
      bildAsset: json['bildAsset'] as String?,
      datum: (json['datum'] as Timestamp).toDate(),
      anmeldeschluss: (json['anmeldeschluss'] as Timestamp).toDate(),
      uhrzeitStart: json['uhrzeitStart'] as String? ?? '',
      uhrzeitEnde: json['uhrzeitEnde'] as String? ?? '',
      altersbeschraenkung: json['altersbeschraenkung'] as int? ?? 0,
      anmeldePreise: (json['anmeldePreise'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int)),
      minimaleTeilnehmerzahl: json['minimaleTeilnehmerzahl'] as int? ?? 0,
      maximaleTeilnehmerzahl: json['maximaleTeilnehmerzahl'] as int? ?? 0,
      raumAufbau: json['raumAufbau'] as String? ?? 'Stehend',
      veranstalter: json['veranstalter'] as String? ?? '',
      featureFlag: json['featureFlag'] as bool? ?? false,
      langbeschreibung: json['langbeschreibung'] as String?,
      status: json['status'] as String?,
      teilnehmerliste: (json['teilnehmerliste'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      eingecheckteListe: (json['eingecheckteListe'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [], // Konvertiere Liste der eingecheckten Teilnehmer
      addons:
          (json['addons'] as List<dynamic>?)?.map((e) => e as String).toList(),
      addonPreise: (json['addonPreise'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)),
      bewertungen: (json['bewertungen'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      lockedIn: json['lockedIn'] as bool? ?? false,
    );
  }
}
