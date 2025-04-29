import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  Future<void> _findPassword() async {
    final url = Uri.parse('http://10.0.2.2:8000/find-password');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text,
        "birthdate": _birthdateController.text,
      }),
    );

    if (response.statusCode == 200) {
      final password = jsonDecode(response.body)["password"];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('비밀번호 찾기 성공'),
          content: Text('당신의 비밀번호: $password'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${jsonDecode(response.body)["detail"]}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "아이디"),
            ),
            TextField(
              controller: _birthdateController,
              decoration: const InputDecoration(labelText: "생년월일 (YYYY-MM-DD)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _findPassword,
              child: const Text("비밀번호 찾기"),
            ),
          ],
        ),
      ),
    );
  }
}
