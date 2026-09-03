import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  final List<String> currencyLabels = [
    "banknote", "currency", "cash", "money", "bill", "paper currency", "coin"
  ];

  final List<String> fruits = [
    "apple", "banana", "mango", "orange", "grape", "pineapple", "watermelon",
    "strawberry", "peach", "pear", "plum", "cherry", "kiwi", "papaya",
    "pomegranate", "guava", "lemon", "lime", "fig", "apricot", "blueberry",
    "coconut", "dragon fruit", "lychee", "melon", "avocado", "cantaloupe",
    "honeydew", "raspberry", "blackberry", "cranberry", "mulberry",
    "passion fruit", "star fruit", "persimmon", "custard apple",
    "jackfruit", "durian", "rambutan", "longan", "tangerine", "mandarin",
    "grapefruit", "nectarine", "date", "prune", "gooseberry", "sapodilla",
    "quince", "loquat", "elderberry", "currant", "tamarind", "olive",
    "breadfruit", "soursop",
  ];

  final List<String> vegetables = [
    "potato", "tomato", "carrot", "onion", "cabbage", "spinach", "pepper",
    "cucumber", "eggplant", "broccoli", "cauliflower", "garlic", "ginger",
    "pumpkin", "radish", "beet", "corn", "peas", "lettuce", "zucchini",
    "okra", "mushroom", "celery", "turnip", "bell pepper", "chili",
    "asparagus", "artichoke", "leek", "kale", "brussels sprouts",
    "bok choy", "fennel", "parsnip", "rutabaga", "sweet potato", "yam",
    "squash", "green bean", "lima bean", "kidney bean", "chickpea",
    "lentil", "bitter gourd", "bottle gourd", "ridge gourd", "snake gourd",
    "drumstick", "taro", "arugula", "watercress", "chard",
  ];

  static const String cloudFunctionUrl =
      "https://recognizeimage-y2lqize5aq-uc.a.run.app";

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

  Future<void> analyzeImage() async {
    try {
      final imageBytes = await widget.capturedImage.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image}),
      );

      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('error')) {
        setState(() {
          resultMessage = "Error: ${data['error']}";
        });
        await speakAndListen(resultMessage);
        return;
      }

      final labels = List<String>.from(data['labels'] ?? []);
      final List<String> denominations =
      List<String>.from(data['denominations'] ?? []);

      final int totalObjects = labels.length;

      bool isCurrencyDetected = false;
      final List<String> matchedFruits = [];
      final List<String> matchedVegetables = [];

      for (var label in labels) {
        final text = label.toLowerCase();

        if (currencyLabels.any((c) => text.contains(c))) {
          isCurrencyDetected = true;
        }
        for (var fruit in fruits) {
          if (text.contains(fruit) && !matchedFruits.contains(fruit)) {
            matchedFruits.add(fruit);
          }
        }
        for (var veg in vegetables) {
          if (text.contains(veg) && !matchedVegetables.contains(veg)) {
            matchedVegetables.add(veg);
          }
        }
      }

      final message = buildResultMessage(
        totalObjects,
        isCurrencyDetected,
        denominations,
        matchedFruits,
        matchedVegetables,
      );

      setState(() {
        resultMessage = message;
      });

      await speakAndListen(message);
    } catch (e) {
      final errMsg = "Error analyzing image: $e";
      setState(() {
        resultMessage = errMsg;
      });
      await speakAndListen(errMsg);
    }
  }

  // Speaks the given text, then starts listening for a "go back" command
  // so the user can return to the camera screen without touching the phone.
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

  String buildResultMessage(
      int totalObjects,
      bool isCurrencyDetected,
      List<String> denominations,
      List<String> fruits,
      List<String> vegetables,
      ) {
    final buffer = StringBuffer();
    final bool isUrdu = widget.languageCode == "ur";

    if (isUrdu) {
      buffer.writeln("تصویر میں $totalObjects اشیاء ہیں۔");
    } else {
      buffer.writeln(
        "There ${totalObjects == 1 ? 'is' : 'are'} $totalObjects item${totalObjects == 1 ? '' : 's'} in the image.",
      );
    }

    final bool hasAnyMatch =
        isCurrencyDetected || fruits.isNotEmpty || vegetables.isNotEmpty;

    if (!hasAnyMatch) {
      buffer.writeln(isUrdu
          ? "کوئی کرنسی نوٹ، پھل، یا سبزی شناخت نہیں ہوئی۔"
          : "No currency notes, fruits, or vegetables were identified.");
      return buffer.toString().trim();
    }

    if (isCurrencyDetected) {
      if (denominations.isNotEmpty) {
        final denomText = denominations.map((d) => "$d").join(', ');
        buffer.writeln(isUrdu
            ? "کرنسی نوٹ: $denomText روپے"
            : "Currency note${denominations.length > 1 ? 's' : ''}: ${denominations.map((d) => "$d rupees").join(', ')}");
      } else {
        buffer.writeln(isUrdu
            ? "کرنسی نوٹ شناخت ہوا، لیکن مالیت واضح طور پر نہیں پڑھی جا سکی۔"
            : "Currency note detected, but the denomination could not be read clearly.");
      }
    }
    if (fruits.isNotEmpty) {
      buffer.writeln(isUrdu
          ? "پھل: ${fruits.join(', ')}"
          : "Fruit${fruits.length > 1 ? 's' : ''}: ${fruits.join(', ')}");
    }
    if (vegetables.isNotEmpty) {
      buffer.writeln(isUrdu
          ? "سبزی: ${vegetables.join(', ')}"
          : "Vegetable${vegetables.length > 1 ? 's' : ''}: ${vegetables.join(', ')}");
    }

    return buffer.toString().trim();
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
                  "assets/images/Assistant_image.png",
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