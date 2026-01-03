import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  // =========================
  // LOAD SAVED REPORTS
  // =========================
  Future<void> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("reports") ?? [];

    setState(() {
      reports = data
          .map((e) {
        try {
          return jsonDecode(e) as Map<String, dynamic>;
        } catch (_) {
          return <String, dynamic>{};
        }
      })
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  // =========================
  // DELETE REPORT
  // =========================
  Future<void> deleteReport(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("reports") ?? [];

    if (index < 0 || index >= data.length) return;

    data.removeAt(index);
    await prefs.setStringList("reports", data);

    setState(() {
      reports.removeAt(index);
    });
  }

  // =========================
  // CONFIRM DELETE
  // =========================
  void confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text("Are you sure you want to delete this report?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteReport(index);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "My Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          _animatedBackground(),
          ..._floatingOrbs(),

          reports.isEmpty
              ? _emptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r = reports[i];
              return _reportCard(r, i)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.15);
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // REPORT CARD
  // =========================
  Widget _reportCard(Map<String, dynamic> r, int index) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 IMAGE
          if (r["image"] != null &&
              r["image"].toString().isNotEmpty &&
              File(r["image"]).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.file(
                    File(r["image"]),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // 🚦 RISK + DELETE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _riskPill(r["risk"]),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => confirmDelete(index),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 🧠 SUMMARY
          Text(
            r["summary"] ?? "",
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 10),

          // 🕒 TIME
          if (r["time"] != null)
            Text(
              "Saved on ${DateTime.parse(r["time"]).toLocal()}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  // =========================
  // EMPTY STATE
  // =========================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No reports yet",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // =========================
  // RISK PILL
  // =========================
  Widget _riskPill(String? risk) {
    final color = _riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Risk: ${risk?.toString().toUpperCase() ?? ""}",
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // =========================
  // GLASS CARD
  // =========================
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 18),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // =========================
  // BACKGROUND
  // =========================
  Widget _animatedBackground() {
    return AnimatedContainer(
      duration: 6.seconds,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEDE9FE),
            Color(0xFFE0F2FE),
            Color(0xFFF6F7FB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  List<Widget> _floatingOrbs() {
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
      width: 200,
      height: 200,
      decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: colors[i].withOpacity(0.25),
      ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .move(
      duration: (8 + i * 2).seconds,
      begin: Offset.zero,
      end: const Offset(50, 70),
      )
          .blurXY(begin: 70, end: 120));
    });
  }

  // =========================
  // RISK COLOR HELPER
  // =========================
  Color _riskColor(String? risk) {
    switch (risk) {
      case "high":
        return Colors.red;
      case "moderate":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
