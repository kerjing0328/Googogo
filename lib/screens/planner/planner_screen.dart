import 'package:flutter/material.dart';
import 'planner_dashboard.dart';
import 'planner_map.dart';
import 'planner_list.dart';

class CityPlannerScreen extends StatefulWidget {
  const CityPlannerScreen({super.key});

  @override
  State<CityPlannerScreen> createState() => _CityPlannerScreenState();
}

class _CityPlannerScreenState extends State<CityPlannerScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PlannerDashboard(),
    PlannerMap(),
    PlannerList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Colors.indigo.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Colors.indigo),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Colors.indigo),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            selectedIcon: Icon(Icons.list_alt, color: Colors.indigo),
            label: 'All Reports',
          ),
        ],
      ),
    );
  }
}