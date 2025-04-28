import 'package:flutter/material.dart';

class RecommendScreen extends StatelessWidget {
  final String nickname;
  final String grade;
  final String subject;

  const RecommendScreen({
    super.key,
    required this.nickname,
    required this.grade,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추천 문제 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('닉네임: $nickname'),
            Text('학년: $grade'),
            Text('단원: $subject'),
          ],
        ),
      ),
    );
  }
}
