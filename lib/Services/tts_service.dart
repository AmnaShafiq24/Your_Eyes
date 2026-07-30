import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts tts = FlutterTts();
  static bool configured = false;
  static String? currentLanguage;

  static Future<void> init({
    required String languageCode,
  }) async {
    if (!configured) {
      await tts.awaitSpeakCompletion(true);
      await tts.setSpeechRate(0.5);
      await tts.setPitch(1.0);
      configured = true;
    }

    if (currentLanguage != languageCode) {
      await tts.setLanguage(languageCode);
      currentLanguage = languageCode;
    }
  }

  static Future<void> speak(String text) async {
    debugPrint("TTS speaking: $text");
    await tts.speak(text);
    debugPrint("TTS finished speaking");
  }

  // Stop speaking
  static Future<void> stop() async {
    await tts.stop();
  }
}