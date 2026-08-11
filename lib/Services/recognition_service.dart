import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RecognitionServiceScreen extends StatefulWidget {
  final XFile capturedImage;

  const RecognitionServiceScreen({super.key, required this.capturedImage});

  @override
  State<RecognitionServiceScreen> createState() => RecognitionServiceScreenState();
}

class RecognitionServiceScreenState extends State<RecognitionServiceScreen> {
  String resultMessage = "Processing image...";

  // Generic terms Vision API's label detection actually returns for money/notes
  final List<String> currencyLabels = [
    "banknote", "currency", "cash", "money", "bill", "paper currency", "coin"
  ];
  final List<String> fruits = [
    "apple", "banana", "mango", "orange", "grape", "pineapple", "watermelon"
  ];
  final List<String> vegetables = [
    "potato", "tomato", "carrot", "onion", "cabbage", "spinach", "pepper"
  ];

  static const String cloudFunctionUrl =
      "https://recognizeimage-y2lqize5aq-uc.a.run.app";

  @override
  void initState() {
    super.initState();
    analyzeImage();
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
        return;
      }

      final labels = List<String>.from(data['labels'] ?? []);
      final String? denomination = data['denomination'];

      // Task 1: total number of objects detected
      final int totalObjects = labels.length;

      // Task 2: match against currency, fruits, vegetables only
      bool isCurrencyDetected = false;
      final List<String> matchedFruits = [];
      final List<String> matchedVegetables = [];

      for (var label in labels) {
        final text = label.toLowerCase();

        if (currencyLabels.any((c) => text.contains(c))) {
          isCurrencyDetected = true;
        }
        for (var fruit in fruits) {
          if (text.contains(fruit)) {
            matchedFruits.add(fruit);
          }
        }
        for (var veg in vegetables) {
          if (text.contains(veg)) {
            matchedVegetables.add(veg);
          }
        }
      }

      setState(() {
        resultMessage = buildResultMessage(
          totalObjects,
          isCurrencyDetected,
          denomination,
          matchedFruits,
          matchedVegetables,
        );
      });
    } catch (e) {
      setState(() {
        resultMessage = "Error analyzing image: $e";
      });
    }
  }

  String buildResultMessage(
      int totalObjects,
      bool isCurrencyDetected,
      String? denomination,
      List<String> fruits,
      List<String> vegetables,
      ) {
    final buffer = StringBuffer();

    // First: total item count
    buffer.writeln(
      "There ${totalObjects == 1 ? 'is' : 'are'} $totalObjects item${totalObjects == 1 ? '' : 's'} in the image.",
    );

    final bool hasAnyMatch =
        isCurrencyDetected || fruits.isNotEmpty || vegetables.isNotEmpty;

    if (!hasAnyMatch) {
      buffer.writeln("No currency notes, fruits, or vegetables were identified.");
      return buffer.toString().trim();
    }

    if (isCurrencyDetected) {
      if (denomination != null) {
        buffer.writeln("Currency note: $denomination rupees");
      } else {
        buffer.writeln("Currency note detected, but the denomination could not be read clearly.");
      }
    }
    if (fruits.isNotEmpty) {
      buffer.writeln("Fruit${fruits.length > 1 ? 's' : ''}: ${fruits.join(', ')}");
    }
    if (vegetables.isNotEmpty) {
      buffer.writeln("Vegetable${vegetables.length > 1 ? 's' : ''}: ${vegetables.join(', ')}");
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
                // Speech bubble containing the recognition result text
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

                // Small triangle "tail" pointing down from the bubble to the avatar
                CustomPaint(
                  size: const Size(24, 14),
                  painter: BubbleTailPainter(),
                ),

                const SizedBox(height: 16),

                // Assistant avatar, centered
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