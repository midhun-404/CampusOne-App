# sgmsa

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Repository Setup & Firebase Secrets

To keep the application secure, API keys and sensitive project files have been hidden using `.gitignore`. 
When you clone this project, you will need to provide your own Firebase configuration:

1. **Android Setup**: Add your `google-services.json` to `android/app/`.
2. **Flutter Firebase Config**: Rename `lib/config/firebase_config.example.dart` to `lib/config/firebase_config.dart` and provide your API keys.
3. Ensure no keys are exposed by keeping `.env` or other sensitive templates inside `.gitignore`.
