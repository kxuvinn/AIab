import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const AlabApp());
}

class AlabApp extends StatelessWidget {
  const AlabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSans',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 14),
          bodyLarge: TextStyle(fontSize: 16),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontWeight: FontWeight.w700),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(primary: Colors.blue),
      ),
      home: const WelcomeScreen(),
    );
  }
}
