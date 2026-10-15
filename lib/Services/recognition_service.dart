import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'voice_assistant_service.dart';

class RecognitionServiceScreen extends StatefulWidget {
  final XFile capturedImage;
  final String languageCode; // "en" or "ur"

  const RecognitionServiceScreen({
    super.key,
    required this.capturedImage,
    required this.languageCode,
  });

  @override
  State<RecognitionServiceScreen> createState() => RecognitionServiceScreenState();
}

class RecognitionServiceScreenState extends State<RecognitionServiceScreen> {
  String resultMessage = "Processing image...";
  bool isHandlingCommand = false;

  static const String recognitionServerUrl =
      "https://amber-lankiness-culprit.ngrok-free.dev/recognize";

  // The model expects 448px images, so the photo is shrunk to this size
  // before it is uploaded.
  static const int modelImageSize = 448;

  @override
  void initState() {
    super.initState();
    analyzeImage();
  }

  @override
  void dispose() {
    VoiceAssistantService.stopListening();
    super.dispose();
  }

  // Resizes the captured photo so its longest side is 448px (aspect ratio
  // preserved) and re-encodes it as JPEG. Interpolation.average is used
  // because the default (nearest-neighbour) makes downscaled text jagged,
  // which hurts reading currency denominations.
  Future<Uint8List> _compressForUpload(Uint8List originalBytes) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) return originalBytes;

    final resized = decoded.width >= decoded.height
        ? img.copyResize(
            decoded,
            width: modelImageSize,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            decoded,
            height: modelImageSize,
            interpolation: img.Interpolation.average,
          );

    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  Future<void> analyzeImage() async {
    try {
      final originalBytes = await widget.capturedImage.readAsBytes();
      final compressedBytes = await _compressForUpload(originalBytes);
      final base64Image = base64Encode(compressedBytes);

      final response = await http
          .post(
            Uri.parse(recognitionServerUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "image": base64Image,
              "language": widget.languageCode,
            }),
          )
          .timeout(const Duration(seconds: 25));

      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('error')) {
        setState(() {
          resultMessage = "Error: ${data['error']}";
        });
        await speakAndListen(resultMessage);
        return;
      }

      // The server already returns a complete, localized, ready-to-speak
      // sentence in spoken_text, so there is no need to build our own message.
      final String spokenText = data['spoken_text'] ??
          "I could not identify this clearly.";

      setState(() {
        resultMessage = spokenText;
      });

      await speakAndListen(spokenText);
    } on TimeoutException {
      final msg = widget.languageCode == "ur"
          ? "درخواست کا وقت ختم ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔"
          : "The request took too long. Please try again.";
      setState(() {
        resultMessage = msg;
      });
      await speakAndListen(msg);
    } on http.ClientException catch (e) {
      // package:http wraps underlying network failures (no connection, DNS
      // failure, fetch blocked, etc.) into ClientException consistently on
      // both mobile and web, so we can detect "no internet" from the
      // message text without needing platform-specific exception types.
      final lowerMsg = e.message.toLowerCase();
      final looksLikeNoInternet = lowerMsg.contains("failed to fetch") ||
          lowerMsg.contains("failed host lookup") ||
          lowerMsg.contains("network") ||
          lowerMsg.contains("socket") ||
          lowerMsg.contains("connection");

      final msg = looksLikeNoInternet
          ? (widget.languageCode == "ur"
              ? "انٹرنیٹ کنکشن نہیں ہے۔ براہ کرم اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔"
              : "No internet connection. Please check your connection and try again.")
          : (widget.languageCode == "ur"
              ? "کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔"
              : "Something went wrong. Please try again.");

      setState(() {
        resultMessage = msg;
      });
      await speakAndListen(msg);
    } catch (e) {
      final errMsg = "Error analyzing image: $e";
      setState(() {
        resultMessage = errMsg;
      });
      await speakAndListen(errMsg);
    }
  }

  Future<void> speakAndListen(String message) async {
    await VoiceAssistantService.speak(message, languageCode: widget.languageCode);

    if (widget.languageCode == "ur") {
      await VoiceAssistantService.speak(
        "کیمرہ اسکرین پر واپس جانے کے لئے 'واپس جائیں' کہیں۔",
        languageCode: "ur",
      );
    } else {
      await VoiceAssistantService.speak(
        "Say 'go back' to return to the camera screen.",
        languageCode: "en",
      );
    }

    if (mounted) {
      listenForCommand();
    }
  }

  void listenForCommand() {
    VoiceAssistantService.stopListening();
    VoiceAssistantService.listen(
      handleVoiceInput,
      onSessionEnded: handleSessionEnded,
      languageCode: widget.languageCode,
    );
  }

  void handleSessionEnded() {
    if (!mounted || isHandlingCommand) return;
    listenForCommand();
  }

  void handleVoiceInput(String result) async {
    if (!mounted || isHandlingCommand) return;
    final input = result.toLowerCase().trim();

    final bool saysGoBack = input.contains("go back") ||
        input.contains("back") ||
        input.contains("واپس") ||
        input.contains("wapis") ||
        input.contains("wapas") ||
        input.contains("vapis") ||
        input.contains("vapas") ||
        input.contains("peeche");

    if (!saysGoBack) return;

    isHandlingCommand = true;
    VoiceAssistantService.stopListening();

    final msg = widget.languageCode == "ur"
        ? "کیمرہ اسکرین پر واپس جا رہے ہیں۔"
        : "Going back to the camera screen.";
    await VoiceAssistantService.speak(msg, languageCode: widget.languageCode);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Recognition Service",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xff0B4F7D),
      ),
      backgroundColor: const Color(0xffF5F0FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      resultMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xff0B4F7D),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(24, 14),
                  painter: BubbleTailPainter(),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  "assets/images/Assistant_girl.png",
                  height: 260,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width / 2 - 12, 0)
      ..lineTo(size.width / 2 + 12, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
