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
