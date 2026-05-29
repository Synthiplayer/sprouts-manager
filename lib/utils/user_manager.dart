import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../models/user.dart';

class UserManager {
  CollectionReference get userCollection =>
      FirebaseFirestore.instance.collection('users');

  Future<List<BenutzerDaten>> loadUsersFromFirestore() async {
    try {
      final snapshot = await userCollection.get();
      return snapshot.docs
          .map((doc) => BenutzerDaten.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Fehler beim Laden der Benutzer: $e');
      return [];
    }
  }

  List<BenutzerDaten> loadDummyUsers() {
    return [
      BenutzerDaten(
        id: 'U1001',
        vorname: 'Max',
        nachname: 'Müller',
        telefonnummer: '+491234567890',
        geschlecht: 'männlich',
        email: 'max@example.com',
        adresse: 'Musterstraße 1, Berlin',
        eventCoins: 120,
      ),
      BenutzerDaten(
        id: 'U1002',
        vorname: 'Lea',
        nachname: 'Schmidt',
        telefonnummer: '+491709876543',
        geschlecht: 'weiblich',
        email: 'lea@example.com',
        adresse: 'Beispielweg 5, Hamburg',
        eventCoins: 80,
      ),
    ];
  }

  Future<void> addUser(BenutzerDaten user) async {
    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    await userCollection.add(user.toJson());
  }

  Future<void> deleteUser(String userId) async {
    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    await userCollection.doc(userId).delete();
  }

  Future<void> updateUser(String userId, BenutzerDaten updatedUser) async {
    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    await userCollection.doc(userId).update(updatedUser.toJson());
  }
}
