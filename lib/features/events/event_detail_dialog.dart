import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sprouts_manager/core/domain_enums.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';
import 'package:sprouts_manager/features/event_calculation/application/event_calculation_notifier.dart';
import 'package:sprouts_manager/features/event_calculation/domain/event_calculation_model.dart';
import 'package:sprouts_manager/features/events/event_category_ui.dart';
import 'package:sprouts_manager/models/event.dart';
import 'package:sprouts_manager/widgets/event_dialog.dart';

class EventDetailDialog extends ConsumerWidget {
  final Event event;

  const EventDetailDialog({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculation = ref.watch(eventCalculationPreviewProvider(event));
    final currentParticipants = event.teilnehmerliste.length;
    final progressToMinimum = event.minimaleTeilnehmerzahl > 0
        ? (currentParticipants / event.minimaleTeilnehmerzahl)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;
    final isCompact = MediaQuery.sizeOf(context).width < 900;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 32,
        vertical: isCompact ? 12 : 24,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1080,
          maxHeight: 780,
        ),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              event.category.toChip(),
                              _StatusBadge(label: _eventStatusLabel(event)),
                              _StatusBadge(label: calculation.calculationStatus.label),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.veranstaltungsname,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_formatDate(event.datum)} | ${event.uhrzeitStart} - ${event.uhrzeitEnde}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) => EventDialog(event: event),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Bearbeiten'),
                        ),
                        IconButton(
                          tooltip: 'Schliessen',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Uebersicht'),
                  Tab(text: 'Kalkulation'),
                  Tab(text: 'Teilnehmer'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(
                      event: event,
                      calculation: calculation,
                      currentParticipants: currentParticipants,
                      progressToMinimum: progressToMinimum,
                    ),
                    _CalculationTab(
                      event: event,
                      calculation: calculation,
                      currentParticipants: currentParticipants,
                    ),
                    _ParticipantsTab(
                      event: event,
                      calculation: calculation,
                      currentParticipants: currentParticipants,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Event event;
  final EventCalculationModel calculation;
  final int currentParticipants;
  final double progressToMinimum;

  const _OverviewTab({
    required this.event,
    required this.calculation,
    required this.currentParticipants,
    required this.progressToMinimum,
  });

  @override
  Widget build(BuildContext context) {
    final normalPrice = event.anmeldePreise['Normal'] ?? 0;
    final earlyBirdPrice = event.anmeldePreise['EarlyBird'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Uebersicht',
            child: Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _InfoPair(label: 'Kategorie', value: event.category.label),
                _InfoPair(label: 'Status', value: _eventStatusLabel(event)),
                _InfoPair(label: 'Terminstatus', value: _scheduleStatusLabel(event)),
                _InfoPair(
                  label: 'Termin',
                  value:
                      '${_formatDate(event.datum)} | ${event.uhrzeitStart} - ${event.uhrzeitEnde}',
                ),
                const _InfoPair(
                  label: 'Location / Setup',
                  value: 'Noch nicht zugewiesen',
                ),
                _InfoPair(
                  label: 'Normalpreis',
                  value:
                      '$normalPrice EVC = ${formatEuro(calculation.normalTicketValueEur)}',
                ),
                _InfoPair(
                  label: 'Early-Bird-Preis',
                  value:
                      '$earlyBirdPrice EVC = ${formatEuro(calculation.earlyBirdTicketValueEur)}',
                ),
                _InfoPair(
                  label: 'Early-Bird-Deadline',
                  value: event.earlyBirdDeadline == null
                      ? 'Noch offen'
                      : _formatDate(event.earlyBirdDeadline!),
                ),
                _InfoPair(
                  label: 'Anmeldeschluss',
                  value: _formatDate(event.anmeldeschluss),
                ),
                _InfoPair(
                  label: 'Mindestteilnehmer',
                  value: '${event.minimaleTeilnehmerzahl}',
                ),
                _InfoPair(
                  label: 'Maximalteilnehmer',
                  value: '${event.maximaleTeilnehmerzahl}',
                ),
                _InfoPair(
                  label: 'Aktuelle Teilnehmer',
                  value: '$currentParticipants',
                ),
                _InfoPair(
                  label: 'Break-even-Status',
                  value: event.hasReachedBreakEven
                      ? 'Break-even erreicht'
                      : 'Break-even noch offen',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Teilnehmerstatus',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(value: progressToMinimum),
                    ),
                    const SizedBox(width: 12),
                    Text('${(progressToMinimum * 100).round()} %'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Aktuell $currentParticipants von ${event.minimaleTeilnehmerzahl} Mindestteilnehmern erreicht.',
                ),
                const SizedBox(height: 6),
                Text(
                  'Kalkulationsstatus: ${calculation.calculationStatus.label}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculationTab extends StatelessWidget {
  final Event event;
  final EventCalculationModel calculation;
  final int currentParticipants;

  const _CalculationTab({
    required this.event,
    required this.calculation,
    required this.currentParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final missingParticipants = max(
      0,
      calculation.breakEvenParticipants - currentParticipants,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Kalkulation',
            child: Column(
              children: [
                _ValueRow(
                  label: 'Ticketpreis',
                  value:
                      '${event.anmeldePreise['Normal'] ?? 0} EVC / ${formatEuro(calculation.normalTicketValueEur)}',
                ),
                _ValueRow(
                  label: 'Grundkosten',
                  value: formatEuro(calculation.baseCostGrossEur),
                ),
                if (calculation.sponsorAndGrantTotalEur > 0)
                  _ValueRow(
                    label: 'Sponsoring / Zuschuesse',
                    value: formatEuro(calculation.sponsorAndGrantTotalEur),
                  ),
                _ValueRow(
                  label: 'Zu deckender Betrag',
                  value: formatEuro(calculation.amountToCoverEur),
                  emphasize: true,
                ),
                _ValueRow(
                  label: 'Break-even-Teilnehmer',
                  value: '${calculation.breakEvenParticipants}',
                ),
                _ValueRow(
                  label: 'Fehlende Teilnehmer',
                  value: '$missingParticipants',
                ),
                _ValueRow(
                  label: 'Upgrade-Budget',
                  value: formatEuro(calculation.upgradeBudgetAfterBreakEvenEur),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  final Event event;
  final EventCalculationModel calculation;
  final int currentParticipants;

  const _ParticipantsTab({
    required this.event,
    required this.calculation,
    required this.currentParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final checkedInCount = event.eingecheckteListe.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Teilnehmer',
            child: Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                _InfoPair(label: 'Aktuell angemeldet', value: '$currentParticipants'),
                _InfoPair(label: 'Eingecheckt', value: '$checkedInCount'),
                _InfoPair(
                  label: 'Mindestteilnehmer',
                  value: '${event.minimaleTeilnehmerzahl}',
                ),
                _InfoPair(
                  label: 'Maximalteilnehmer',
                  value: '${event.maximaleTeilnehmerzahl}',
                ),
                _InfoPair(
                  label: 'Geplante Teilnehmer',
                  value: '${calculation.expectedParticipants}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Spaeterer Adminbereich',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teilnehmerverwaltung spaeter: Ticketstatus, Zahlung, Check-in, Erstattung, Ampelstatus und Notizen.',
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Teilnehmerverwaltung'),
                        content: const Text(
                          'Die Teilnehmerverwaltung wird spaeter als eigener Bereich ergaenzt.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Schliessen'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Teilnehmer verwalten'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoPair extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPair({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ValueRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasize
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
    );
  }
}

String _eventStatusLabel(Event event) {
  if (event.lockedIn) {
    return 'Locked-in';
  }
  if (event.hasReachedBreakEven) {
    return 'Break-even erreicht';
  }
  if ((event.status ?? '').trim().isNotEmpty) {
    return event.status!;
  }
  return 'Entwurf';
}

String _scheduleStatusLabel(Event event) {
  if (event.lockedIn) {
    return 'Termin gesichert';
  }
  if (event.hasReachedBreakEven) {
    return 'Termin nach Break-even';
  }
  return 'Termin offen';
}

String _formatDate(DateTime date) {
  return DateFormat('dd.MM.yyyy').format(date);
}
