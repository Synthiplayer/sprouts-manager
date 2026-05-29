class VisitedEvent {
  String eventId;
  String eventName;
  DateTime date;
  int paidPrice;

  VisitedEvent({
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.paidPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'date': date.toIso8601String(), // Datum als ISO-String speichern
      'paidPrice': paidPrice,
    };
  }

  factory VisitedEvent.fromJson(Map<String, dynamic> json) {
    return VisitedEvent(
      eventId: json['eventId'],
      eventName: json['eventName'],
      date: DateTime.parse(json['date']), // Datum korrekt parsen
      paidPrice: json['paidPrice'],
    );
  }
}
