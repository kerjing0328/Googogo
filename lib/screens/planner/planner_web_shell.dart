import 'package:flutter/material.dart';
import 'planner_dashboard.dart';
import 'planner_map.dart';
import 'planner_list.dart';

class PlannerWebShell extends StatefulWidget {
  final String userName; 
  const PlannerWebShell({super.key, required this.userName});

  @override
  State<PlannerWebShell> createState() => _PlannerWebShellState();
}

class _PlannerWebShellState extends State<PlannerWebShell> {
  int _selectedIndex = 0;

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 800;
    
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.fromARGB(255, 73, 83, 185), 
        Color.fromARGB(255, 83, 130, 201),
      ],
      stops: [0.0, 1.0],
    );

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isLargeScreen ? 260 : 80,
            decoration: const BoxDecoration(gradient: gradient),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.admin_panel_settings_outlined, color: Colors.white.withOpacity(0.9), size: 36),
                if (isLargeScreen) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "AidCess",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                  ),
                  Text(
                    "AUTHORITY PANEL",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, letterSpacing: 2),
                  ),
                ],
                const SizedBox(height: 40),
            
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard_rounded,
                        label: "Overview",
                        isSelected: _selectedIndex == 0,
                        isExtended: isLargeScreen,
                        onTap: () => _switchTab(0),
                      ),
                      _NavItem(
                        icon: Icons.map_rounded,
                        label: "Live Map",
                        isSelected: _selectedIndex == 1,
                        isExtended: isLargeScreen,
                        onTap: () => _switchTab(1),
                      ),
                      _NavItem(
                        icon: Icons.table_chart_rounded,
                        label: "Reports",
                        isSelected: _selectedIndex == 2,
                        isExtended: isLargeScreen,
                        onTap: () => _switchTab(2),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: isLargeScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF4953B9), size: 20),
                      ),
                      if (isLargeScreen) ...[
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Administrator", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text("Log Out", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: const Color(0xFFF1F5F9), 
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  PlannerDashboard(onViewAll: () => _switchTab(2)),
                  const PlannerMap(),
                  const PlannerList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: isExtended ? 20 : 0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
            ),
            child: Row(
              mainAxisAlignment: isExtended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                if (isExtended) ...[
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}