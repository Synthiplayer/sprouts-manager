import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprouts_manager/app/state/app_state_providers.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
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
  confirmed,
  all,
}

enum EventWorkspaceTab {
  participants,
  calculation,
  details,
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
  EventWorkspaceTab _workspaceTab = EventWorkspaceTab.participants;
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
        _buildFilterToolbar(context),
        Expanded(
          child: isDesktopLike
              ? Row(
                  children: [
                    Expanded(
                      flex: 58,
                      child: _buildEventList(filteredEvents, selectedEvent),
                    ),
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      flex: 42,
                      child: _buildWorkspacePane(context, selectedEvent),
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
                        height: 380,
                        child: _buildWorkspacePane(context, selectedEvent),
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

  Widget _buildFilterToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTabs(),
                const SizedBox(height: 6),
                _buildCategoryFilter(),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _openEventDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Neues Event'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return SegmentedButton<EventPlanningStatusTab>(
      segments: const [
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.planning,
          label: Text('In Abstimmung'),
        ),
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.breakEvenReached,
          label: Text('Break-even'),
        ),
        ButtonSegment<EventPlanningStatusTab>(
          value: EventPlanningStatusTab.confirmed,
          label: Text('Bestaetigt'),
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
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('Alle'),
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
        child: Text('Keine Events fuer die aktuelle Filterauswahl.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isSelected = selectedEvent?.eventId == event.eventId;
        final participantCount = event.teilnehmerliste.length;
        final minParticipants = event.minimaleTeilnehmerzahl;
        final progress = minParticipants > 0
            ? (participantCount / minParticipants).clamp(0.0, 1.0).toDouble()
            : 0.0;
        final breakEvenText =
            event.hasReachedBreakEven ? 'Break-even erreicht' : 'Break-even offen';
        final ticketPrice = event.anmeldePreise['Normal'] ?? 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: event.category.color.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Card(
            color: event.category.color,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: isSelected ? 2.4 : 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.onOpenEventForAdmission != null) {
                  widget.onOpenEventForAdmission!(event);
                  return;
                }

                setState(() {
                  _selectedEventId = event.eventId;
                  _workspaceTab = EventWorkspaceTab.participants;
                });
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              event.category.toChip(filled: false),
                              _cardBadge(_workflowStatusLabel(event)),
                              if (isSelected) _cardBadge('Ausgewaehlt'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 8),
                    Text(
                      event.veranstaltungsname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.hasReachedBreakEven
                          ? 'Termin: ${_formatDate(event.datum)}'
                          : 'Terminstatus: Termin offen',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                    if (event.uhrzeitStart.trim().isNotEmpty)
                      Text(
                        'Uhrzeit: ${event.uhrzeitStart}${event.uhrzeitEnde.trim().isNotEmpty ? ' - ${event.uhrzeitEnde}' : ''}',
                        style: const TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '$participantCount / $minParticipants Mindestteilnehmer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          breakEvenText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$ticketPrice EVC',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkspacePane(BuildContext context, Event? event) {
    if (event == null) {
      return const Center(
        child: Text('Waehle ein Event aus, um Teilnehmer, Kalkulation und Aktionen zu sehen.'),
      );
    }

    final calculation = ref.watch(eventCalculationPreviewProvider(event));
    final participantCount = event.teilnehmerliste.length;
    final minParticipants = event.minimaleTeilnehmerzahl;
    final maxParticipants = event.maximaleTeilnehmerzahl;
    final progress = minParticipants > 0
        ? (participantCount / minParticipants).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final ticketPrice = event.anmeldePreise['Normal'] ?? 0;
    final missingParticipants =
        (calculation.breakEvenParticipants - participantCount).clamp(
      0,
      calculation.breakEvenParticipants,
    );

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
                label: Text(_workflowStatusLabel(event)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<EventWorkspaceTab>(
            segments: const [
              ButtonSegment<EventWorkspaceTab>(
                value: EventWorkspaceTab.participants,
                label: Text('Teilnehmer'),
              ),
              ButtonSegment<EventWorkspaceTab>(
                value: EventWorkspaceTab.calculation,
                label: Text('Kalkulation'),
              ),
              ButtonSegment<EventWorkspaceTab>(
                value: EventWorkspaceTab.details,
                label: Text('Details'),
              ),
            ],
            selected: <EventWorkspaceTab>{_workspaceTab},
            onSelectionChanged: (selection) {
              setState(() {
                _workspaceTab = selection.first;
              });
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _workspaceTab = EventWorkspaceTab.participants;
                  });
                },
                child: const Text('Teilnehmer verwalten'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _workspaceTab = EventWorkspaceTab.calculation;
                  });
                },
                child: const Text('Kalkulation oeffnen'),
              ),
              OutlinedButton(
                onPressed: () => _openEventDialog(context, event: event),
                child: const Text('Bearbeiten'),
              ),
              OutlinedButton(
                onPressed: () => _openEventDetailDialog(context, event),
                child: const Text('Grosse Detailansicht'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          switch (_workspaceTab) {
            EventWorkspaceTab.participants => _buildDetailSection(
                context,
                title: 'Teilnehmer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoLine('Aktuelle Teilnehmer', '$participantCount'),
                    _infoLine('Mindestteilnehmer', '$minParticipants'),
                    _infoLine('Maximalteilnehmer', '$maxParticipants'),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      'Fortschritt zur Mindestteilnehmerzahl: ${(progress * 100).round()} %',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Teilnehmerverwaltung spaeter: Ticketstatus, Zahlung, Check-in, Erstattung, Ampelstatus und Notizen.',
                    ),
                  ],
                ),
              ),
            EventWorkspaceTab.calculation => _buildDetailSection(
                context,
                title: 'Kalkulation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoLine(
                      'Ticketpreis',
                      '$ticketPrice EVC / ${formatEuro(calculation.normalTicketValueEur)}',
                    ),
                    _infoLine(
                      'Grundkosten',
                      formatEuro(calculation.baseCostGrossEur),
                    ),
                    if (calculation.sponsorAndGrantTotalEur > 0)
                      _infoLine(
                        'Sponsoring / Zuschuesse',
                        formatEuro(calculation.sponsorAndGrantTotalEur),
                      ),
                    _infoLine(
                      'Zu deckender Betrag',
                      formatEuro(calculation.amountToCoverEur),
                    ),
                    _infoLine(
                      'Break-even-Teilnehmer',
                      '${calculation.breakEvenParticipants}',
                    ),
                    _infoLine(
                      'Fehlende Teilnehmer',
                      '$missingParticipants',
                    ),
                    _infoLine(
                      'Upgrade-Budget',
                      formatEuro(calculation.upgradeBudgetAfterBreakEvenEur),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Kalkulationseditor spaeter hier als eigener Arbeitsbereich.',
                    ),
                  ],
                ),
              ),
            EventWorkspaceTab.details => _buildDetailSection(
                context,
                title: 'Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoLine('Kategorie', event.category.label),
                    _infoLine('Status', _workflowStatusLabel(event)),
                    _infoLine(
                      'Terminstatus',
                      event.hasReachedBreakEven ? 'Termin bestaetigt' : 'Termin offen',
                    ),
                    _infoLine(
                      'Datum / Zeit',
                      '${_formatDate(event.datum)} | ${event.uhrzeitStart}${event.uhrzeitEnde.trim().isNotEmpty ? ' - ${event.uhrzeitEnde}' : ''}',
                    ),
                    _infoLine('Location / Setup', 'Noch nicht zugewiesen'),
                    _infoLine(
                      'Early-Bird-Deadline',
                      event.earlyBirdDeadline == null
                          ? 'Noch offen'
                          : _formatDate(event.earlyBirdDeadline!),
                    ),
                    _infoLine(
                      'Anmeldeschluss',
                      _formatDate(event.anmeldeschluss),
                    ),
                    _infoLine(
                      'Preisinfos',
                      '$ticketPrice EVC / ${formatEuro(calculation.normalTicketValueEur)}',
                    ),
                  ],
                ),
              ),
          },
        ],
      ),
    );
  }

  List<Event> _applyFilters(List<Event> events) {
    final byStatus = events.where((event) {
      switch (_statusTab) {
        case EventPlanningStatusTab.planning:
          return !_isConfirmed(event) && !event.hasReachedBreakEven;
        case EventPlanningStatusTab.breakEvenReached:
          return !_isConfirmed(event) && event.hasReachedBreakEven;
        case EventPlanningStatusTab.confirmed:
          return _isConfirmed(event);
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
          title: const Text('Event loeschen'),
          content: Text(
            'Moechten Sie das Event "${event.veranstaltungsname}" wirklich loeschen?',
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
              child: const Text('Loeschen', style: TextStyle(color: Colors.red)),
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
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _cardBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  String _workflowStatusLabel(Event event) {
    if (_isConfirmed(event)) {
      return 'Bestaetigt';
    }

    return event.hasReachedBreakEven ? 'Break-even erreicht' : 'In Abstimmung';
  }

  bool _isConfirmed(Event event) {
    final status = event.status?.trim().toLowerCase();
    return event.lockedIn || status == 'confirmed' || status == 'bestaetigt';
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
