# Nabra Flutter Frontend Scaffold

This is a **ready-to-start** Flutter project structure for the Nabra app.

## Features (scaffold)
- JWT auth flow (login/register placeholders)
- Riverpod + GoRouter
- Dio HTTP client with auth interceptor
- Secure token storage (flutter_secure_storage)
- Modules aligned with backend:
  - Auth/User Management
  - Lip Reading
  - Sessions/History
  - Chat
  - Smart Prediction
  - Visual Dictionary
  - Learning
  - Admin Tools

## Getting Started
1. Install Flutter (stable)
2. From this folder:

```bash
flutter pub get
flutter run
```

## Configure Backend URL
Edit:
- `lib/core/config/app_config.dart`

Default base URL is:
- `http://10.0.2.2:8080/api` (Android emulator)

## Notes
- This scaffold focuses on architecture + wiring.
- Add your ARB files for localization under `lib/l10n/` when ready.
