AI HEALTH APP (HealthiE)
======================

An AI-powered Flutter mobile application that helps users interpret medical reports,
ask health-related questions, and manage health records in a simple and user-friendly way.

This application uses Artificial Intelligence, Firebase, and Flutter to make medical
information easier to understand for everyone.


FEATURES
--------

- Secure Google Sign-In
- Upload Medical Reports (PDF or Image)
- AI-based Medical Report Interpretation
- Multi-language Support (English, Hindi, Telugu)
- Ask AI through Chat or Voice
- Medicine Reminders
- Health Report History
- Privacy-focused design


APP SCREENSHOTS
---------------

Screenshots are included in the repository under the "screenshots" folder.

- screenshots/login.png   : Login Screen
- screenshots/home.png    : Home Dashboard
- screenshots/upload.png  : Upload Medical Report
- screenshots/result1.png : AI Interpretation Result
- screenshots/result2.png : Detailed Health Explanation


TECH STACK
----------

Frontend        : Flutter (Dart)
Backend         : Firebase
Authentication  : Google Sign-In
AI Engine       : OpenAI API
Platform        : Android (iOS ready)


GETTING STARTED
---------------

1. Clone the repository

   git clone https://github.com/MoteeshA/AI_Health_App.git
   cd Health


2. Install dependencies

   flutter pub get


3. Firebase Configuration (Android)

   - Download google-services.json from Firebase Console
   - Place the file at:

     android/app/google-services.json

   IMPORTANT:
   This file must NOT be committed to GitHub.
   Ensure it is listed in .gitignore.


4. Firebase Configuration (iOS - Optional)

   If running on iOS, place:

   ios/Runner/GoogleService-Info.plist


5. OpenAI API Key Setup (Secure Method)

   This project does NOT store API keys in source code.

   Run the app using:

   flutter run --dart-define=OPENAI_API_KEY=sk-xxxxxxxx

   Build release APK using:

   flutter build apk --release --dart-define=OPENAI_API_KEY=sk-xxxxxxxx

   API key is accessed in code using:

   String.fromEnvironment('OPENAI_API_KEY');


6. Run the application

   flutter run


SECURITY NOTES
--------------

- API keys are never committed to the repository
- Rotate any keys that were exposed previously
- Git history can be cleaned using git-filter-repo if required


PROJECT STRUCTURE (SIMPLIFIED)
------------------------------

Health/
|
|-- lib/
|   |-- screens/
|   |-- services/
|   |-- widgets/
|   |-- main.dart
|
|-- android/
|-- ios/
|-- screenshots/
|-- README.md
|-- pubspec.yaml


CURRENT STATUS
--------------

- Core features implemented
- UI and UX improvements in progress
- iOS build and Play Store release planned


DISCLAIMER
----------

This application does NOT replace professional medical advice.
Always consult a certified healthcare provider before making medical decisions.


AUTHOR
------

Name   : Moteesh Annadanam
GitHub : https://github.com/MoteeshA


If you like this project, please give it a star on GitHub.
