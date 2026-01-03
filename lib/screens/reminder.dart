import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_animate/flutter_animate.dart';

import '../main.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Map<String, dynamic>> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // =============================
  // LOAD
  // =============================
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("reminders") ?? [];

    setState(() {
      reminders =
          data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    });
  }

  // =============================
  // SAVE
  // =============================
  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      "reminders",
      reminders.map((e) => jsonEncode(e)).toList(),
    );
  }

  // =============================
  // ADD
  // =============================
  Future<void> _addReminder() async {
    final titleController = TextEditingController();
    DateTime? selectedTime;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration:
              const InputDecoration(labelText: "Medicine / Test"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              child: const Text("Pick Time"),
              onPressed: () async {
                final now = DateTime.now();
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(now),
                );

                if (time != null) {
                  selectedTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    time.hour,
                    time.minute,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Save"),
            onPressed: () async {
              if (titleController.text.isEmpty || selectedTime == null) return;

              if (selectedTime!.isBefore(DateTime.now())) {
                selectedTime = selectedTime!.add(const Duration(days: 1));
              }

              final int id =
                  DateTime.now().millisecondsSinceEpoch ~/ 1000;

              final reminder = {
                "id": id,
                "title": titleController.text,
                "time": selectedTime!.toIso8601String(),
              };

              setState(() => reminders.add(reminder));
              await _saveReminders();

              await notificationsPlugin.zonedSchedule(
                id,
                "Reminder",
                titleController.text,
                tz.TZDateTime.from(selectedTime!, tz.local),
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'reminder_channel',
                    'Reminders',
                    importance: Importance.max,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
                androidScheduleMode:
                AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.wallClockTime,
              );

              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // =============================
  // DELETE
  // =============================
  Future<void> _deleteReminder(int index) async {
    final id = reminders[index]["id"];
    await notificationsPlugin.cancel(id);

    setState(() => reminders.removeAt(index));
    await _saveReminders();
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Set Reminders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _addReminder,
        child: const Icon(Icons.add),
      ).animate().scale(),
      body: Stack(
        children: [
          _animatedBackground(),
          ..._floatingOrbs(),

          reminders.isEmpty
              ? _emptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return _reminderCard(reminder, index)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.15);
            },
          ),
        ],
      ),
    );
  }

  // =============================
  // REMINDER CARD
  // =============================
  Widget _reminderCard(Map<String, dynamic> reminder, int index) {
    final time = DateTime.parse(reminder["time"]);

    return _glassCard(
      child: Row(
        children: [
          // ⏰ ICON
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.alarm, color: Colors.indigo),
          ),

          const SizedBox(width: 12),

          // 📄 TITLE + TIME
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🗑 DELETE
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteReminder(index),
          ),
        ],
      ),
    );
  }

  // =============================
  // EMPTY STATE
  // =============================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.alarm_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No reminders added",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  // =============================
  // GLASS CARD
  // =============================
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

  // =============================
  // BACKGROUND
  // =============================
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
}
