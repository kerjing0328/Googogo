import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/role_card.dart';
import '../volunteer/volunteer_screen.dart';
import '../navigate/navigate_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- Logout Logic ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('assets/malaysia_flag.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 73, 83, 185).withOpacity(0.90),
                    const Color.fromARGB(255, 72, 168, 157).withOpacity(0.85),
                    const Color.fromARGB(255, 83, 130, 201).withOpacity(0.90),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: FadeTransition(
              opacity: _controller,
              child: IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _showLogoutDialog,
                tooltip: "Logout",
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  _buildAnimatedHeader(),

                  const Spacer(flex: 2),

                  const Text(
                    "Select Your Role",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  _buildAnimatedCard(
                    index: 0,
                    child: RoleCard(
                      title: "Volunteer",
                      subtitle: "Report barriers & earn points",
                      icon: Icons.camera_alt_outlined,
                      gradientColors: [
                        Colors.tealAccent.shade700,
                        Colors.teal.shade900,
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VolunteerScreen(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildAnimatedCard(
                    index: 1,
                    child: RoleCard(
                      title: "Access User",
                      subtitle: "Voice-guided navigation",
                      icon: Icons.map_outlined,
                      gradientColors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade800,
                      ],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OkuMapScreen()),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  Center(
                    child: Opacity(
                      opacity: 0.9,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Building smarter, inclusive cities.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.code,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "by Googogo",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          ),
      child: FadeTransition(
        opacity: _controller,
        child: Column(
          children: [
            Text(
              "Welcome, ${widget.userName}",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
                shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.location_city_rounded,
                size: 70,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AidCess',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Text(
                'AI for Accessible Cities',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    final double delay = (index + 1) * 0.2;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(delay * 0.5, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(delay * 0.5, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: child,
      ),
    );
  }
}
