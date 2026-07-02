import 'package:flutter/material.dart';

class SponsorPartnerScreen extends StatelessWidget {
  const SponsorPartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Sponsoren',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Hier entsteht die neutrale Partnerdatenbank mit Zielgruppen, Mindestreichweite und Kontaktstatus. Konkrete Zusagen, Beträge und Gold/Silber/Bronze-Level werden pro Event in der Planung gesetzt.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partnerdatenbank',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Noch keine zentrale Sponsorverwaltung angelegt.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
