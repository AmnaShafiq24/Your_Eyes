# Your Eyes

**An AI-powered, voice-first mobile app that helps blind and visually impaired people in Pakistan identify everyday items and currency, independently.**

---

## 📖 Overview

Your Eyes is a cross-platform mobile application designed to promote independence for blind and visually impaired individuals in Pakistan. Using only a voice command and the phone's camera, users can identify Pakistani grocery items (fruits and vegetables) and currency notes.

When an image is captured, the app sends it to our own inference server, which runs a **fine-tuned Qwen2.5-VL vision-language model** to determine the identity of the grocery item or the denomination of the currency note. The result is converted to speech using **Text-to-Speech (TTS)**, so users get clear audio feedback without ever needing to look at the screen.

By removing the barriers blind and visually impaired people face in recognizing everyday items, Your Eyes empowers users to shop independently, handle money with confidence, and carry out daily tasks without relying on others.

---

## ✨ Features

- 🎙️ **Voice-controlled capture**: trigger the camera hands-free with a voice command
- 🍎 **Fruit & vegetable recognition**: tuned for produce commonly found in Pakistan
- 💵 **Currency note recognition**: identifies Pakistani rupee denominations, including several notes in one photo
- 🧠 **Custom fine-tuned model**: our own LoRA-tuned Qwen2.5-VL, not a general-purpose third-party API
- 🔊 **Audio feedback**: results are spoken aloud via Text-to-Speech
- 🌐 **English and Urdu**: voice commands and spoken results in both languages
- ♿ **Accessibility-first design**: usable without looking at the screen
- 🔒 **No third-party AI API**: images are processed by our own model, and no AI-provider keys live on the device
- 📱 **Cross-platform**: runs on both Android and iOS

---

## 🔄 How It Works

```
┌────────────┐   voice    ┌────────────┐   image    ┌───────────────────┐   image    ┌──────────────────────┐
│    User    │ ─────────► │ Mobile App │ ─────────► │ Inference Server  │ ─────────► │ Qwen2.5-VL-3B (4-bit)│
└────────────┘            └────────────┘            │    (FastAPI)      │ ◄───────── │ + our LoRA adapter   │
       ▲                        │                   └───────────────────┘   result   └──────────────────────┘
       │        audio           │  spoken_text              │
       └────────────────────────┘ ◄─────────────────────────┘
              (Text-to-Speech)
```

1. The user says a voice command to activate the camera.
2. The app captures an image of the item or note.
3. The image is sent, with the user's chosen language, to the inference server.
4. The server runs the fine-tuned Qwen2.5-VL model, which identifies the item or denomination and writes a short, ready-to-speak sentence in English or Urdu.
5. The result is returned to the app and read aloud using TTS.

---

## 🧠 The Model

Your Eyes uses a vision-language model we fine-tuned ourselves for this task.

