import 'package:flutter/material.dart';
import '../widgets/custom_navbar.dart';
import '../screens/gpt_quiz_screen.dart';


class HomeScreen extends StatelessWidget {
  final String userGrade;
  final String userId;

  const HomeScreen({required this.userGrade, required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '홈',
          style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            //오늘의 퀴즈
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GptQuizScreen(userGrade: userGrade, userId: userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("오늘의 퀴즈", 
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'NotoSans',
                color: Colors.white,
                )
                ),
            ),
            const SizedBox(height: 20),
            //문제 검색 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImageUploadScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "문제 검색",
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'NotoSans',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
          currentIndex: 0,
          userGrade: userGrade,
          userId: userId,
        ),
      ),
    );
  }
}
