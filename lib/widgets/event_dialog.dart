import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';

import '../app/state/app_state_providers.dart';
import '../models/event.dart';

class EventDialog extends ConsumerStatefulWidget {
  final Event? event;

  const EventDialog({super.key, this.event});

  @override
  ConsumerState<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends ConsumerState<EventDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController earlyBirdDeadlineController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController preisNormalController = TextEditingController();
  final TextEditingController preisEarlyBirdController = TextEditingController();
  final TextEditingController altersbeschraenkungController = TextEditingController();
  final TextEditingController anmeldeschlussController = TextEditingController();
  final TextEditingController minimaleTeilnehmerController = TextEditingController();
  final TextEditingController maximaleTeilnehmerController = TextEditingController();
  String raumAufbau = 'Stehend';
  EventCategory category = EventCategory.concert;

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      nameController.text = widget.event!.veranstaltungsname;
      dateController.text = DateFormat('dd.MM.yyyy').format(widget.event!.datum);
      startTimeController.text = widget.event!.uhrzeitStart;
      endTimeController.text = widget.event!.uhrzeitEnde;
      preisNormalController.text = widget.event!.anmeldePreise['Normal'].toString();
      preisEarlyBirdController.text = widget.event!.anmeldePreise['EarlyBird'].toString();
      earlyBirdDeadlineController.text = widget.event!.earlyBirdDeadline == null
          ? ''
          : DateFormat('dd.MM.yyyy').format(widget.event!.earlyBirdDeadline!);
      altersbeschraenkungController.text = widget.event!.altersbeschraenkung.toString();
      anmeldeschlussController.text = DateFormat('dd.MM.yyyy').format(widget.event!.anmeldeschluss);
      minimaleTeilnehmerController.text = widget.event!.minimaleTeilnehmerzahl.toString();
      maximaleTeilnehmerController.text = widget.event!.maximaleTeilnehmerzahl.toString();
      raumAufbau = widget.event!.raumAufbau;
      category = widget.event!.category;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    earlyBirdDeadlineController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    preisNormalController.dispose();
    preisEarlyBirdController.dispose();
    altersbeschraenkungController.dispose();
    anmeldeschlussController.dispose();
    minimaleTeilnehmerController.dispose();
    maximaleTeilnehmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Neues Event' : 'Event bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<EventCategory>(
              initialValue: category,
              items: EventCategory.values
                  .map(
                    (value) => DropdownMenuItem<EventCategory>(
                      value: value,
                      child: value.toDropdownItem(),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  category = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Kategorie'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Eventname'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Datum (tt.mm.jjjj)'),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  dateController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
                }
              },
            ),
            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(labelText: 'Startzeit (HH:MM)'),
            ),
            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(labelText: 'Endzeit (HH:MM)'),
            ),
            TextField(
              controller: preisNormalController,
              decoration: const InputDecoration(labelText: 'Normalpreis'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: preisEarlyBirdController,
              decoration: const InputDecoration(labelText: 'Early Bird Preis'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: earlyBirdDeadlineController,
              decoration: const InputDecoration(labelText: 'Early-Bird-Deadline (tt.mm.jjjj)'),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.event?.earlyBirdDeadline ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  earlyBirdDeadlineController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
                }
              },
            ),
            TextField(
              controller: altersbeschraenkungController,
              decoration: const InputDecoration(labelText: 'Altersbeschränkung'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: anmeldeschlussController,
              decoration: const InputDecoration(labelText: 'Anmeldeschluss (tt.mm.jjjj)'),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  anmeldeschlussController.text = DateFormat('dd.MM.yyyy').format(pickedDate);
                }
              },
            ),
            TextField(
              controller: minimaleTeilnehmerController,
              decoration: const InputDecoration(labelText: 'Minimale Teilnehmer'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: maximaleTeilnehmerController,
              decoration: const InputDecoration(labelText: 'Maximale Teilnehmer'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
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
            final newEvent = Event(
              eventId: widget.event?.eventId ?? 'event_${DateTime.now().millisecondsSinceEpoch}',
              category: category,
              veranstaltungsname: nameController.text,
              kurzbeschreibung: 'Beschreibung',
              datum: DateFormat('dd.MM.yyyy').parse(dateController.text),
              uhrzeitStart: startTimeController.text,
              uhrzeitEnde: endTimeController.text,
              earlyBirdDeadline: earlyBirdDeadlineController.text.trim().isEmpty
                  ? null
                  : DateFormat('dd.MM.yyyy').parse(earlyBirdDeadlineController.text),
              altersbeschraenkung: int.parse(altersbeschraenkungController.text),
              anmeldeschluss: DateFormat('dd.MM.yyyy').parse(anmeldeschlussController.text),
              anmeldePreise: {
                'Normal': int.parse(preisNormalController.text),
                'EarlyBird': int.parse(preisEarlyBirdController.text),
              },
              minimaleTeilnehmerzahl: int.parse(minimaleTeilnehmerController.text),
              maximaleTeilnehmerzahl: int.parse(maximaleTeilnehmerController.text),
              veranstalter: 'Eventsprouts',
              featureFlag: true,
              raumAufbau: raumAufbau,
              bildAsset: null,
              teilnehmerliste: widget.event?.teilnehmerliste ?? const [],
              eingecheckteListe: widget.event?.eingecheckteListe ?? const [],
              status: widget.event?.status ?? 'open',
              addons: widget.event?.addons,
              addonPreise: widget.event?.addonPreise,
              langbeschreibung: widget.event?.langbeschreibung,
              bewertungen: widget.event?.bewertungen,
              lockedIn: widget.event?.lockedIn ?? false,
            );

            ref.read(eventListProvider.notifier).addOrUpdateEvent(newEvent);
            Navigator.of(context).pop();
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
