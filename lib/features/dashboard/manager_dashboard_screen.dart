import 'package:flutter/material.dart';
import 'package:sprouts_manager/features/admission/admission_mode_screen.dart';
import 'package:sprouts_manager/features/events/event_management_page.dart';
import 'package:sprouts_manager/features/locations/presentation/screens/location_management_screen.dart';
import 'package:sprouts_manager/features/planning/planning_screen.dart';
import 'package:sprouts_manager/pages/statistics_page.dart';
import 'package:sprouts_manager/pages/user_management_page.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const PlanningScreen(),
      const EventManagementPage(),
      const AdmissionModeScreen(),
      const UserManagementPage(),
      const LocationManagementScreen(),
      const StatisticsPage(),
    ];

    final labels = <String>[
      'Planung',
      'Events',
      'Einlass',
      'User',
      'Locations',
      'Statistiken',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Manager/Adminmodus - ${labels[_index]}'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.edit_calendar),
                label: Text('Planung'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text('Events'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.confirmation_number),
                label: Text('Einlass'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.groups),
                label: Text('User'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.location_on),
                label: Text('Locations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                label: Text('Statistik'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}
