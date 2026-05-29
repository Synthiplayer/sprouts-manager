import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/app_config.dart';
import '../models/user.dart';

class UserManager extends ChangeNotifier {
  bool _hasLoadedDummyUsers = false;
  List<BenutzerDaten> users = [];

  CollectionReference get userCollection =>
      FirebaseFirestore.instance.collection('users');

  Future<void> loadUsersFromFirestore() async {
    try {
      final snapshot = await userCollection.get();
      users = snapshot.docs
          .map((doc) => BenutzerDaten.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      _hasLoadedDummyUsers = true;
    notifyListeners();
    } catch (e) {
      debugPrint('Fehler beim Laden der Benutzer: $e');
      if (users.isEmpty) {
        loadDummyUsers();
      }
    }
  }

  void loadDummyUsers() {
    if (_hasLoadedDummyUsers && users.isNotEmpty) {
      return;
    }
    users = [
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
    _hasLoadedDummyUsers = true;
    notifyListeners();
  }

  Future<void> addUser(BenutzerDaten user) async {
    users.add(user);
    _hasLoadedDummyUsers = true;
    notifyListeners();

    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    try {
      await userCollection.add(user.toJson());
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen des Benutzers: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    users.removeWhere((user) => user.id == userId);
    _hasLoadedDummyUsers = true;
    notifyListeners();

    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    try {
      await userCollection.doc(userId).delete();
    } catch (e) {
      debugPrint('Fehler beim Löschen des Benutzers: $e');
    }
  }

  Future<void> updateUser(String userId, BenutzerDaten updatedUser) async {
    final index = users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      users[index] = updatedUser;
      _hasLoadedDummyUsers = true;
    notifyListeners();
    }

    if (!AppConfig.useFirebaseInDevelopment) {
      return;
    }

    try {
      await userCollection.doc(userId).update(updatedUser.toJson());
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Benutzers: $e');
    }
  }
}

