import 'package:flutter/material.dart';
import 'package:sprouts_manager/features/events/event_management_page.dart';
import 'package:sprouts_manager/pages/user_management_page.dart'; // Beispiel fÃ¼r Dummy-Seiten
import 'package:sprouts_manager/pages/location_management_page.dart';
import 'package:sprouts_manager/pages/statistics_page.dart'; // Dummy-Statistikseite

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  // Liste der Seiten, die in der Navigation aufgerufen werden kÃ¶nnen
  static const List<Widget> _pages = <Widget>[
    EventManagementPage(),
    UserManagementPage(), // Dummy-Seite fÃ¼r Benutzerverwaltung
    LocationManagementPage(), // Dummy-Seite fÃ¼r Location-Verwaltung
    StatisticsPage(), // Dummy-Seite fÃ¼r Statistiken
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // Farbe der aktiven Icons
        unselectedItemColor: Colors.grey.shade600, // Farbe der inaktiven Icons
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Benutzer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistiken',
          ),
        ],
      ),
    );
  }
}

