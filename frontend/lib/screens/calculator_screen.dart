import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';

class CalculatorScreen extends StatelessWidget {
  final String userGrade;
  final String userId;
  
  const CalculatorScreen({required this.userGrade, required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('계산기', style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'CalculatorScreen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
          currentIndex: 1,
          userGrade: userGrade,
          userId: userId,
        ),
      ),
    );
  }
}
