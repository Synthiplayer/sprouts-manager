import 'package:flutter/material.dart';

class LocationManagementPage extends StatelessWidget {
  const LocationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location-Verwaltung'),
      ),
      body: const Center(
        child: Text(
          'Hier werden die Event-Locations verwaltet.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
