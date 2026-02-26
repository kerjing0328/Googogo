import 'package:flutter/material.dart';

class VolunteerGamification {
  static int getLevel(int points) => (points ~/ 200) + 1;
  static int getLevelThreshold(int level) {
    return (level - 1) * 200;
  }

  static int getNextLevelThreshold(int level) {
    return level * 200;
  }

  static String getRank(int level) {
    if (level >= 10) return "Legend";
    if (level >= 8) return "Elite";
    if (level >= 5) return "Hero";
    if (level >= 3) return "Guardian";
    return "Scout"; 
  }

  static List<Map<String, dynamic>> badges = [
    {
      'id': 'first_report',
      'name': 'First Step',
      'desc': 'Submit your first report',
      'icon': Icons.flag,
      'color': Colors.blue, 
      'type': 'reports',
      'value': 1,
    },
    {
      'id': 'helper_10',
      'name': 'Helpful Hand',
      'desc': 'Help 10 people',
      'icon': Icons.volunteer_activism,
      'color': Colors.pink, 
      'type': 'helped',
      'value': 10,
    },
    {
      'id': 'reporter_50',
      'name': 'Sharp Eye',
      'desc': 'Submit 50 reports',
      'icon': Icons.remove_red_eye,
      'color': Colors.teal, 
      'type': 'reports',
      'value': 50,
    },
    {
      'id': 'elite_500',
      'name': 'Elite Volunteer',
      'desc': 'Reach 500 points',
      'icon': Icons.star,
      'color': Colors.amber, 
      'type': 'points',
      'value': 500,
    },
    {
      'id': 'legend_2000',
      'name': 'Legendary',
      'desc': 'Reach 2000 points',
      'icon': Icons.emoji_events,
      'color': Colors.purple, 
      'type': 'points',
      'value': 2000,
    },
    {
      'id': 'night_owl',
      'name': 'Night Owl',
      'desc': 'Report at night',
      'icon': Icons.nights_stay,
      'color': Colors.indigo, 
      'type': 'manual', 
      'value': 1,
    }
  ];

  static bool isUnlocked({
    required Map<String, dynamic> badge,
    required int points,
    required int reports,
    required int helped,
  }) {
    switch (badge['type']) {
      case 'reports':
        return reports >= badge['value'];

      case 'helped':
        return helped >= badge['value'];

      case 'points':
        return points >= badge['value'];
      
      default:
        return false;
    }
  }
}