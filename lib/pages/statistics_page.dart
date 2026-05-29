import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      body: const Center(
        child: Text(
          'Hier werden die Event-Statistiken angezeigt.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
