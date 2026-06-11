enum EventStatus {
  open,
  confirmed,
  soldOut,
  closed,
  past,
  canceled,
  notHappening,
}

enum AdmissionResultType {
  valid,
  alreadyCheckedIn,
  canceled,
  wrongEvent,
  blockedUser,
  unknownTicket,
  offlineDataMissing,
  syncRequired,
}

enum UserRole {
  admin,
  eventManager,
  admissionStaff,
  support,
}

enum ParticipantType {
  regular,
  wheelchair,
  child,
  waitlist,
}

enum EventCategory {
  party,
  concert,
  special,
  movie,
  kids,
}

extension EventCategoryX on EventCategory {
  String get label {
    switch (this) {
      case EventCategory.party:
        return 'Partys';
      case EventCategory.concert:
        return 'Konzerte';
      case EventCategory.special:
        return 'Specials';
      case EventCategory.movie:
        return 'Movies';
      case EventCategory.kids:
        return 'Kids';
    }
  }

  static EventCategory fromStoredValue(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'party':
      case 'partys':
        return EventCategory.party;
      case 'concert':
      case 'konzert':
      case 'konzerte':
        return EventCategory.concert;
      case 'special':
      case 'specials':
        return EventCategory.special;
      case 'movie':
      case 'movies':
      case 'cinema':
      case 'kino':
        return EventCategory.movie;
      case 'kids':
        return EventCategory.kids;
      case 'culture':
      case 'kultur':
      case 'other':
      case 'sonstiges':
        return EventCategory.special;
      default:
        return EventCategory.special;
    }
  }
}
