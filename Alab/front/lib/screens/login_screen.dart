import 'package:flutter/material.dart';
import 'subject_select_screen.dart';

class GradeSelectScreen extends StatelessWidget {
  final String nickname;

  const GradeSelectScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('학년 선택')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectSelectScreen(
                      nickname: nickname,
                      grade: '중1',
                    ),
                  ),
                );
              },
              child: const Text('중1'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectSelectScreen(
                      nickname: nickname,
                      grade: '중2',
                    ),
                  ),
                );
              },
              child: const Text('중2'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubjectSelectScreen(
                      nickname: nickname,
                      grade: '중3',
                    ),
                  ),
                );
              },
              child: const Text('중3'),
            ),
          ],
        ),
      ),
    );
  }
}
