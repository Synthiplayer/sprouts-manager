import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprouts_manager/core/app_config.dart';
import 'package:sprouts_manager/models/event.dart';
import 'package:sprouts_manager/models/user.dart';
import 'package:sprouts_manager/utils/event_manager.dart';
import 'package:sprouts_manager/utils/user_manager.dart';

final eventManagerProvider = Provider<EventManager>((ref) => EventManager());
final userManagerProvider = Provider<UserManager>((ref) => UserManager());

final eventListProvider = StateNotifierProvider<EventListNotifier, List<Event>>(
  (ref) => EventListNotifier(ref.read(eventManagerProvider)),
);

final userListProvider = StateNotifierProvider<UserListNotifier, List<BenutzerDaten>>(
  (ref) => UserListNotifier(ref.read(userManagerProvider)),
);

class EventListNotifier extends StateNotifier<List<Event>> {
  EventListNotifier(this._manager) : super(const []);

  final EventManager _manager;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!AppConfig.useFirebaseInDevelopment) {
      state = _manager.loadDummyEvents();
      return;
    }

    final remoteEvents = await _manager.loadEventsFromFirestore();
    state = remoteEvents.isNotEmpty ? remoteEvents : _manager.loadDummyEvents();
  }

  Future<void> addOrUpdateEvent(Event event) async {
    final index = state.indexWhere((e) => e.eventId == event.eventId);
    if (index == -1) {
      state = [...state, event];
    } else {
      final updated = [...state];
      updated[index] = event;
      state = updated;
    }

    await _manager.upsertEvent(event);
  }

  Future<void> deleteEvent(String eventId) async {
    state = state.where((e) => e.eventId != eventId).toList();
    await _manager.deleteEvent(eventId);
  }
}

class UserListNotifier extends StateNotifier<List<BenutzerDaten>> {
  UserListNotifier(this._manager) : super(const []);

  final UserManager _manager;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!AppConfig.useFirebaseInDevelopment) {
      state = _manager.loadDummyUsers();
      return;
    }

    final remoteUsers = await _manager.loadUsersFromFirestore();
    state = remoteUsers.isNotEmpty ? remoteUsers : _manager.loadDummyUsers();
  }

  Future<void> addUser(BenutzerDaten user) async {
    state = [...state, user];
    await _manager.addUser(user);
  }

  Future<void> deleteUser(String userId) async {
    state = state.where((user) => user.id != userId).toList();
    await _manager.deleteUser(userId);
  }

  Future<void> updateUser(String userId, BenutzerDaten updatedUser) async {
    final index = state.indexWhere((user) => user.id == userId);
    if (index == -1) {
      return;
    }

    final updated = [...state];
    updated[index] = updatedUser;
    state = updated;
    await _manager.updateUser(userId, updatedUser);
  }
}
