import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Screens
import 'interpret.dart';
import 'ai.dart';
import 'reminder.dart';
import 'reports.dart';
import 'login.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🔐 LOGOUT
  Future<void> _logout(BuildContext context) async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    const primary = Color(0xFF6366F1);
    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      body: Stack(
        children: [
          // =========================
          // 🌈 ANIMATED GRADIENT BASE
          // =========================
          AnimatedContainer(
            duration: 3.seconds,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF6F7FB),
                  Color(0xFFEDE9FE),
                  Color(0xFFE0F2FE),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // =========================
          // 🫧 FLOATING COLOR BLOBS
          // =========================
          ..._floatingBlobs(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // TOP BAR
                  // =========================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "HealthiE",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ).animate().fadeIn(),

                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) =>
                              _profileSheet(context, user, primary),
                        ),
                        child: CircleAvatar(
                          backgroundColor: primary.withOpacity(0.15),
                          child: Text(
                            (user?.displayName ?? 'U')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =========================
                  // HERO CARD
                  // =========================
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back 👋",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.displayName?.split(' ').first ?? "User",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Your health. Smarter. Simpler.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .slideY(begin: -0.2)
                      .fadeIn(),

                  const SizedBox(height: 36),

                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.9,
                    children: [
                      _feature(
                        index: 0,
                        icon: Icons.description_rounded,
                        title: "Interpret",
                        subtitle: "Health reports",
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const InterpretScreen()),
                        ),
                      ),
                      _feature(
                        index: 1,
                        icon: Icons.smart_toy_rounded,
                        title: "Ask AI",
                        subtitle: "Chat or voice",
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AIScreen()),
                        ),
                      ),
                      _feature(
                        index: 2,
                        icon: Icons.alarm_rounded,
                        title: "Reminders",
                        subtitle: "Medicines",
                        color: const Color(0xFFF59E0B),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReminderScreen()),
                        ),
                      ),
                      _feature(
                        index: 3,
                        icon: Icons.history_rounded,
                        title: "Reports",
                        subtitle: "History",
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ReportsScreen()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  _glassCard(
                    child: Row(
                      children: const [
                        Icon(Icons.favorite, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Tip: Stay hydrated & sleep well 💤",
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),

      // =========================
      // FLOATING AI BUTTON
      // =========================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        elevation: 14,
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Ask AI"),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIScreen()),
        ),
      )
          .animate()
          .scale(duration: 600.ms)
          .shimmer(delay: 2.seconds),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // =========================
  // FLOATING BLOBS
  // =========================
  List<Widget> _floatingBlobs() {
    final colors = [
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.tealAccent,
    ];

    return List.generate(3, (i) {
      return Positioned(
        top: Random().nextDouble() * 500,
        left: Random().nextDouble() * 300,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[i].withOpacity(0.25),
          ),
        )
            .animate(
          onPlay: (c) => c.repeat(reverse: true),
        )
            .move(
          duration: (6 + i * 2).seconds,
          curve: Curves.easeInOut,
          begin: const Offset(0, 0),
          end: const Offset(40, 60),
        )
            .blurXY(begin: 80, end: 120),
      );
    });
  }

  // =========================
  // GLASS CARD
  // =========================
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // =========================
  // FEATURE TILE
  // =========================
  Widget _feature({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, delay: (120 * index).ms)
        .fadeIn();
  }

  // =========================
  // PROFILE SHEET
  // =========================
  Widget _profileSheet(
      BuildContext context, User? user, Color primary) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: primary.withOpacity(0.15),
            child: Text(
              (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(user?.displayName ?? "User",
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? "",
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
