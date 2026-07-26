import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Recognition_Service.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final Function(String) onLocaleChange;

  const LanguageSelectionScreen({
    super.key,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    final languages = [
      {
        "code": "en",
        "title": "English",
        "subtitle": "Continue in English",
        "icon": Icons.language,
      },
      {
        "code": "ur",
        "title": "اردو",
        "subtitle": "اردو میں جاری رکھیں",
        "icon": Icons.translate,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xff081C2D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Image.asset("assets/images/logo.png", height: 120),
              const SizedBox(height: 25),
              const Text(
                "Choose Your Language",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select your preferred language to continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                              "languageCode", lang["code"] as String);
                          await prefs.setBool("isLanguageSelected", true);

                          onLocaleChange(lang["code"] as String);

                          if (!context.mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CaptureImageScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xff124E78),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  lang["icon"] as IconData,
                                  color: const Color(0xff124E78),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang["title"] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      lang["subtitle"] as String,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
