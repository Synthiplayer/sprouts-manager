import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../models/event.dart';

class EventManager extends ChangeNotifier {
  bool _hasLoadedDummyEvents = false;
  List<Event> _events = [];

  List<Event> get events => _events;

  Future<void> loadEventsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      if (snapshot.docs.isNotEmpty) {
        _events = snapshot.docs.map((doc) => Event.fromJson(doc.data())).toList();
        _hasLoadedDummyEvents = true;
    notifyListeners();
      } else {
        debugPrint('Keine Events in Firestore gefunden');
      }
    } catch (error) {
      debugPrint('Fehler beim Laden der Events aus Firestore: $error');
      if (_events.isEmpty) {
        loadDummyEvents();
      }
    }
  }

  void loadDummyEvents() {
    if (_hasLoadedDummyEvents && _events.isNotEmpty) {
      return;
    }
    _events = [
      Event(
        eventId: 'demo_event_1',
        kategorie: 'Party',
        veranstaltungsname: 'Demo Night Berlin',
        kurzbeschreibung: 'Lokales Demo-Event ohne Live-Firebase',
        datum: DateTime.now().add(const Duration(days: 5)),
        uhrzeitStart: '20:00',
        uhrzeitEnde: '02:00',
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
        kategorie: 'Konzert',
        veranstaltungsname: 'Acoustic Session',
        kurzbeschreibung: 'Zweites Demo-Event',
        datum: DateTime.now().add(const Duration(days: 12)),
        uhrzeitStart: '19:30',
        uhrzeitEnde: '23:00',
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
    _hasLoadedDummyEvents = true;
    notifyListeners();
  }

  void addOrUpdateEvent(Event event) {
    final index = _events.indexWhere((e) => e.eventId == event.eventId);

    if (index == -1) {
      _events.add(event);
    } else {
      _events[index] = event;
    }
    _hasLoadedDummyEvents = true;
    notifyListeners();

    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    FirebaseFirestore.instance.collection('events').doc(event.eventId).set(event.toJson()).catchError((error) {
      debugPrint('Fehler beim Speichern des Events: $error');
    });
  }

  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.eventId == eventId);
    _hasLoadedDummyEvents = true;
    notifyListeners();

    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    FirebaseFirestore.instance.collection('events').doc(eventId).delete().catchError((error) {
      debugPrint('Fehler beim Löschen des Events: $error');
    });
  }
}

