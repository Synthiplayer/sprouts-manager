import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sprouts_manager/app/state/app_state_providers.dart';
import 'package:sprouts_manager/models/event.dart';
import 'package:sprouts_manager/pages/check_in_page.dart';

class AdmissionModeScreen extends ConsumerWidget {
  const AdmissionModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventListProvider);

    final todayEvents = events.where(_isToday).toList();
    final upcomingEvents = events.where(_isUpcomingWithinSevenDays).toList();
    final otherLocalEvents = events.where((event) {
      return !_isToday(event) && !_isUpcomingWithinSevenDays(event);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einlassmodus'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wähle ein relevantes Event für den Einlass.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (todayEvents.isNotEmpty) ...[
                    _EventGroupCard(
                      title: 'Heute',
                      events: todayEvents,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (upcomingEvents.isNotEmpty) ...[
                    _EventGroupCard(
                      title: 'Nächste Events',
                      events: upcomingEvents,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (otherLocalEvents.isNotEmpty)
                    _EventGroupCard(
                      title: 'Weitere Events',
                      events: otherLocalEvents,
                    ),
                  if (todayEvents.isEmpty &&
                      upcomingEvents.isEmpty &&
                      otherLocalEvents.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Keine lokalen Events vorhanden.'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isToday(Event event) {
    final now = DateTime.now();
    return event.datum.year == now.year &&
        event.datum.month == now.month &&
        event.datum.day == now.day;
  }

  static bool _isUpcomingWithinSevenDays(Event event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(event.datum.year, event.datum.month, event.datum.day);
    final lastUpcomingDay = today.add(const Duration(days: 7));
    return eventDay.isAfter(today) && !eventDay.isAfter(lastUpcomingDay);
  }
}

class _EventGroupCard extends StatelessWidget {
  final String title;
  final List<Event> events;

  const _EventGroupCard({
    required this.title,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...events.map(
              (event) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available),
                title: Text(event.veranstaltungsname),
                subtitle: Text('Datum: ${_formatDate(event.datum)} | Start: ${event.uhrzeitStart}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckInPage(event: event),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
