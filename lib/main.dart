import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Recognition_Service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved language preference (default: English)
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('languageCode') ?? 'en';

  runApp(MyApp(initialLocale: savedLanguage));
}

class MyApp extends StatefulWidget {
  final String initialLocale;
  const MyApp({super.key, required this.initialLocale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = Locale(widget.initialLocale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your Eyes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Color(0xff0B4F7D),
          secondary: Color(0xff0B4F7D),
        ),
      ),
      locale: _locale,
      home: const CaptureImageScreen(),
    );
  }
}
