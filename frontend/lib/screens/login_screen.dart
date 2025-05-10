import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ❗ 로그인 실패 시 팝업 메시지
  void showMessage(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    '로그인 실패',
                    style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'NotoSans', fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // ✅ 로그인 요청 및 HomeScreen으로 이동
  void login() async {
    print("🚀 login() 함수 실행됨");

    String id = idController.text.trim();
    String password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      showMessage('아이디와 비밀번호를 모두 입력해주세요');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': id, 'password': password}),
      );

      print("🔁 상태코드: ${response.statusCode}");
      print("📦 응답내용: ${response.body}");

      final data = json.decode(utf8.decode(response.bodyBytes));
      print("✅ 파싱된 데이터: $data");

      if (response.statusCode == 200 && (data['success'] == true || data['success'] == "true")) {
        String grade = data['grade'];
        String userId = data['userId'] ?? id;

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen(userGrade: grade, userId: userId)),
            (route) => false,
          );
        }
      } else {
        showMessage(data['message'] ?? '로그인에 실패했습니다.');
      }
    } catch (e) {
      showMessage('서버와 연결할 수 없습니다.');
    }
  }

  // 텍스트필드 스타일 공통 함수
  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'NotoSans'),
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.blue[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '로그인',
          style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 140, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: idController,
              decoration: inputStyle('아이디', Icons.person),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputStyle('비밀번호', Icons.lock),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: login,
              child: const Text(
                '로그인',
                style: TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
