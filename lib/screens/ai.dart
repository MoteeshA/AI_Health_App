import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  bool isRecording = false;
  bool isLoading = false;
  bool aiThinking = false;
  bool aiSpeaking = false;

  final Record _record = Record();
  final FlutterTts _tts = FlutterTts();

  List<Map<String, dynamic>> reports = [];
  List<Map<String, String>> chat = [];

  static const String openAiApiKey = "REDACTED";

  String? audioPath;

  @override
  void initState() {
    super.initState();
    loadReports();
    setupTTS();
  }

  // =========================
  // LOAD REPORTS
  // =========================
  Future<void> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList("reports") ?? [];

    setState(() {
      reports = data
          .map((e) {
            try {
              return Map<String, dynamic>.from(jsonDecode(e));
            } catch (_) {
              return <String, dynamic>{};
            }
          })
          .where((e) => e.isNotEmpty)
          .toList();
    });
  }

  // =========================
  // BUILD HEALTH CONTEXT
  // =========================
  String buildHealthContext() {
    if (reports.isEmpty) {
      return "No previous health reports available.";
    }

    final buffer = StringBuffer("User Health History:\n");

    for (final r in reports) {
      buffer.writeln("""
- Risk Level: ${r["risk"]}
- Summary: ${r["summary"]}
""");
    }

    return buffer.toString();
  }

  // =========================
  // RECORD AUDIO
  // =========================
  Future<void> toggleRecording() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    if (aiThinking || aiSpeaking) return;

    final hasPermission = await _record.hasPermission();
    if (!hasPermission) return;

    final dir = await getTemporaryDirectory();
    audioPath = "${dir.path}/whisper_input.wav";

    await _record.start(
      path: audioPath!,
      encoder: AudioEncoder.wav,
      samplingRate: 16000,
    );

    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await _record.stop();
    setState(() => isRecording = false);

    if (audioPath != null) {
      await transcribeWithWhisper(audioPath!);
    }
  }

  // =========================
  // WHISPER TRANSCRIPTION
  // =========================
  Future<void> transcribeWithWhisper(String path) async {
    setState(() {
      aiThinking = true;
      isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://api.openai.com/v1/audio/transcriptions"),
      );

      request.headers["Authorization"] = "Bearer $openAiApiKey";
      request.fields["model"] = "whisper-1";
      request.files.add(await http.MultipartFile.fromPath("file", path));

      final response = await request.send();
      final responseText = await response.stream.bytesToString();
      final decoded = jsonDecode(responseText);

      final text = decoded["text"]?.toString().trim() ?? "";

      if (text.isNotEmpty) {
        setState(() {
          chat.add({"role": "user", "text": text});
        });

        await askAI(text);
      } else {
        resetThinking();
      }
    } catch (_) {
      resetThinking();
    }
  }

  // =========================
  // TEXT TO SPEECH
  // =========================
  Future<void> setupTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      setState(() => aiSpeaking = false);
    });
  }

  Future<void> speak(String text) async {
    setState(() => aiSpeaking = true);
    await _tts.stop();
    await _tts.speak(text);
  }

  // =========================
  // ASK AI
  // =========================
  Future<void> askAI(String question) async {
    final context = buildHealthContext();

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "temperature": 0.2,
          "messages": [
            {
              "role": "system",
              "content":
                  """
You are a personal health voice assistant.

RULES:
- Health questions only
- Use reports as primary knowledge
- No diagnosis or emergency advice
- Calm doctor-like tone

User Health Context:
$context
""",
            },
            {"role": "user", "content": question},
          ],
        }),
      );

      final body = jsonDecode(response.body);
      final answer = body["choices"][0]["message"]["content"].toString();

      setState(() {
        chat.add({"role": "ai", "text": answer});
        aiThinking = false;
        isLoading = false;
      });

      await speak(answer);
    } catch (_) {
      resetThinking();
    }
  }

  void resetThinking() {
    setState(() {
      aiThinking = false;
      isLoading = false;
    });
  }

  // =========================
  // UI (ENHANCED WHISPER STYLE)
  // =========================
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Ask AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 🌈 Background Gradient
          Container(
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
          ),

          // 🫧 Floating Orbs
          ..._floatingOrbs(),

          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...chat.map((msg) {
                      final isUser = msg["role"] == "user";

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _glassBubble(
                          isUser: isUser,
                          child: Text(msg["text"] ?? ""),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1);
                    }),

                    if (aiThinking)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "AI is thinking…",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ).animate().shimmer(),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    Text(
                      isRecording
                          ? "Listening… tap to stop"
                          : aiThinking || aiSpeaking
                          ? "AI is responding…"
                          : "Tap to speak",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    FloatingActionButton(
                          backgroundColor: isRecording ? Colors.red : primary,
                          onPressed: toggleRecording,
                          child: Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            size: 30,
                          ),
                        )
                        .animate(
                          onPlay: (c) =>
                              isRecording ? c.repeat(reverse: true) : null,
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // GLASS CHAT BUBBLE
  // =========================
  Widget _glassBubble({required bool isUser, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: (isUser ? Colors.blueAccent : Colors.greenAccent).withOpacity(
          0.2,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: child,
    );
  }

  // =========================
  // FLOATING ORBS
  // =========================
  List<Widget> _floatingOrbs() {
    final colors = [Colors.purpleAccent, Colors.blueAccent, Colors.tealAccent];

    return List.generate(3, (i) {
      return Positioned(
        top: Random().nextDouble() * 500,
        left: Random().nextDouble() * 300,
        child:
            Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i].withOpacity(0.25),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  duration: (6 + i * 2).seconds,
                  begin: Offset.zero,
                  end: const Offset(40, 60),
                )
                .blurXY(begin: 80, end: 120),
      );
    });
  }
}
