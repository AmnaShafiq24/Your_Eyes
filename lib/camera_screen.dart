import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Services/voice_assistant_service.dart';
import 'Services/recognition_service.dart';
import 'Settings_screen.dart';

class CaptureImageScreen extends StatefulWidget {
  final String languageCode; // "en" or "ur", initial value

  const CaptureImageScreen({super.key, required this.languageCode});

  @override
  State<CaptureImageScreen> createState() => CaptureImageScreenState();
}

class CaptureImageScreenState extends State<CaptureImageScreen> {
  CameraController? controller;
  Future<void>? initializeControllerFuture;
  Uint8List? capturedImageBytes;
  bool isHandlingCommand = false;

  // Mutable local copy so this screen reflects language changes made from
  // Settings immediately, without needing to rebuild/recreate this screen.
  late String currentLanguageCode;

  @override
  void initState() {
    super.initState();
    currentLanguageCode = widget.languageCode;
    setupCamera();
    startVoiceAssistant();
  }

  Future<void> setupCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      initializeControllerFuture = controller!.initialize();
      await initializeControllerFuture;
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission denied")),
        );
      }
    }
  }

  void startVoiceAssistant() async {
    await giveGuidance(); // initial guidance
    listenForCommand();
  }

  void listenForCommand() {
    VoiceAssistantService.stopListening();
    VoiceAssistantService.listen(
      handleVoiceInput,
      onSessionEnded: handleSessionEnded,
      languageCode: currentLanguageCode,
    );
  }

  void handleSessionEnded() {
    if (!mounted || isHandlingCommand) return;
    listenForCommand();
  }

  Future<void> giveGuidance() async {
    if (!mounted) return;
    if (currentLanguageCode == "ur") {
      await VoiceAssistantService.speak(
        "تصویر لینے کے لئے 'تصویر لو' کہیں۔ سیٹنگز کھولنے کے لئے 'سیٹنگز' کہیں۔ اگر آپ کرنسی نوٹ کی تصویر لے رہے ہیں تو براہ کرم نوٹ کو اچھی طرح کھول کر تصویر لیں۔",
        languageCode: "ur",
      );
    } else {
      await VoiceAssistantService.speak(
        "Say 'Capture' to take a picture. Say 'Open Settings' to open settings. If you are testing a currency note, please make sure it is fully opened before capturing.",
        languageCode: "en",
      );
    }
  }

  void handleVoiceInput(String result) async {
    if (!mounted || isHandlingCommand) return;
    final input = result.toLowerCase().trim();
    String? matchedAction;

    if (currentLanguageCode == "ur") {

      final bool saysCapture = input.contains("tasveer") ||
          input.contains("tasvir") ||
          input.contains("تصویر") ||
          input.contains("کیپچر");

      final bool saysSettings = input.contains("سیٹنگ") ||
          input.contains("setting") ||
          input.contains("settings");

      if (saysCapture) {
        matchedAction = "capture";
      } else if (saysSettings) {
        matchedAction = "settings";
      }
    } else {
      if (input.contains("capture")) {
        matchedAction = "capture";
      } else if (input.contains("open settings") || input.contains("settings")) {
        matchedAction = "settings";
      }
    }

    if (matchedAction == null) return;

    isHandlingCommand = true;
    VoiceAssistantService.stopListening();

    try {
      if (matchedAction == "capture") {
        await captureImage(fromVoice: true);
      } else if (matchedAction == "settings") {
        await openSettings(fromVoice: true);
      }
    } catch (e) {
      debugPrint("Error handling voice command: $e");
    }

    if (!mounted) return;
    // Restart guidance and listening after each voice command
    await giveGuidance();
    isHandlingCommand = false;
    if (mounted) listenForCommand();
  }

  Future<void> captureImage({bool fromVoice = false}) async {
    try {
      if (controller == null || !controller!.value.isInitialized) {
        debugPrint("Camera not initialized yet.");
        return;
      }
      if (controller!.value.isTakingPicture) {
        return;
      }

      final image = await controller!.takePicture();
      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        capturedImageBytes = bytes;
      });

      final msg = currentLanguageCode == "ur"
          ? "تصویر لی گئی ہے۔"
          : "Image captured.";
      await VoiceAssistantService.speak(msg, languageCode: currentLanguageCode);

      // Stop listening before navigating so voice commands don't fire on the new screen
      VoiceAssistantService.stopListening();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecognitionServiceScreen(
            capturedImage: image,
            languageCode: currentLanguageCode,
          ),
        ),
      );

      if (!fromVoice && mounted) {
        await giveGuidance();
        listenForCommand();
      }
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  Future<void> openSettings({bool fromVoice = false}) async {
    if (!mounted) return;

    VoiceAssistantService.stopListening();

    final confirmMsg = currentLanguageCode == "ur"
        ? "سیٹنگز کھول دی گئی ہیں۔"
        : "Settings opened.";
    await VoiceAssistantService.speak(confirmMsg, languageCode: currentLanguageCode);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentLanguageCode: currentLanguageCode,
          onLocaleChange: (newCode) {
            // Reflect the language change on this screen immediately,
            // even though this screen instance was never recreated.
            if (mounted) {
              setState(() {
                currentLanguageCode = newCode;
              });
            }
          },
        ),
      ),
    );

    // Restart guidance/listening in whichever language is now current
    // after returning from Settings, for both voice- and tap-triggered opens.
    if (mounted) {
      await giveGuidance();
      listenForCommand();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    VoiceAssistantService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0B4F7D),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => openSettings(fromVoice: false),
          ),
        ],
      ),
      body: initializeControllerFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              controller != null &&
              controller!.value.isInitialized) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(controller!)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: FloatingActionButton(
                      onPressed: () => captureImage(fromVoice: false),
                      backgroundColor: const Color(0xff0B4F7D),
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
                if (capturedImageBytes != null)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        capturedImageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}