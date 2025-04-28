import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'grade_select_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  Future<void> _signup() async {
    final nickname = _nicknameController.text.trim();
    final grade = _gradeController.text.trim();
    if (nickname.isEmpty || grade.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://192.168.200.193:8000/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nickname': nickname, 'grade': grade}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => GradeSelectScreen(nickname: nickname)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${responseData["message"]}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 연결 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: '닉네임 입력'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gradeController,
              decoration:
                  const InputDecoration(labelText: '학년 입력 (중1, 중2, 중3)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _signup,
              child: const Text('회원가입 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
