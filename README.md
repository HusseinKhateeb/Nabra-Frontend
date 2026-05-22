# Nabra — Frontend

> Flutter mobile app for Arabic Audio-Visual Speech Recognition — enabling real-time lip-reading and speech transcription for users with hearing impairments.

---

## 📱 Demo

https://github.com/user-attachments/assets/Sequence_3.mp4

> *Real-time Arabic AVSR session — lip-reading + audio recognition in action*

---

## ✨ Features

- 🎙️ **Real-time AVSR** — camera + microphone input for live Arabic speech recognition
- 👁️ **Lip-reading** — video-based lip movement capture sent to the backend model
- 💬 **Realtime Chat** — WebSocket-based chat using STOMP protocol
- 📖 **Visual Dictionary** — browse Arabic lip-reading entries with video previews
- 🕒 **Session History** — view past recognition sessions and transcription results
- 🔐 **Authentication** — JWT login, registration, and Google Sign-In
- 🌍 **Localization** — multi-language support with Flutter gen-l10n
- 🧭 **Declarative Routing** — go_router for clean navigation
- 🧠 **State Management** — Riverpod for scalable, reactive state

---

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| Framework | Flutter (Dart SDK ≥ 3.3.0) |
| State Management | flutter_riverpod |
| Routing | go_router |
| Networking | dio, http |
| Auth | JWT, flutter_secure_storage, google_sign_in |
| Camera & Audio | camera, record |
| Realtime Chat | stomp_dart_client (WebSocket/STOMP) |
| Video | video_player, video_thumbnail |
| Code Generation | freezed, json_serializable, build_runner |
| Localization | flutter_localizations, intl |

---

## 📋 Prerequisites

- **Flutter SDK** `>=3.3.0 <4.0.0` → [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **Xcode** for device/emulator
- A running instance of the [Nabra Backend](https://github.com/HusseinKhateeb/Nabra-Backend)

---

## ⚙️ Environment Setup

### 1. Clone the repo

```bash
git clone https://github.com/HusseinKhateeb/Nabra-Frontend
cd nabra_frontend
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the API base URL

Find the API configuration file (e.g. `lib/core/config/app_config.dart` or similar) and update the backend base URL:

```dart
const String baseUrl = 'http://localhost:8080'; // local
// or your deployed backend URL
```

### 4. Run code generation

The project uses `freezed` and `json_serializable` for model generation. Run this after any model changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 🚀 Running the App

```bash
# Check connected devices
flutter devices

# Run on a specific device
flutter run -d <device_id>

# Run in debug mode (default)
flutter run

# Run in release mode
flutter run --release
```

> Make sure the backend is running before launching the app, or API calls will fail.

---

## 📁 Project Structure

```
lib/
├── assets/
│   ├── images/          → App images
│   ├── icons/           → Custom icons
│   └── translations/    → Localization ARB files
├── core/
│   ├── config/          → API base URL, app constants
│   ├── network/         → Dio client, interceptors
│   └── router/          → go_router route definitions
├── features/
│   ├── auth/            → Login, register, Google Sign-In
│   ├── avsr/            → Camera input, AVSR session, results
│   ├── chat/            → Realtime chat (STOMP/WebSocket)
│   ├── dictionary/      → Visual lip-reading dictionary
│   ├── history/         → Past AVSR sessions
│   └── admin/           → Admin panel screens
└── main.dart            → App entry point
```

---

## 🔐 Authentication

The app uses **JWT token authentication** stored securely via `flutter_secure_storage`. It also supports **Google Sign-In** via the `google_sign_in` package.

Tokens are automatically attached to API requests via a Dio interceptor.

---

## 🌍 Localization

The app supports multiple languages using Flutter's built-in `gen-l10n` system. Translation files are ARB format, located in `lib/assets/translations/`.

To add a new language:
1. Create a new `.arb` file in the translations folder
2. Run `flutter gen-l10n`

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing |
| `dio` | HTTP client with interceptors |
| `flutter_secure_storage` | Secure JWT token storage |
| `camera` | Camera access for lip-reading capture |
| `record` | Audio recording for speech input |
| `stomp_dart_client` | WebSocket/STOMP for realtime chat |
| `video_player` | Dictionary video playback |
| `google_sign_in` | Google OAuth login |
| `freezed` | Immutable model code generation |
| `json_serializable` | JSON serialization code generation |

---

## 🔗 Related

- [Nabra Backend (Spring Boot)](https://github.com/HusseinKhateeb/Nabra-Backend)
- [Nabra Main Repo](https://github.com/HusseinKhateeb/Nabra)

---

## 👥 Authors

**Hussein Khateeb**
[GitHub](https://github.com/HusseinKhateeb) · [LinkedIn](https://linkedin.com/in/hussein-khateeb-33464a352)

**Imad Swaitti**

**Saja Shawawra**
