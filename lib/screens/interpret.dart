import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InterpretScreen extends StatefulWidget {
  const InterpretScreen({super.key});

  @override
  State<InterpretScreen> createState() => _InterpretScreenState();
}

class _InterpretScreenState extends State<InterpretScreen> {
  bool isLoading = false;

  String summary = "";
  List<String> recommendations = [];
  List<String> reminders = [];
  String riskLevel = "";

  String selectedLanguage = "en";
  String? lastImagePath;

  final ImagePicker _imagePicker = ImagePicker();

  static const String openAiApiKey = "REDACTED";

  // =========================
  // OCR
  // =========================
  Future<String> extractTextFromImage(File file) async {
    try {
      final inputImage = InputImage.fromFile(file);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      return result.text;
    } catch (_) {
      return "";
    }
  }

  // =========================
  // FILE PICKERS
  // =========================
  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      showMessage("PDF OCR not implemented yet");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source);
    if (image == null) return;

    lastImagePath = image.path;

    final text = await extractTextFromImage(File(image.path));
    if (text.trim().isEmpty) {
      showMessage("No readable text found");
      return;
    }

    await interpretReport(text);
  }

  // =========================
  // HELPERS
  // =========================
  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String safeString(dynamic v) => v == null ? "" : v.toString();

  List<String> safeList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return [];
  }

  String languageName() {
    switch (selectedLanguage) {
      case "hi":
        return "Hindi";
      case "te":
        return "Telugu";
      default:
        return "English";
    }
  }

  // =========================
  // SAVE REPORT
  // =========================
  Future<void> saveReport(String rawText) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList("reports") ?? [];

    final report = {
      "summary": summary,
      "recommendations": recommendations,
      "reminders": reminders,
      "risk": riskLevel,
      "language": selectedLanguage,
      "image": lastImagePath,
      "time": DateTime.now().toIso8601String(),
      "raw_text": rawText,
    };

    reports.insert(0, jsonEncode(report));
    await prefs.setStringList("reports", reports);
  }

  // =========================
  // OPENAI INTERPRETATION
  // =========================
  Future<void> interpretReport(String reportText) async {
    setState(() {
      isLoading = true;
      summary = "";
      recommendations = [];
      reminders = [];
      riskLevel = "";
    });

    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "temperature": 0.1,
          "messages": [
            {"role": "system", "content": "Return ONLY valid JSON."},
            {
              "role": "user",
              "content":
                  """
You are a medical explainer speaking to a normal person.

LANGUAGE:
- Respond fully in ${languageName()}

Return JSON ONLY:
{
  "summary": "...",
  "recommendations": ["..."],
  "reminders": ["..."],
  "risk_level": "low | moderate | high"
}

REPORT:
$reportText
""",
            },
          ],
        }),
      );

      final body = jsonDecode(response.body);
      final msg = body["choices"][0]["message"]["content"];
      final parsed = jsonDecode(msg);

      setState(() {
        summary = safeString(parsed["summary"]);
        recommendations = safeList(parsed["recommendations"]);
        reminders = safeList(parsed["reminders"]);
        riskLevel = safeString(parsed["risk_level"]).toLowerCase();
        isLoading = false;
      });

      await saveReport(reportText);
    } catch (_) {
      setState(() => isLoading = false);
      showMessage("Interpretation failed");
    }
  }

  // =========================
  // RISK UI
  // =========================
  Color getRiskColor() {
    switch (riskLevel) {
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

  String getRiskText() {
    switch (riskLevel) {
      case "high":
        return "Needs Attention";
      case "moderate":
        return "Minor Concern";
      case "low":
        return "All Good";
      default:
        return "";
    }
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
        title: const Text(
          "Interpret Report",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _animatedBackground(),
          ..._floatingOrbs(),

          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _languageSelector(),
              const SizedBox(height: 16),
              _uploadCard(),

              const SizedBox(height: 24),

              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ).animate().fadeIn(),

              if (!isLoading && summary.isNotEmpty) ...[
                _riskBadge(),
                const SizedBox(height: 20),
                _glassSection("🧠 What this means", summary),
                _glassList("✅ What you can do", recommendations),
                _glassList("⏰ Keep in mind", reminders),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // COMPONENTS
  // =========================
  Widget _languageSelector() {
    return Wrap(
      spacing: 10,
      children: [
        _langChip("en", "English"),
        _langChip("hi", "Hindi"),
        _langChip("te", "Telugu"),
      ],
    );
  }

  Widget _langChip(String code, String label) {
    final selected = selectedLanguage == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => selectedLanguage = code),
    );
  }

  Widget _uploadCard() {
    return _glassCard(
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 40),
          const SizedBox(height: 12),
          const Text(
            "Upload Medical Report",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: showUploadOptions,
            child: const Text("Choose File"),
          ),
        ],
      ),
    );
  }

  Widget _riskBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: getRiskColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: getRiskColor()),
          const SizedBox(width: 8),
          Text(
            getRiskText(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: getRiskColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection(String title, String text) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _glassList(String title, List<String> items) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (e) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _animatedBackground() {
    return AnimatedContainer(
      duration: 6.seconds,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE9FE), Color(0xFFE0F2FE), Color(0xFFF6F7FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  List<Widget> _floatingOrbs() {
    final colors = [Colors.purpleAccent, Colors.blueAccent, Colors.tealAccent];

    return List.generate(3, (i) {
      return Positioned(
        top: Random().nextDouble() * 500,
        left: Random().nextDouble() * 300,
        child:
            Container(
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
                .blurXY(begin: 70, end: 120),
      );
    });
  }

  void showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Upload Image"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text("Upload PDF"),
              onTap: () {
                Navigator.pop(context);
                pickPdf();
              },
            ),
          ],
        ),
      ),
    );
  }
}
