import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_selection_screen.dart';
import 'camera_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(String) onLocaleChange;

  const SplashScreen({super.key, required this.onLocaleChange});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    goNext();
  }

  Future<void> goNext() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool isLanguageSelected = prefs.getBool("isLanguageSelected") ?? false;
    final String? languageCode = prefs.getString("languageCode");

    if (!mounted) return;

    if (isLanguageSelected && languageCode != null) {
      widget.onLocaleChange(languageCode);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CaptureImageScreen(languageCode: languageCode),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LanguageSelectionScreen(
            onLocaleChange: widget.onLocaleChange,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3F6A),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 5),
              const Text(
                "Your Eyes",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),
              ),
            ]
        ),
      ),
    );
  }
}