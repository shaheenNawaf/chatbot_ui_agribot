# 🌾 Agri-Pinoy AI

A Flutter-based AI chatbot that helps Filipino farmers with practical advice on growing common Pinoy crops — rice, cacao, and more. Built with a RAG (Retrieval-Augmented Generation) backend, real-time evaluation pipeline, and Supabase data logging.

---

## 📱 Features

- **AI Chat** — Ask questions about planting, harvesting, fertilizing, and pest control for common Filipino crops
- **Evaluation Mode** — A structured onboarding flow that collects 10 AI response ratings before the user enters the main chat
- **Persistent Feedback Banner** — A non-intrusive banner that reappears on every app launch, encouraging users to fill out a Google Form feedback survey
- **Response Depth Control** — Users can choose between Concise, Balanced, Deep, and Ultra-Deep AI responses via a `top_k` setting
- **Supabase Logging** — All evaluation ratings are saved to Supabase for analysis
- **Device ID Tracking** — Anonymous device-level identification for consistent data attribution across sessions
- **Fallback Detection** — Automatically detects when the AI cannot find relevant crop information and visually flags those responses

---

## 🗂️ Project Structure

```
lib/
├── models/
│   └── message_model.dart          # ChatMessage data model
├── providers/
│   └── chat_provider.dart          # Chat state, session management, API calls
├── screens/
│   ├── chat_screen.dart            # Main chat UI
│   └── onboarding_eval_screen.dart # Evaluation mode screen
├── services/
│   ├── device_id_service.dart      # Anonymous device ID (Android + Web)
│   └── supabase_eval_service.dart  # Supabase eval data persistence
├── widgets/
│   ├── google_form_modal.dart      # In-app Google Form iframe modal
│   ├── onboarding_modal.dart       # First-launch onboarding carousel
│   ├── rating_bottom_sheet.dart    # Bottom sheet rating widget (legacy)
│   ├── web_registry_stub.dart      # Platform stub for native builds
│   └── web_registry_web.dart       # iframe registration for web builds
└── main.dart                       # App entry point
```

---

## 🔄 User Flow

```
App Launch
    │
    ▼
Onboarding Complete? ──No──▶ Onboarding Modal (carousel)
    │                               │
   Yes                              ▼
    │                     Evaluation Mode (10 Q&A + ratings)
    │                               │
    └───────────────────────────────▼
                          Chat Screen
                          + Persistent Feedback Banner
```

1. **First launch** — The onboarding carousel introduces the app
2. **Evaluation mode** — 10 randomly selected crop questions are auto-sent to the AI; the user rates each response 1–5
3. **Chat screen** — Full free-form chat with quick prompt suggestions, depth settings, and a persistent feedback banner

---

## 🧩 Key Components

### `OnboardingEvalScreen`
Runs a sequential 10-question evaluation session on first launch. Each question is auto-sent to the API, the AI response is displayed, and an inline 1–5 relevance rating prompt appears beneath it. Ratings are saved to Supabase with the device ID, question, answer, and question index.

### `ChatProvider`
Manages chat state using `ChangeNotifier`. Handles session IDs, `top_k` configuration, message history, and API communication. Includes fallback detection based on keyword matching in AI responses.

### `ChatScreen`
Main UI screen. Features:
- Persistent Google Form feedback banner (session-dismissable via X; reappears on next launch)
- AppBar feedback button to open the form at any time
- `top_k` depth selector in a settings bottom sheet
- Quick prompt suggestions on first message
- Fallback response highlighting with a "Start New Chat" CTA

### `DeviceIdService`
Returns a stable anonymous device ID — uses Android ID on Android devices, and a UUID stored in `SharedPreferences` on web.

### `GoogleFormModal`
Renders the Google Form inside an in-app iframe modal (web) or WebView-equivalent. Opened via the feedback banner or the AppBar feedback button.

---

## ⚙️ Environment Variables

The app uses `--dart-define` environment variables at build time:

| Variable | Description |
|---|---|
| `API_BASE_URL` | Base URL for the RAG chat API |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous API key |

**Example build command:**
```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-api.com/chat \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 🗄️ Supabase Schema

Evaluation responses are stored via `SupabaseEvalService.saveEvalResponse()` with the following fields:

| Field | Type | Description |
|---|---|---|
| `device_id` | `text` | Anonymous device identifier |
| `question` | `text` | The evaluation question sent to the AI |
| `answer` | `text` | The AI's response |
| `rating` | `int` | User relevance rating (1–5) |
| `question_index` | `int` | Question position in the session (1–10) |

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API requests |
| `flutter_markdown` | Markdown rendering in chat bubbles |
| `google_fonts` | Poppins & Roboto typography |
| `shared_preferences` | Local persistence (onboarding state) |
| `supabase_flutter` | Supabase client |
| `device_info_plus` | Android device ID |
| `uuid` | UUID generation for web device IDs |
| `intl` | Timestamp formatting |

---

## 🚀 Getting Started

**Prerequisites:** Flutter SDK, a running RAG API endpoint, and a Supabase project.

```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://your-api.com/chat \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Run on Android
flutter run -d android \
  --dart-define=API_BASE_URL=https://your-api.com/chat \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 🌱 Supported Crops

The current evaluation and quick prompt pool covers:

- **Rice** — land preparation, seeding rates, transplanting, harvesting, pest control (golden kuhol), weed management, fertilization, water management
- **Cacao** — tree spacing, shade requirements, pod ripeness, harvesting technique, fermentation, disease management (black pod rot)

---

## 📝 Notes

- The feedback banner appears on every app launch and can be dismissed (X) for the current session only — it will reappear on the next launch by design, to encourage form submissions
- The AppBar feedback button (📋) allows users to open the Google Form at any time regardless of banner state
- Fallback responses (where the AI cannot find relevant crop data) are visually distinguished with an orange bubble and a "Start New Chat" button
- The `rating_bottom_sheet.dart` widget is retained for potential reuse but the evaluation flow currently uses inline ratings within the chat bubbles
