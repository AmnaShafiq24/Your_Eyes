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
  bool isHandlingCommand = false;

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
    startVoiceAssistant();
  }

  Future<void> startVoiceAssistant() async {
    await giveGuidance();
    listenForCommand();
  }

  void listenForCommand() {
    VoiceAssistantService.stopListening();
    VoiceAssistantService.listen(
      handleVoiceInput,
      onSessionEnded: handleSessionEnded,
      languageCode: selectedLanguage,
    );
  }

  void handleSessionEnded() {
    if (!mounted || isHandlingCommand) return;
    listenForCommand();
  }

  Future<void> giveGuidance() async {
    if (!mounted) return;
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
  }

  void handleVoiceInput(String result) async {
    // Guard against overlapping partial-result triggers while a
    // previous command is still being processed.
    if (!mounted || isHandlingCommand) return;

    final input = result.toLowerCase().trim();
    String? matchedAction;
    String? matchedLanguage;

    // Urdu speech is often transcribed phonetically in Latin letters
    // (e.g. "wapis jao") rather than Urdu script, depending on the STT
    // engine/locale, so we match both script and common romanized forms.
    final bool saysGoBack = input.contains("go back") ||
        input.contains("back") ||
        input.contains("واپس") ||
        input.contains("wapis") ||
        input.contains("wapas") ||
        input.contains("vapis") ||
        input.contains("vapas") ||
        input.contains("peeche");

    final bool saysEnglish =
        input.contains("english") || input.contains("انگلش");

    final bool saysUrdu = input.contains("urdu") ||
        input.contains("اردو") ||
        input.contains("urdo");

    if (saysGoBack) {
      matchedAction = "back";
    } else if (saysEnglish) {
      matchedAction = "language";
      matchedLanguage = "en";
    } else if (saysUrdu) {
      matchedAction = "language";
      matchedLanguage = "ur";
    }

    if (matchedAction == null) return;

    isHandlingCommand = true;
    VoiceAssistantService.stopListening();

    try {
      if (matchedAction == "back") {
        await goBack();
        // Screen is popping — no need to restart listening here.
        return;
      } else if (matchedAction == "language" && matchedLanguage != null) {
        await selectLanguage(matchedLanguage);
      }
    } catch (e) {
      debugPrint("Error handling settings voice command: $e");
    }

    if (!mounted) return;
    isHandlingCommand = false;
    listenForCommand();
  }

  Future<void> goBack() async {
    final msg = selectedLanguage == "ur"
        ? "کیمرہ اسکرین پر واپس جا رہے ہیں۔"
        : "Going back to the camera screen.";
    await VoiceAssistantService.speak(msg, languageCode: selectedLanguage);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> selectLanguage(String code) async {
    if (code == selectedLanguage) {
      final msg = code == "ur"
          ? "زبان پہلے ہی اردو ہے۔"
          : "Language is already English.";
      await VoiceAssistantService.speak(msg, languageCode: code);
      return;
    }

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
                          if (isHandlingCommand) return;
                          isHandlingCommand = true;
                          VoiceAssistantService.stopListening();
                          await selectLanguage(lang["code"] as String);
                          if (mounted) {
                            isHandlingCommand = false;
                            listenForCommand();
                          }
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