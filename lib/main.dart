import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 🔐 Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'screens/home.dart';
import 'screens/login.dart';

// 🔔 GLOBAL NOTIFICATION PLUGIN
final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =============================
  // 🔐 INIT FIREBASE (ADDED)
  // =============================
  await Firebase.initializeApp();

  // =============================
  // ⏰ INIT TIMEZONE (RETAINED)
  // =============================
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  // =============================
  // 🔔 INIT NOTIFICATIONS (RETAINED)
  // =============================
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(initSettings);

  // =============================
  // 🔔 CREATE CHANNEL (RETAINED)
  // =============================
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'reminder_channel',
    'Reminders',
    description: 'Medicine and test reminders',
    importance: Importance.max,
  );

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // =============================
  // 🔔 ANDROID 13+ PERMISSION (RETAINED)
  // =============================
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      ),

      // 🔐 AUTH GATE (ADDED)
      home: const AuthGate(),
    );
  }
}

//
// =============================
// 🔐 AUTH GATE WIDGET
// =============================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Not logged in
        return const LoginScreen();
      },
    );
  }
}
