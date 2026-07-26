import 'package:flutter/material.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(String) onLocaleChange;

  const SplashScreen({super.key, required this.onLocaleChange});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageSelectionScreen(
          onLocaleChange: widget.onLocaleChange,
        ),
      ),
    );

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
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
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