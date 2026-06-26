part of '../planning_screen.dart';

extension on _PlanningScreenState {
  Widget _buildSponsoringTab(BuildContext context, PlanningDraft draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          context,
          title: 'Finanzierungsbausteine',
          child: Column(
            children: [
              _valueRow(
                'Event-Sponsoring fix',
                formatEuro(draft.fixedSponsorAmountEur),
              ),
              _valueRow(
                'Unterstuetzer / Eventhilfe',
                formatEuro(draft.supporterAmountEur),
              ),
              _valueRow(
                'Zuschuss / Foerderung',
                formatEuro(draft.grantAmountEur),
              ),
              _valueRow(
                'Gesamtunterstuetzung',
                formatEuro(draft.totalSupportEur),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Passende Werbepartner und Sponsoren',
          child: Column(
            children: draft.partners.map((partner) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${partner.name} - ${partner.type.label}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Zielgruppe: ${partner.audienceFocus} | Level: ${partner.tier.label}',
                          ),
                          Text(
                            'Potenzial: ${formatEuro(partner.expectedAmountEur)} | Fokus: ${partner.note}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          context,
          title: 'Sponsoring-Ziel',
          child: Text(
            'Ziel ist, mehrere Werbepartner und Unterstuetzer so zu kombinieren, dass das Event eher stattfindet und der noetige Ticketpreis sinkt. Aktuell vorbereitet: ${draft.partnerSummary}.',
          ),
        ),
      ],
    );
  }

}
