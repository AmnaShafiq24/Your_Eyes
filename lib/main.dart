import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'camera_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Your Eyes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(
        onLocaleChange: (locale) {
        },
      ),
    );
  }
}
