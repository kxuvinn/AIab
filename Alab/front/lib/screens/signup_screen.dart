import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  Future<void> _signup() async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nickname': _nicknameController.text,
        'grade': _gradeController.text,
        'subject': _subjectController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: '닉네임 입력'),
            ),
            TextField(
              controller: _gradeController,
              decoration: InputDecoration(labelText: '학년 입력 (ex. 중1)'),
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: '단원 입력 (ex. 정수와 유리수)'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: Text('회원가입 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
