import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Services/voice_assistant_service.dart';

class CaptureImageScreen extends StatefulWidget {
  final String languageCode; // "en" or "ur"

  const CaptureImageScreen({super.key, required this.languageCode});

  @override
  State<CaptureImageScreen> createState() => CaptureImageScreenState();
}

class CaptureImageScreenState extends State<CaptureImageScreen> {
  CameraController? controller;
  Future<void>? initializeControllerFuture;
  Uint8List? capturedImageBytes;
  bool isHandlingCommand = false;

  @override
  void initState() {
    super.initState();
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
    );
  }

  void handleSessionEnded() {
    if (!mounted || isHandlingCommand) return;
    listenForCommand();
  }

  Future<void> giveGuidance() async {
    if (!mounted) return;
    if (widget.languageCode == "ur") {
      await VoiceAssistantService.speak(
        "تصویر لینے کے لئے 'کیپچر' کہیں۔ سیٹنگز کھولنے کے لئے 'سیٹنگز کھولیں' کہیں۔",
        languageCode: "ur",
      );
    } else {
      await VoiceAssistantService.speak(
        "Say 'Capture' to take a picture. Say 'Open Settings' to open settings.",
        languageCode: "en",
      );
    }
  }

  void handleVoiceInput(String result) async {
    if (!mounted || isHandlingCommand) return;
    final input = result.toLowerCase().trim();
    String? matchedAction;

    if (widget.languageCode == "ur") {
      if (input.contains("کیپچر")) {
        matchedAction = "capture";
      } else if (input.contains("سیٹنگ")) {
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
        await captureImage();
      } else if (matchedAction == "settings") {
        openSettings();
      }
    } catch (e) {
      debugPrint("Error handling voice command: $e");
    }

    if (!mounted) return;
    // Restart guidance and listening after each command
    await giveGuidance();
    isHandlingCommand = false;
    if (mounted) listenForCommand();
  }

  Future<void> captureImage() async {
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

      final msg = widget.languageCode == "ur"
          ? "تصویر لی گئی ہے۔"
          : "Image captured.";
      await VoiceAssistantService.speak(msg, languageCode: widget.languageCode);
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  void openSettings() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings tapped")),
    );

    if (widget.languageCode == "ur") {
      VoiceAssistantService.speak("سیٹنگز کھول دی گئی ہیں۔", languageCode: "ur");
    } else {
      VoiceAssistantService.speak("Settings opened.", languageCode: "en");
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
            onPressed: openSettings,
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
                      onPressed: captureImage,
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