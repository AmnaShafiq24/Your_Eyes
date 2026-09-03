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

  Future<void> startListening(
      Function(String) onResult, {
        Function()? onSessionEnded,
        String? localeId,
      }) async {
    // Make sure any previous session is fully stopped before starting a new one
    if (speech.isListening) {
      await stopListening();
    }

    this.onSessionEnded = onSessionEnded;

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
      localeId: localeId,
    );
  }

  Future<void> stopListening() async {
    onSessionEnded = null;
    if (speech.isListening) {
      await speech.stop();
      // Give the browser/engine a brief moment to fully release the session on web
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}