| Detail | Value |
|--------|-------|
| Base model | `unsloth/Qwen2.5-VL-3B-Instruct-bnb-4bit` (Qwen2.5-VL, 3B parameters, 4-bit quantized) |
| Fine-tuning method | LoRA (rank 16, alpha 16) trained with [Unsloth](https://github.com/unslothai/unsloth) |
| Task | Identify Pakistani currency notes (denominations) and common fruits and vegetables |
| Output | A short JSON response whose `spoken_text` field is read aloud to the user |
| Validation result | 295 / 300 correct (98.3%) on a 300-image validation set: currency 177/180, fruits and vegetables 118/120 |

> The validation figure comes from our own held-out check, not an independent benchmark. Real-world accuracy still depends on lighting, distance, and camera angle.

The LoRA adapter (`lora_model_your_eyes`) is loaded on top of the base model at server start-up.

---

## 🛠️ Tech Stack

### Tools

| Tool | Version | Rationale |
|------|---------|-----------|
| Flutter | 3.x | Cross-platform mobile development |
| Google Colab | Latest | Fine-tuning the model and running the inference server (GPU) |
| Git & GitHub | Latest | Version control system |
| Canva | Latest | Logo designing |

### Libraries

| Library | Version | Rationale |
|---------|---------|-----------|
| `flutter_tts` | 3.x | Text-to-Speech for voice feedback |
| `camera` | Latest | Capture images from the device camera |
| `speech_to_text` | Latest | Voice commands in English and Urdu |
| `permission_handler` | Latest | Camera and microphone permissions |
| `shared_preferences` | Latest | Remember the user's language choice |
| `http` | Latest | Send captured images to the inference server |

### Technologies

| Technology | Version | Rationale |
|------------|---------|-----------|
| Qwen2.5-VL-3B-Instruct (4-bit) | n/a | Base vision-language model |
| LoRA adapter (Unsloth + PEFT) | n/a | Fine-tuned weights that specialise the model for Pakistani currency, fruits, and vegetables |
| FastAPI + Uvicorn | Latest | Inference server that receives images and returns spoken-ready results |
| ngrok | Latest | Exposes the Colab-hosted server to the app during development |

---

## 📂 Project Structure

> Adjust to match your repository.

```
Your_Eyes/
├── lib/                          # Flutter app source code
│   ├── Services/                 # Voice assistant, STT, TTS, recognition client
│   └── ...
├── android/ ios/                 # Platform projects
├── backend/
│   └── your_eyes_qwen_vl_server.ipynb   # Notebook that loads the model and serves it
├── docs/                         # Documentation, screenshots, reports
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)
- Android Studio and/or Xcode
- A Google account with access to [Google Colab](https://colab.research.google.com/) and a GPU runtime (a T4 is enough)
- A free [ngrok](https://ngrok.com/) account and authtoken
- The trained LoRA adapter (`lora_model_your_eyes`) as a zip file
- A physical device (recommended) with camera and microphone

### 1. Clone the repository

```bash
git clone https://github.com/AmnaShafiq24/Your_Eyes.git
cd Your_Eyes
```

### 2. Start the model server (Google Colab)

1. Open `backend/your_eyes_qwen_vl_server.ipynb` in Google Colab.
2. Set the runtime to a GPU (**Runtime → Change runtime type**).
3. Paste your ngrok authtoken into the config cell.
4. Run the cells from top to bottom. When asked, upload `lora_model_your_eyes.zip`.
5. Copy the public URL printed at the end of the notebook.

> ⚠️ **Development setup.** With the free ngrok tier the URL changes every time the notebook restarts, and Colab stops the server when the session ends. For regular use, host the same server on a persistent GPU machine.

### 3. Point the app at your server

Set the server address in the app's recognition service (`lib/Services/recognition_service.dart`):

```dart
static const String recognitionServerUrl = "https://<your-public-url>/recognize";
```

### 4. Run the Flutter app

```bash
flutter pub get
flutter run
```

> ⚠️ **Never commit tokens or secrets (such as your ngrok authtoken) to version control.**

---

## 🗣️ Usage

1. Open the app. It greets you with audio instructions.
2. Choose **English** or **Urdu** by tapping or by saying the language name.
3. On the camera screen, use the voice command (or the capture button) to take a photo.
4. Hold the item or currency note in front of the camera. For a currency note, open it fully and keep it flat.
5. Listen to the spoken result, e.g., *"Currency notes: 100, 1000 rupees."*
6. Say **"go back"** at any time to return to the previous screen.
7. Open **Settings** by voice or by tapping to switch between English and Urdu at any time.

---

## 🔐 Privacy & Security

- Images are sent only to identify the item and are not intended to be stored.
- Recognition is done by our own fine-tuned model. No third-party AI API (such as OpenAI) receives the images, and no AI-provider keys are stored in the app.
- Communication with the inference server occurs over HTTPS.

---

## ⚠️ Limitations

- Requires an active internet connection, and the inference server must be running.
- Response time depends on the GPU the server runs on.
- Accuracy depends on lighting, image clarity, and camera angle.
- The model recognises the categories it was fine-tuned on (Pakistani currency notes, and common fruits and vegetables); other objects may be described less reliably.
- AI predictions can occasionally be wrong, so users should double-check before high-stakes decisions such as large payments.

---

## 🗺️ Roadmap

- [x] Fruit & vegetable identification
- [x] Pakistani currency note recognition
- [x] Voice command + Text-to-Speech feedback
- [x] English and Urdu language support
- [x] Custom fine-tuned vision-language model
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

- The [Qwen team at Alibaba Cloud](https://github.com/QwenLM/Qwen2.5-VL) for the Qwen2.5-VL model
- [Unsloth](https://github.com/unslothai/unsloth) for efficient fine-tuning
- [Hugging Face](https://huggingface.co/) for hosting the base model
- Flutter and Google Colab
- The blind and visually impaired community in Pakistan, whose needs inspired this project

---

<p align="center"><b>Your Eyes: see the world through sound.</b></p>
