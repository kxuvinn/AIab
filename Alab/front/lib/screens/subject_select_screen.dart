import 'package:flutter/material.dart';
import 'recommend_screen.dart';

class SubjectSelectScreen extends StatelessWidget {
  final String nickname;
  final String grade;

  SubjectSelectScreen({required this.nickname, required this.grade});

  final Map<String, List<String>> curriculum = {
    "중1": ["정수와 유리수", "문자와 식", "함수", "기하", "통계"],
    "중2": ["다항식", "연립방정식", "일차함수", "도형의 성질", "확률"],
    "중3": ["제곱근", "이차방정식", "이차함수", "삼각비", "원의 성질", "통계"],
  };

  @override
  Widget build(BuildContext context) {
    final subjects = curriculum[grade] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('단원 선택')),
      body: ListView.builder(
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(subjects[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecommendScreen(
                    nickname: nickname,
                    grade: grade,
                    subject: subjects[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
