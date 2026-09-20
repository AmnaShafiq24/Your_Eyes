# Your Eyes

**An AI-powered, voice-first mobile app that helps blind and visually impaired people in Pakistan identify everyday items and currency, independently.**

![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)
![AI](https://img.shields.io/badge/AI-GPT--4o%20mini-412991)

---

## 📖 Overview

Your Eyes is a cross-platform mobile application designed to promote independence for blind and visually impaired individuals in Pakistan. Using only a voice command and the phone's camera, users can identify Pakistani grocery items (fruits and vegetables) and currency notes.

When an image is captured, the app sends it to a secure backend service that uses OpenAI's **GPT-4o mini** API to determine the identity of the grocery item or the denomination of the currency note. The result is converted to speech using **Text-to-Speech (TTS)**, so users get clear audio feedback without ever needing to look at the screen.

By removing the barriers blind and visually impaired people face in recognizing everyday items, Your Eyes empowers users to shop independently, handle money with confidence, and carry out daily tasks without relying on others.

---

## ✨ Features

- 🎙️ **Voice-controlled capture**: trigger the camera hands-free with a voice command
- 🍎 **Fruit & vegetable recognition**: tuned for produce commonly found in Pakistan
- 💵 **Currency note recognition**: identifies Pakistani rupee denominations
- 🔊 **Audio feedback**: results are spoken aloud via Text-to-Speech
- ♿ **Accessibility-first design**: usable without looking at the screen
- 🔒 **Secure backend**: API keys never live on the device
- 📱 **Cross-platform**: runs on both Android and iOS

---

## 🔄 How It Works

```
┌────────────┐   voice    ┌────────────┐   image    ┌──────────────┐   image    ┌───────────────┐
│    User    │ ─────────► │ Mobile App │ ─────────► │   Backend    │ ─────────► │ GPT-4o mini   │
└────────────┘            └────────────┘            │   Service    │ ◄───────── │     API       │
       ▲                        │                   └──────────────┘   result   └───────────────┘
       │        audio           │  result text            │
       └────────────────────────┘ ◄───────────────────────┘
              (Text-to-Speech)
```

1. The user says a voice command to activate the camera.
2. The app captures an image of the item or note.
3. The image is sent to the secure backend.
4. The backend queries GPT-4o mini to identify the item or denomination.
5. The result is returned to the app and read aloud using TTS.

---

## 🛠️ Tech Stack

### Tools

| Tool | Version | Rationale |
|------|---------|-----------|
| Flutter | 3.x | Cross-platform mobile development |
| Git & GitHub | Latest | Version control system |
| Canva | Latest | Logo designing |

### Libraries

| Library | Version | Rationale |
|---------|---------|-----------|
| `flutter_tts` | 3.x | Text-to-Speech for voice feedback |
| `flutter_camera` plugin | Latest | Capture real-time images from the device camera for object detection |
| `intl` + Urdu TTS | Latest | Support both Urdu and English for accessibility |

### Technologies

| Technology | Version | Rationale |
|------------|---------|-----------|
| OpenAI GPT-4o mini API | Latest | Detects and labels currency notes and grocery items from captured images |
| Firebase Cloud Functions (Python) | Latest | Backend proxy that securely calls the OpenAI GPT-4o mini API and returns spoken-ready results |

---

## 📂 Project Structure

> Adjust to match your repository.

```
your-eyes/
├── app/                # Mobile application source code
│   ├── lib/ or src/
│   └── ...
├── backend/            # Backend service (API proxy to OpenAI)
│   ├── src/
│   ├── .env.example
│   └── ...
├── docs/               # Documentation, screenshots, reports
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)
- Android Studio and/or Xcode
- A [Firebase](https://firebase.google.com/) project with Cloud Functions enabled (Blaze plan required for external API calls)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- An [OpenAI API key](https://platform.openai.com/api-keys)
- A physical device (recommended) with camera and microphone

### 1. Clone the repository

```bash
git clone https://github.com/AmnaShafiq24/Your_Eyes.git
cd Your-Eyes
```

### 2. Deploy the backend (Firebase Cloud Functions)

```bash
cd functions
pip install -r requirements.txt

# store your OpenAI key as a secret (never commit it)
firebase functions:secrets:set OPENAI_API_KEY

# deploy
firebase deploy --only functions
```

Copy the deployed function URL, you'll need it in the app config.

### 3. Run the Flutter app

```bash
flutter pub get
# set your Cloud Function URL in the app's config file, then:
flutter run
```

> ⚠️ **Never commit API keys or secrets to version control.**

---

## 🗣️ Usage

1. Open the app. It greets you with audio instructions.
2. Choose **English** or **Urdu** by tapping or by saying the language name.
3. On the camera screen, use the voice command (or the capture button) to take a photo.
4. Hold the item or currency note in front of the camera.
5. Listen to the spoken result, e.g., *"Currency notes: 100, 1000 rupees."*
6. Say **"go back"** at any time to return to the previous screen.

---

## 🔐 Privacy & Security

- Images are sent only to identify the item and are not intended to be stored.
- The OpenAI API key is kept server-side in Firebase and never exposed in the app.
- All communication with the backend occurs over HTTPS.

---

## ⚠️ Limitations

- Requires an active internet connection.
- Accuracy depends on lighting, image clarity, and camera angle.
- AI predictions can occasionally be wrong, so users should double-check before high-stakes decisions such as large payments.

---

## 🗺️ Roadmap

- [x] Fruit & vegetable identification
- [x] Pakistani currency note recognition
- [x] Voice command + Text-to-Speech feedback
- [x] English and Urdu language support
- [ ] 💊 Medicine recognition
- [ ] 📦 Broader object identification
- [ ] 🧭 Indoor navigation assistance
- [ ] 📴 Offline recognition mode

Looking ahead, Your Eyes has significant potential for expansion. These enhancements will extend the app's role as a comprehensive independence tool for its users.

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes (`git commit -m "Add your feature"`)
4. Push to the branch (`git push origin feature/your-feature`)
5. Open a Pull Request

Please keep accessibility in mind with every change: if a feature can't be used without sight, it isn't finished.

---

## 👥 Team

| Name | Role |
|------|------|
| `Amna Shafiq ` | `Full Stack Developer` |
| `Haseeba Maqsood ` | `Full Stack Developer` |


---

## 🙏 Acknowledgements

- [OpenAI](https://openai.com/) for the GPT-4o mini API
- Firebase and Flutter teams
- The blind and visually impaired community in Pakistan, whose needs inspired this project

---

<p align="center"><b>Your Eyes: see the world through sound.</b></p>
