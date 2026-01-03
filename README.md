After cloning this repository
=============================

Follow these steps after cloning to run the app locally and restore required secrets safely.

1) Install prerequisites

```bash
# Install Flutter and confirm setup
flutter doctor

# Fetch dependencies
cd healt
flutter pub get
```

2) Restore Firebase config (Android)

- Obtain `google-services.json` from your Firebase project and place it at:

  android/app/google-services.json

- DO NOT commit this file. Add it to `.gitignore` if it isn't already.

3) Restore Firebase config (iOS)

- If you use iOS Firebase, add `GoogleService-Info.plist` to `ios/Runner`.

4) Provide OpenAI API key (recommended: use dart-define)

- This project previously contained a hard-coded OpenAI key which has been redacted.
- Recommended: supply your key at build/run-time using `--dart-define`:

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-...            # run on device

# Or build with the key
flutter build apk --release --dart-define=OPENAI_API_KEY=sk-...
```

- Alternative: use `flutter_dotenv` or CI secret variables and load securely in code.

5) Replace local placeholders in source (if applicable)

- The code currently contains `REDACTED` placeholders where keys were removed.
- Either update code to read from `const String.fromEnvironment('OPENAI_API_KEY')` or set the values securely before running.

6) Security and cleanup

- Rotate any keys that were exposed publicly. Revoke/regenerate them in provider consoles.
- To purge secrets from git history, use `git-filter-repo` or BFG — I can help run this if desired.

7) Run the app

```bash
flutter run
```

8) Optional useful commands

```bash
# Add google-services.json to .gitignore
echo "android/app/google-services.json" >> .gitignore
git add .gitignore
git commit -m "Ignore local Firebase config"
```

9) Need help?

- I can: (a) add the `.gitignore` change and commit it, (b) patch the code to read `OPENAI_API_KEY` from `--dart-define`, or (c) help purge secrets from git history. Tell me which you'd like.
