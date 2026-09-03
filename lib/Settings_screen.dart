import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Services/voice_assistant_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLanguageCode; // "en" or "ur"
  final Function(String) onLocaleChange;

  const SettingsScreen({
    super.key,
    required this.currentLanguageCode,
    required this.onLocaleChange,
  });

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late String selectedLanguage;

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

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.currentLanguageCode;
    giveGuidanceAndListen();
  }

  Future<void> giveGuidanceAndListen() async {
    if (selectedLanguage == "ur") {
      await VoiceAssistantService.speak(
        "سیٹنگز۔ زبان تبدیل کرنے کے لئے 'انگلش' یا 'اردو' کہیں۔ کیمرہ اسکرین پر واپس جانے کے لئے 'واپس جائیں' کہیں۔",
        languageCode: "ur",
      );
    } else {
      await VoiceAssistantService.speak(
        "Settings. Say English or Urdu to change the language. Say 'go back' to return to the camera screen.",
        languageCode: "en",
      );
    }
    if (mounted) {
      VoiceAssistantService.listen(handleVoiceInput);
    }
  }

  void handleVoiceInput(String result) async {
    final input = result.toLowerCase().trim();

    if (input.contains("go back") ||
        input.contains("back") ||
        input.contains("واپس")) {
      await goBack();
    } else if (input.contains("english") || input.contains("انگلش")) {
      await selectLanguage("en");
    } else if (input.contains("urdu") || input.contains("اردو")) {
      await selectLanguage("ur");
    }
  }

  Future<void> goBack() async {
    VoiceAssistantService.stopListening();

    final msg = selectedLanguage == "ur"
        ? "کیمرہ اسکرین پر واپس جا رہے ہیں۔"
        : "Going back to the camera screen.";
    await VoiceAssistantService.speak(msg, languageCode: selectedLanguage);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> selectLanguage(String code) async {
    if (code == selectedLanguage) return;

    VoiceAssistantService.stopListening();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("languageCode", code);
    await prefs.setBool("isLanguageSelected", true);

    // Applies the new language app-wide via the callback passed down
    // from the calling screen, so it picks it up immediately on return.
    widget.onLocaleChange(code);

    if (!mounted) return;

    setState(() {
      selectedLanguage = code;
    });

    final confirmMsg = code == "ur"
        ? "زبان اردو میں تبدیل کر دی گئی ہے۔"
        : "Language changed to English.";
    await VoiceAssistantService.speak(confirmMsg, languageCode: code);

    if (mounted) {
      VoiceAssistantService.listen(handleVoiceInput);
    }
  }

  @override
  void dispose() {
    VoiceAssistantService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff081C2D),
      appBar: AppBar(
        backgroundColor: const Color(0xff081C2D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Language",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Say 'English' or 'Urdu', or tap to select. Say 'go back' to return.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final lang = languages[index];
                    final bool isSelected = lang["code"] == selectedLanguage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          await selectLanguage(lang["code"] as String);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xff124E78),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
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
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 28)
                              else
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