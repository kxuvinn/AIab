import 'package:flutter/material.dart';
import 'recommend_screen.dart';

class SubjectSelectScreen extends StatefulWidget {
  final String nickname;
  final String grade;

  SubjectSelectScreen({required this.nickname, required this.grade});

  @override
  _SubjectSelectScreenState createState() => _SubjectSelectScreenState();
}

class _SubjectSelectScreenState extends State<SubjectSelectScreen> {
  late List<String> subjects;
  String? selectedSubject;

  Map<String, List<String>> curriculum = {
    "초1": ["1부터 9까지의 수", "여러 가지 모양", "덧셈과 뺄셈", "50까지의 수", "비교하기", "덧셈과 뺄셈(두 자리 수)"],
    "초2": ["세 자리 수", "덧셈과 뺄셈 (세 자리 수)", "길이 재기", "곱셈", "시각과 시간", "분수와 소수", "규칙 찾기"],
    "초3": ["곱셈", "나눗셈", "들이와 무게", "분수", "소수", "원", "규칙 찾기"],
    "초4": ["큰 수", "각도", "곱셈과 나눗셈", "분수의 덧셈과 뺄셈", "평면도형", "막대그래프", "혼합계산", "소수의 덧셈과 뺄셈"],
    "초5": ["자연수의 혼합계산", "약수와 배수", "분수의 곱셈", "평면도형의 합동", "소수의 곱셈", "직육면체", "평균과 가능성"],
    "초6": ["분수의 나눗셈", "소수의 나눗셈", "비와 비율", "원의 넓이", "입체도형의 부피", "속력", "그래프와 비율"],
    "중1": ["정수와 유리수", "문자와 식", "함수", "기하", "통계"],
    "중2": ["다항식", "연립방정식", "일차함수", "도형의 성질", "확률"],
    "중3": ["제곱근", "이차방정식", "이차함수", "삼각비", "원의 성질", "통계"],
  };

  @override
  void initState() {
    super.initState();
    subjects = curriculum[widget.grade] ?? [];
  }

  void _startRecommendation() {
    if (selectedSubject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendScreen(
            nickname: widget.nickname,
            grade: widget.grade,
            subject: selectedSubject!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('단원을 선택해주세요!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('단원 선택')),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            DropdownButton<String>(
              hint: Text('단원을 선택하세요'),
              value: selectedSubject,
              items: subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _startRecommendation,
              child: Text('문제 추천받기'),
            ),
          ],
        ),
      ),
    );
  }
}
