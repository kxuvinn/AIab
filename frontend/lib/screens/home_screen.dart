import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰 배경
      appBar: AppBar(
        title: const Text(
          '홈',
          style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'HomeScreen',
          style: TextStyle(
            fontFamily: 'NotoSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
