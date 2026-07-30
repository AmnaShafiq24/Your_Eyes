import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText speech = SpeechToText();
  bool isInitialized = false;
  Function()? onSessionEnded;

  Future<bool> initialize() async {
    if (isInitialized) return true;

    isInitialized = await speech.initialize(
      onError: (error) => debugPrint("STT error: ${error.errorMsg}"),
      onStatus: (status) {
        debugPrint("STT status: $status");

        if (status == "done" || status == "notListening") {
          onSessionEnded?.call();
        }
      },
    );
    return isInitialized;
  }

  void startListening(
      Function(String) onResult, {
        Function()? onSessionEnded,
      }) async {
    if (speech.isListening) return;
    onSessionEnded = onSessionEnded;

    await speech.listen(
      onResult: (result) {
        debugPrint("STT heard: ${result.recognizedWords} (final: ${result.finalResult})");
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 8),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );
  }

  void stopListening() {
    onSessionEnded = null;
    speech.stop();
  }
}