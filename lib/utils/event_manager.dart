import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sprouts_manager/core/domain_enums.dart';

import '../core/app_config.dart';
import '../models/event.dart';

class EventManager {
  Future<List<Event>> loadEventsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Event.fromJson(doc.data())).toList();
      }

      debugPrint('Keine Events in Firestore gefunden');
      return [];
    } catch (error) {
      debugPrint('Fehler beim Laden der Events aus Firestore: $error');
      return [];
    }
  }

  List<Event> loadDummyEvents() {
    return [
      Event(
        eventId: 'demo_event_1',
        category: EventCategory.party,
        veranstaltungsname: 'Demo Night Berlin',
        kurzbeschreibung: 'Lokales Demo-Event ohne Live-Firebase',
        datum: DateTime.now().add(const Duration(days: 5)),
        uhrzeitStart: '20:00',
        uhrzeitEnde: '02:00',
        earlyBirdDeadline: DateTime.now().add(const Duration(days: 2)),
        altersbeschraenkung: 18,
        anmeldeschluss: DateTime.now().add(const Duration(days: 4)),
        anmeldePreise: const {'Normal': 15, 'EarlyBird': 10},
        minimaleTeilnehmerzahl: 50,
        maximaleTeilnehmerzahl: 300,
        raumAufbau: 'Stehend',
        veranstalter: 'Eventsprouts',
        featureFlag: true,
        status: 'open',
        teilnehmerliste: const ['U1001', 'U1002', 'U1003'],
        eingecheckteListe: const [],
      ),
      Event(
        eventId: 'demo_event_2',
        category: EventCategory.concert,
        veranstaltungsname: 'Acoustic Session',
        kurzbeschreibung: 'Zweites Demo-Event',
        datum: DateTime.now().add(const Duration(days: 12)),
        uhrzeitStart: '19:30',
        uhrzeitEnde: '23:00',
        earlyBirdDeadline: DateTime.now().add(const Duration(days: 8)),
        altersbeschraenkung: 16,
        anmeldeschluss: DateTime.now().add(const Duration(days: 11)),
        anmeldePreise: const {'Normal': 20, 'EarlyBird': 14},
        minimaleTeilnehmerzahl: 30,
        maximaleTeilnehmerzahl: 180,
        raumAufbau: 'Mischung',
        veranstalter: 'Eventsprouts',
        featureFlag: true,
        status: 'open',
        teilnehmerliste: const ['U1004', 'U1005'],
        eingecheckteListe: const ['U1004'],
      ),
    ];
  }

  Future<void> upsertEvent(Event event) async {
    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    await FirebaseFirestore.instance.collection('events').doc(event.eventId).set(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
  }
}
