import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';

class NoteScreen extends StatelessWidget {
  final String userGrade;
  final String userId;

  const NoteScreen({required this.userGrade, required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('노트', style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'NoteScreen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
          currentIndex: 2,
          userGrade: userGrade,
          userId: userId,
        ),
      ),
    );
  }
}
