import 'tts_service.dart';
import 'stt_service.dart';

class VoiceAssistantService {
  static final STTService stt = STTService();

  static Future<void> speak(String text, {String languageCode = "en"}) async {
    await TtsService.init(languageCode: languageCode);
    await TtsService.speak(text);
  }

  static String _localeIdFor(String languageCode) {
    switch (languageCode) {
      case "ur":
        return "ur-PK";
      case "en":
      default:
        return "en-US";
    }
  }

  static Future<void> listen(
      Function(String) onResult, {
        Function()? onSessionEnded,
        String languageCode = "en",
      }) async {
    final initialized = await stt.initialize();
    if (initialized) {
      stt.startListening(
        onResult,
        onSessionEnded: onSessionEnded,
        localeId: _localeIdFor(languageCode),
      );
    }
  }

  static void stopListening() {
    stt.stopListening();
  }

  static Future<void> stopSpeaking() async {
    await TtsService.stop();
  }
}