import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprouts_manager/app/state/app_state_providers.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/event_currency_config.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/core/responsive/app_breakpoints.dart';
import 'package:sprouts_manager/features/event_calculation/application/event_calculation_notifier.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';
import 'package:sprouts_manager/features/events/event_detail_dialog.dart';
import 'package:sprouts_manager/models/event.dart';
import 'package:sprouts_manager/widgets/event_dialog.dart';

enum EventPlanningStatusTab {
  planning,
  breakEvenReached,
  all,
}

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
    return EventPlanningScreen(
      onOpenEventForAdmission: onOpenEventForAdmission,
      embedded: embedded,
    );
  }
}

class EventPlanningScreen extends ConsumerStatefulWidget {
  final void Function(Event event)? onOpenEventForAdmission;
  final bool embedded;

  const EventPlanningScreen({
    super.key,
    this.onOpenEventForAdmission,
    this.embedded = false,
  });

  @override
  ConsumerState<EventPlanningScreen> createState() => _EventPlanningScreenState();
}

class _EventPlanningScreenState extends ConsumerState<EventPlanningScreen> {
  EventPlanningStatusTab _statusTab = EventPlanningStatusTab.planning;
  EventCategory? _categoryFilter;
  String? _selectedEventId;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventListProvider);
    final filteredEvents = _applyFilters(events);
    final selectedEvent = _resolveSelectedEvent(filteredEvents);
    final isDesktopLike = !AppBreakpoints.isPhone(context) ||
        MediaQuery.of(context).orientation == Orientation.landscape;

    final content = Column(
      children: [
        _buildCompactToolbar(context),
        _buildFilterHeader(),
        Expanded(
          child: isDesktopLike
              ? Row(
                  children: [
                    Expanded(
                      flex: 58,
                      child: _buildEventList(filteredEvents, selectedEvent),
                    ),
                    const VerticalDivider(width: 1, thickness: 0.8),
                    Expanded(
                      flex: 42,
                      child: _buildDetailPane(selectedEvent),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: _buildEventList(filteredEvents, selectedEvent),
                    ),
                    if (selectedEvent != null)
                      SizedBox(
                        height: 340,
                        child: _buildDetailPane(selectedEvent),
                      ),
                  ],
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      body: content,
      floatingActionButton: isDesktopLike
          ? null
          : FloatingActionButton(
              onPressed: () => _openEventDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Status und Kategorien filtern',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          FilledButton.icon(
            onPressed: () => _openEventDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Neues Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          _buildStatusTabs(),
          const SizedBox(height: 6),
          _buildCategoryFilter(),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SegmentedButton<EventPlanningStatusTab>(
      segments: const [
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.planning,
          label: Text('In Planung'),
        ),
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.breakEvenReached,
          label: Text('Break-even erreicht'),
        ),
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.all,
          label: Text('Alle'),
        ),
      ],
      selected: <EventPlanningStatusTab>{_statusTab},
      onSelectionChanged: (selection) {
        setState(() {
          _statusTab = selection.first;
        });
      },
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('Alle Kategorien'),
              selected: _categoryFilter == null,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                setState(() {
                  _categoryFilter = null;
                });
              },
            ),
          ),
          ...EventCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(category.label),
                selectedColor: category.color,
                labelStyle: TextStyle(
                  color: _categoryFilter == category ? Colors.white : category.color,
                ),
                side: BorderSide(color: category.color),
                backgroundColor: category.darkColor.withValues(alpha: 0.14),
                selected: _categoryFilter == category,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() {
                    _categoryFilter = category;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events, Event? selectedEvent) {
    if (events.isEmpty) {
      return const Center(
        child: Text('Keine Events für die aktuelle Filterauswahl.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isSelected = selectedEvent?.eventId == event.eventId;
        final statusText =
            event.hasReachedBreakEven ? 'Break-even erreicht' : 'In Planung';

        return Card(
          color: event.category.color,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 1.8,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              if (widget.onOpenEventForAdmission != null) {
                widget.onOpenEventForAdmission!(event);
                return;
              }

              setState(() {
                _selectedEventId = event.eventId;
              });
              _openEventDetailDialog(context, event);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: event.category.toChip(filled: false)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.veranstaltungsname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(event.datum)} | ${event.uhrzeitStart} - ${event.uhrzeitEnde}',
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () => _openEventDialog(context, event: event),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        splashRadius: 18,
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          _showDeleteConfirmation(context, ref, event);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPane(Event? event) {
    if (event == null) {
      return const Center(
        child: Text('Wähle ein Event aus, um Details und Kalkulationsvorschau zu sehen.'),
      );
    }

    final calculation = ref.watch(eventCalculationPreviewProvider(event));
    final normalPrice = event.anmeldePreise['Normal'] ?? 0;
    final earlyBirdPrice = event.anmeldePreise['EarlyBird'] ?? 0;
    final participantCount = event.teilnehmerliste.length;
    final progressToMinimum = event.minimaleTeilnehmerzahl > 0
        ? (participantCount / event.minimaleTeilnehmerzahl)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.veranstaltungsname,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              event.category.toChip(),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  event.hasReachedBreakEven ? 'Break-even erreicht' : 'In Planung',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailSection(
            context,
            title: 'Eventdetails',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Datum: ${_formatDate(event.datum)}'),
                Text('Zeit: ${event.uhrzeitStart} - ${event.uhrzeitEnde}'),
                Text(
                  'Terminstatus: ${event.hasReachedBreakEven ? 'Termin nach Break-even' : 'Termin offen'}',
                ),
                Text('Raumaufbau: ${event.raumAufbau}'),
                Text('Veranstalter: ${event.veranstalter}'),
                if (event.earlyBirdDeadline != null)
                  Text('Early-Bird-Deadline: ${_formatDate(event.earlyBirdDeadline!)}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            context,
            title: 'Teilnehmerstatus',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teilnehmer aktuell: $participantCount'),
                Text('Mindestteilnehmer: ${event.minimaleTeilnehmerzahl}'),
                Text('Maximalteilnehmer: ${event.maximaleTeilnehmerzahl}'),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progressToMinimum),
                const SizedBox(height: 8),
                Text(
                  'Fortschritt zur Mindestteilnehmerzahl: ${(progressToMinimum * 100).round()} %',
                ),
                const SizedBox(height: 8),
                const Text('Teilnehmerliste später hier öffnen'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            context,
            title: 'Kalkulationsvorschau',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticketpreis: $normalPrice EVC ≈ ${formatEuro(calculation.normalTicketValueEur)}',
                ),
                Text(
                  'Early-Bird: $earlyBirdPrice EVC ≈ ${formatEuro(calculation.earlyBirdTicketValueEur)}',
                ),
                Text(
                  'Aktueller Kalkulationswert: 1 EVC = ${formatEuro(EventCurrencyConfig.evcToEur(1))}',
                ),
                Text('Grundkosten brutto: ${formatEuro(calculation.baseCostGrossEur)}'),
                Text(
                  'Zu deckender Betrag: ${formatEuro(calculation.amountToCoverEur)}',
                ),
                Text(
                  'Durchschnittlicher Ticketwert: ${formatEuro(calculation.averageTicketValueEur)}',
                ),
                Text(
                  'Break-even-Teilnehmer: ${calculation.breakEvenParticipants}',
                ),
                Text(
                  'Upgrade-Budget nach Break-even: ${formatEuro(calculation.upgradeBudgetAfterBreakEvenEur)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailSection(
            context,
            title: 'Aktionen',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eventkarte öffnet die große Detailansicht mit Übersicht, Kalkulation und Teilnehmerbereich.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _openEventDetailDialog(context, event),
                      child: const Text('Details öffnen'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Teilnehmer anzeigen'),
                            content: const Text(
                              'Teilnehmerliste wird später in einem eigenen Bereich ergänzt.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Schließen'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Teilnehmer anzeigen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Event> _applyFilters(List<Event> events) {
    final byStatus = events.where((event) {
      switch (_statusTab) {
        case EventPlanningStatusTab.planning:
          return !event.hasReachedBreakEven;
        case EventPlanningStatusTab.breakEvenReached:
          return event.hasReachedBreakEven;
        case EventPlanningStatusTab.all:
          return true;
      }
    });

    return byStatus.where((event) {
      if (_categoryFilter == null) {
        return true;
      }

      return event.category == _categoryFilter;
    }).toList();
  }

  Event? _resolveSelectedEvent(List<Event> filteredEvents) {
    if (filteredEvents.isEmpty) {
      return null;
    }

    for (final event in filteredEvents) {
      if (event.eventId == _selectedEventId) {
        return event;
      }
    }

    return filteredEvents.first;
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
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
                ref.read(eventListProvider.notifier).deleteEvent(event.eventId);
                Navigator.of(context).pop();
              },
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _openEventDialog(BuildContext context, {Event? event}) {
    showDialog(
      context: context,
      builder: (context) => EventDialog(event: event),
    );
  }

  void _openEventDetailDialog(BuildContext context, Event event) {
    showDialog<void>(
      context: context,
      builder: (context) => EventDetailDialog(event: event),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }
}
