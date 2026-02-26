import 'package:flutter/material.dart';
import '../../models/volunteer_gamification.dart'; 

class VolunteerProfileSheet extends StatelessWidget {
  final int points;
  final int reports;
  final int helped;

  const VolunteerProfileSheet({
    super.key,
    required this.points,
    required this.reports,
    required this.helped,
  });

  @override
  Widget build(BuildContext context) {
    final int level = VolunteerGamification.getLevel(points);
    final String rank = VolunteerGamification.getRank(level);

    final int nextLevelThreshold = VolunteerGamification.getNextLevelThreshold(level);
    final int currentLevelThreshold = VolunteerGamification.getLevelThreshold(level);

    int range = nextLevelThreshold - currentLevelThreshold;
    if (range <= 0) range = 200; 
    
    final double progress = (points - currentLevelThreshold) / range;
    final int pointsToNext = nextLevelThreshold - points;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 5, 
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
            ),
            _buildHeader(level, rank, progress, pointsToNext, points),

            const SizedBox(height: 25),
            const Divider(),
            const SizedBox(height: 15),

            _buildStats(),

            const SizedBox(height: 25),

            _buildBadges(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Keep Volunteering",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader(int level, String rank, double progress, int pointsToNext, int currentPoints) {
    return Column(
      children: [
        Row(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal, width: 2),
              ),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 35, color: Colors.white),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                  ),
                  Text(
                    "Level $level Volunteer",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$currentPoints XP",
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Next Level Progress",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
                Text(
                  "$pointsToNext pts to go",
                  style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem("Total Points", points, Icons.stars_rounded, Colors.amber),
        _containerDivider(),
        _statItem("Reports", reports, Icons.assignment_turned_in, Colors.blue),
        _containerDivider(),
        _statItem("People Helped", helped, Icons.volunteer_activism, Colors.pink),
      ],
    );
  }

  Widget _containerDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[300]);
  }

  Widget _statItem(String title, int value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          "$value",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        Text(
          title, 
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }


  Widget _buildBadges() {
    final allBadges = VolunteerGamification.badges;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Badges & Achievements",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 15),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            mainAxisSpacing: 15,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (_, i) {
            final badge = allBadges[i];
            final unlocked = VolunteerGamification.isUnlocked(
              badge: badge,
              points: points,
              reports: reports,
              helped: helped,
            );

            return _badgeItem(badge, unlocked);
          },
        ),
      ],
    );
  }

  Widget _badgeItem(Map<String, dynamic> badge, bool unlocked) {
    final Color badgeColor = badge['color'] ?? Colors.teal;

    return Opacity(
      opacity: unlocked ? 1.0 : 0.5, 
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 3. USE THE EXTRACTED COLOR FOR BACKGROUND
              color: unlocked ? badgeColor.withOpacity(0.1) : Colors.grey[100],
              border: Border.all(
                // 4. USE THE EXTRACTED COLOR FOR BORDER
                color: unlocked ? badgeColor : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Icon(
              badge['icon'],
              color: unlocked ? badgeColor : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: unlocked ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}