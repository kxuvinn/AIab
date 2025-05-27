import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'welcome_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  String? selectedGrade; // 선택한 학년
  bool isIdChecked = false;

  final List<String> gradeOptions = ['중1', '중2', '중3', '고1', '고2', '고3'];

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool success = false}) {
    if(mounted){ //위젯 dispose()시 context 사용 오류 방지
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    success ? '성공' : '오류',
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Future<void> checkId() async {
    String id = idController.text.trim();

    if (id.isEmpty) {
      showMessage('아이디를 입력해주세요');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/check-id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['available'] == true) {
        setState(() {
          isIdChecked = true;
        });
        showMessage('사용 가능한 아이디입니다.', success: true);
      } else {
        setState(() {
          isIdChecked = false;
        });
        showMessage(data['message'] ?? '아이디 확인 실패');
      }
    } catch (e) {
      showMessage('서버와 연결할 수 없습니다');
    }
  }

  void signup() async {
    String id = idController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();
    String? grade = selectedGrade;

    if (id.isEmpty || password.isEmpty || confirmPassword.isEmpty || grade == null) {
      showMessage('모든 항목을 입력해주세요');
      return;
    }

    if (!isIdChecked) {
      showMessage('아이디 중복 확인을 해주세요');
      return;
    }

    if (password != confirmPassword) {
      showMessage('비밀번호가 일치하지 않습니다');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'password': password,
          'grade': grade,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        // 여기 회원가입 성공 팝업 + 확인 누르면 WelcomeScreen 이동

        if(mounted){ //disepose()시 context 사용 오류 방지
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        '회원가입 성공!',
                        style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '회원가입이 완료되었습니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'NotoSans', fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // 팝업 먼저 닫고
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } else {
        showMessage(data['message'] ?? '회원가입 실패');
      }
    } catch (e) {
      showMessage('서버와 연결할 수 없습니다');
    }
  }

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
          '회원가입',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idController,
                    decoration: inputStyle('아이디', Icons.person),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[300],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: checkId,
                  child: const Text(
                    '중복확인',
                    style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputStyle('비밀번호', Icons.lock),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: inputStyle('비밀번호 확인', Icons.lock_outline),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: inputStyle('학년 선택', Icons.school),
              value: selectedGrade,
              onChanged: (value) {
                setState(() {
                  selectedGrade = value;
                });
              },
              items: gradeOptions.map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text(
                    grade,
                    style: const TextStyle(fontFamily: 'NotoSans'),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: signup,
              child: const Text(
                '회원가입',
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
