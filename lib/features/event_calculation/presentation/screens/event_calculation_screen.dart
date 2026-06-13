import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprouts_manager/core/formatters/currency_formatter.dart';

import '../../application/event_calculation_notifier.dart';

class EventCalculationScreen extends ConsumerWidget {
  const EventCalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventCalculationProvider);
    final notifier = ref.read(eventCalculationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Eventkalkulation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Kosten',
            children: [
              _NumberField(
                label: 'Kuenstler / DJ / Band',
                onChanged: notifier.updateArtistCost,
              ),
              _NumberField(
                label: 'Location',
                onChanged: notifier.updateLocationCost,
              ),
              _NumberField(
                label: 'Technik',
                onChanged: notifier.updateTechnologyCost,
              ),
              _NumberField(
                label: 'Security',
                onChanged: notifier.updateSecurityCost,
              ),
              _NumberField(
                label: 'Personal',
                onChanged: notifier.updateStaffCost,
              ),
              _NumberField(
                label: 'GEMA / Lizenz',
                onChanged: notifier.updateLicenseCost,
              ),
              _NumberField(
                label: 'Werbung',
                onChanged: notifier.updateMarketingCost,
              ),
              _NumberField(
                label: 'Versicherung',
                onChanged: notifier.updateInsuranceCost,
              ),
              _NumberField(
                label: 'Sonstige Kosten',
                onChanged: notifier.updateOtherCosts,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Planung',
            children: [
              _NumberField(
                label: 'Early-Bird-Preis in EVC',
                onChanged: notifier.updateEarlyBirdPrice,
              ),
              _NumberField(
                label: 'Normalpreis in EVC',
                onChanged: notifier.updateNormalPrice,
              ),
              _IntField(
                label: 'Erwartete Teilnehmer',
                onChanged: notifier.updateExpectedParticipants,
              ),
              _IntField(
                label: 'Maximale Teilnehmer',
                onChanged: notifier.updateMaxParticipants,
              ),
              _NumberField(
                label: 'Sponsoranteil / Admin-Zuschuss',
                onChanged: notifier.updateSponsorContribution,
              ),
              _IntField(
                label: 'Freitickets / Promo-Tickets',
                onChanged: notifier.updateFreeTickets,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Ergebnisse',
            children: [
              _ResultRow(
                label: 'Ticketpreis',
                value:
                    '${state.normalTicketPriceEvc} EVC / ${formatEuro(state.normalTicketValueEur)}',
              ),
              _ResultRow(
                label: 'Grundkosten',
                value: formatEuro(notifier.totalCosts),
              ),
              if (state.sponsorAndGrantTotalEur > 0)
                _ResultRow(
                  label: 'Sponsoring / Zuschuesse',
                  value: formatEuro(state.sponsorAndGrantTotalEur),
                ),
              _ResultRow(
                label: 'Zu deckender Betrag',
                value: formatEuro(state.amountToCoverEur),
              ),
              _ResultRow(
                label: 'Break-even-Teilnehmer',
                value: '${notifier.breakEvenParticipants}',
              ),
              _ResultRow(
                label: 'Fehlende Teilnehmer',
                value:
                    '${(notifier.breakEvenParticipants - notifier.payingParticipants).clamp(0, notifier.breakEvenParticipants)}',
              ),
              _ResultRow(
                label: 'Upgrade-Budget',
                value: formatEuro(state.upgradeBudgetAfterBreakEvenEur),
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final void Function(double value) onChanged;

  const _NumberField({required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => onChanged(double.tryParse(value.replaceAll(',', '.')) ?? 0),
      ),
    );
  }
}

class _IntField extends StatelessWidget {
  final String label;
  final void Function(int value) onChanged;

  const _IntField({required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => onChanged(int.tryParse(value) ?? 0),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}
