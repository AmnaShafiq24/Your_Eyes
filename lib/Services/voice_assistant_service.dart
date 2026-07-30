import 'tts_service.dart';
import 'stt_service.dart';

class VoiceAssistantService {
  static final STTService stt = STTService();
  static Future<void> speak(String text, {String languageCode = "en"}) async {
    await TtsService.init(languageCode: languageCode);
    await TtsService.speak(text);
  }

  static Future<void> listen(
      Function(String) onResult, {
        Function()? onSessionEnded,
      }) async {
    final initialized = await stt.initialize();
    if (initialized) {
      stt.startListening(onResult, onSessionEnded: onSessionEnded);
    }
  }

  static void stopListening() {
    stt.stopListening();
  }

  static Future<void> stopSpeaking() async {
    await TtsService.stop();
  }
}