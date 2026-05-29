import 'package:flutter/material.dart';
import 'package:sprouts_manager/features/admission/admission_mode_screen.dart';
import 'package:sprouts_manager/features/dashboard/manager_dashboard_screen.dart';

class StartModeScreen extends StatelessWidget {
  const StartModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventsprouts Manager'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ModeCard(
                  title: 'Einlass starten',
                  description:
                      'Für Mitarbeiter am Eingang. Ticket prüfen und Check-in durchführen.',
                  icon: Icons.qr_code_scanner,
                  prominent: true,
                  onTap: () async {
                    final allowed = await _showSimpleConfirmDialog(
                      context,
                      title: 'Einlass starten',
                      message: 'Einlassmodus mit relevanten Events öffnen?',
                      confirmText: 'Starten',
                    );

                    if (allowed == true && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdmissionModeScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  title: 'Admin / Eventverwaltung',
                  description:
                      'Für Eventverwaltung, Teilnehmer, Kalkulation und Einstellungen.',
                  icon: Icons.admin_panel_settings,
                  onTap: () async {
                    final allowed = await _showPinDialog(
                      context,
                      title: 'Lokaler Admin-Zugang',
                      confirmText: 'Adminbereich öffnen',
                    );

                    if (allowed == true && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManagerDashboardScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showSimpleConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showPinDialog(
    BuildContext context, {
    required String title,
    required String confirmText,
  }) {
    final controller = TextEditingController();

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Lokale Admin-PIN (Dummy)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool prominent;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = prominent
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).cardColor;

    return Card(
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
