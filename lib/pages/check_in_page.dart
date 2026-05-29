import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class CheckInPage extends StatefulWidget {
  final Event event;

  const CheckInPage({super.key, required this.event});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String? scannedCode;
  bool isSplitScreen = false;
  bool showMessage = false;
  String message = '';
  Color messageColor = Colors.green;
  final TextEditingController manualInputController = TextEditingController();
  bool resetEnabled = false;

  @override
  void dispose() {
    manualInputController.dispose();
    super.dispose();
  }

  void _checkUserForEvent(String code) {
    if (widget.event.teilnehmerliste.contains(code)) {
      if (!widget.event.eingecheckteListe.contains(code)) {
        setState(() {
          widget.event.eingecheckteListe.add(code);
          message = 'Check-In erfolgreich!';
          messageColor = Colors.green;
        });
      } else {
        setState(() {
          message = 'Teilnehmer bereits eingecheckt!';
          messageColor = Colors.orange;
        });
      }
    } else {
      setState(() {
        message = 'Ungültiger Ticket-Code - Teilnehmer nicht registriert!';
        messageColor = Colors.red;
      });
    }

    setState(() {
      scannedCode = code;
      showMessage = true;
    });
    _resetAfterDelay();
  }

  void _manualCheckIn() {
    final code = manualInputController.text.trim();
    if (code.isNotEmpty) {
      _checkUserForEvent(code);
    }
  }

  void _resetAfterDelay() {
    resetEnabled = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (resetEnabled && mounted) {
        setState(() {
          showMessage = false;
          scannedCode = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Check-in: ${widget.event.veranstaltungsname}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isSplitScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () {
              setState(() {
                isSplitScreen = !isSplitScreen;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Datum: ${_formatDate(widget.event.datum)}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Uhrzeit: ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Eingecheckt: ${widget.event.eingecheckteListe.length} von ${widget.event.teilnehmerliste.length} Personen',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _calculateCheckInProgress(widget.event),
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            if (isSplitScreen)
              Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scannedCode != null ? 'Benutzer: $scannedCode' : 'Kein Code gescannt',
                          style: const TextStyle(fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Zweizeilige Darstellung des Namens',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'QR-Scanner ist vorübergehend deaktiviert (Plugin inkompatibel mit aktuellem Android-Gradle-Stack).\n\nBitte Ticket-Code manuell eingeben.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (showMessage)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: messageColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: manualInputController,
              decoration: const InputDecoration(
                labelText: 'Ticket-/QR-Code manuell eingeben',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _manualCheckIn(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    resetEnabled = false;
                  },
                  child: const Text('Teilnehmerliste'),
                ),
                ElevatedButton(
                  onPressed: _manualCheckIn,
                  child: const Text('Manuell einchecken'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }

  double _calculateCheckInProgress(Event event) {
    final totalTeilnehmer = event.teilnehmerliste.length;
    final checkedIn = event.eingecheckteListe.length;
    return totalTeilnehmer > 0 ? checkedIn / totalTeilnehmer : 0.0;
  }
}
