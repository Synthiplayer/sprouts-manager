import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/visited_event.dart';

class BenutzerDaten {
  String id;
  String vorname;
  String nachname;
  String telefonnummer;
  String geschlecht;
  String? email;
  String? profilbildUrl;
  DateTime geburtsdatum; // Als required markiert
  String adresse; // Als required markiert
  String? rechnungsadresse; // Optional gemacht
  List<String>? bevorzugteBezahlmethoden;
  List<String>? favorisierteEventkategorien;
  bool benachrichtigungenZulassen; // Optional
  int? eventCoins; // Optional
  List<String>? teilgenommeneEvents; // Optional
  bool nameInTeilnehmerListeVerstecken;
  List<VisitedEvent> visitedEvents; // Optional

  BenutzerDaten({
    required this.id,
    required this.vorname,
    required this.nachname,
    required this.telefonnummer,
    required this.geschlecht,
    this.email,
    this.profilbildUrl,
    DateTime? geburtsdatum, // Geburtsdatum als nullable
    required this.adresse,
    this.rechnungsadresse,
    this.bevorzugteBezahlmethoden,
    this.favorisierteEventkategorien,
    this.benachrichtigungenZulassen = true,
    this.eventCoins,
    this.teilgenommeneEvents,
    this.visitedEvents = const [],
    this.nameInTeilnehmerListeVerstecken = false,
  }) : geburtsdatum = geburtsdatum ?? DateTime.now(); // Standardwert gesetzt

  // Factory Methode für den JSON Import
  factory BenutzerDaten.fromJson(Map<String, dynamic> json) {
    return BenutzerDaten(
      id: json['id'] as String,
      vorname: json['vorname'] as String,
      nachname: json['nachname'] as String,
      telefonnummer: json['telefonnummer'] as String,
      geschlecht: json['geschlecht'] as String,
      email: json['email'] as String?,
      profilbildUrl: json['profilbildUrl'] as String?,
      geburtsdatum: json['geburtsdatum'] != null
          ? (json['geburtsdatum'] as Timestamp).toDate()
          : DateTime.now(), // Standardwert auf aktuelles Datum gesetzt
      adresse: json['adresse'] as String,
      rechnungsadresse: json['rechnungsadresse'] as String? ??
          json['adresse'], // Fallback auf Wohnadresse
      bevorzugteBezahlmethoden:
          (json['bevorzugteBezahlmethoden'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      favorisierteEventkategorien:
          (json['favorisierteEventkategorien'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      benachrichtigungenZulassen:
          json['benachrichtigungenZulassen'] as bool? ?? true,
      eventCoins: json['eventCoins'] as int?,
      teilgenommeneEvents: (json['teilgenommeneEvents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      visitedEvents: (json['visitedEvents'] as List<dynamic>?)
              ?.map((e) => VisitedEvent.fromJson(e))
              .toList() ??
          [],
      nameInTeilnehmerListeVerstecken:
          json['nameInTeilnehmerListeVerstecken'] as bool? ?? false,
    );
  }

  // Methode zum Exportieren nach JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vorname': vorname,
      'nachname': nachname,
      'telefonnummer': telefonnummer,
      'geschlecht': geschlecht,
      'email': email,
      'profilbildUrl': profilbildUrl,
      'geburtsdatum': geburtsdatum.toIso8601String(),
      'adresse': adresse,
      'rechnungsadresse':
          rechnungsadresse ?? adresse, // Fallback auf Wohnadresse
      'bevorzugteBezahlmethoden': bevorzugteBezahlmethoden,
      'favorisierteEventkategorien': favorisierteEventkategorien,
      'benachrichtigungenZulassen': benachrichtigungenZulassen,
      'eventCoins': eventCoins,
      'teilgenommeneEvents': teilgenommeneEvents,
      'visitedEvents': visitedEvents.map((e) => e.toJson()).toList(),
      'nameInTeilnehmerListeVerstecken': nameInTeilnehmerListeVerstecken,
    };
  }

  // Methode zur Aktualisierung von Benutzerdaten
  BenutzerDaten copyWith({
    String? id,
    String? vorname,
    String? nachname,
    String? telefonnummer,
    String? geschlecht,
    String? email,
    String? profilbildUrl,
    DateTime? geburtsdatum,
    String? adresse,
    String? rechnungsadresse,
    List<String>? bevorzugteBezahlmethoden,
    List<String>? favorisierteEventkategorien,
    bool? benachrichtigungenZulassen,
    int? eventCoins,
    List<String>? teilgenommeneEvents,
    List<VisitedEvent>? visitedEvents, // Hinzufügen von visitedEvents
    bool? nameInTeilnehmerListeVerstecken,
  }) {
    return BenutzerDaten(
      id: id ?? this.id,
      vorname: vorname ?? this.vorname,
      nachname: nachname ?? this.nachname,
      telefonnummer: telefonnummer ?? this.telefonnummer,
      geschlecht: geschlecht ?? this.geschlecht,
      email: email ?? this.email,
      profilbildUrl: profilbildUrl ?? this.profilbildUrl,
      geburtsdatum: geburtsdatum ?? this.geburtsdatum,
      adresse: adresse ?? this.adresse,
      rechnungsadresse:
          rechnungsadresse ?? this.rechnungsadresse ?? this.adresse,
      bevorzugteBezahlmethoden:
          bevorzugteBezahlmethoden ?? this.bevorzugteBezahlmethoden,
      favorisierteEventkategorien:
          favorisierteEventkategorien ?? this.favorisierteEventkategorien,
      benachrichtigungenZulassen:
          benachrichtigungenZulassen ?? this.benachrichtigungenZulassen,
      eventCoins: eventCoins ?? this.eventCoins,
      teilgenommeneEvents: teilgenommeneEvents ?? this.teilgenommeneEvents,
      visitedEvents:
          visitedEvents ?? this.visitedEvents, // Hinzufügen von visitedEvents
      nameInTeilnehmerListeVerstecken: nameInTeilnehmerListeVerstecken ??
          this.nameInTeilnehmerListeVerstecken,
    );
  }
}
