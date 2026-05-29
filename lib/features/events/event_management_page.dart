import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sprouts_manager/models/event.dart';
import 'package:sprouts_manager/pages/check_in_page.dart';
import 'package:sprouts_manager/utils/event_manager.dart';
import 'package:sprouts_manager/widgets/colors.dart';
import 'package:sprouts_manager/widgets/event_dialog.dart';

class EventManagementPage extends StatelessWidget {
  final void Function(Event event)? onOpenEventForAdmission;
  final bool embedded;

  const EventManagementPage({
    super.key,
    this.onOpenEventForAdmission,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final eventManager = Provider.of<EventManager>(context);

    final eventList = ListView.builder(
      itemCount: eventManager.events.length,
      itemBuilder: (context, index) {
        final event = eventManager.events[index];
        return Card(
          color: _getCategoryColor(event.kategorie),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.kategorie,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  event.veranstaltungsname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Datum: ${_formatDate(event.datum)}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                Text(
                  'Zeit: ${event.uhrzeitStart} - ${event.uhrzeitEnde}',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EventDialog(event: event),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _showDeleteConfirmation(context, eventManager, event);
                  },
                ),
              ],
            ),
            onTap: () {
              if (onOpenEventForAdmission != null) {
                onOpenEventForAdmission!(event);
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckInPage(event: event),
                ),
              );
            },
          ),
        );
      },
    );

    if (embedded) {
      return eventList;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
      ),
      body: eventList,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const EventDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    EventManager eventManager,
    Event event,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Event löschen'),
          content: Text(
            'Möchten Sie das Event "${event.veranstaltungsname}" wirklich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                eventManager.deleteEvent(event.eventId);
                Navigator.of(context).pop();
              },
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Konzert':
        return konzertEvent;
      case 'Movie':
        return movieNight;
      case 'Special':
        return specialEvent;
      case 'Kids':
        return kidsClub;
      case 'Party':
        return partyNight;
      default:
        return lightGray;
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }
}
