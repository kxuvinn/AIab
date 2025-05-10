import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/custom_navbar.dart';
import '../screens/quiz_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userGrade;
  final String userId;

  const ProfileScreen({required this.userGrade, required this.userId, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class EditProfileDialog extends StatefulWidget {
  final String userId;
  final String currentGrade;

  const EditProfileDialog({required this.userId, required this.currentGrade, super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late String selectedGrade;
  final List<String> gradeOptions = ['중1', '중2', '중3', '고1', '고2', '고3'];

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.currentGrade;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("프로필 수정", style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text("아이디:", style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(widget.userId, style: const TextStyle(fontFamily: 'NotoSans')),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text("학년:", style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedGrade,
                  items: gradeOptions.map((grade) {
                    return DropdownMenuItem(
                      value: grade,
                      child: Text(grade, style: const TextStyle(fontFamily: 'NotoSans')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedGrade = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(fontFamily: 'NotoSans')),
        ),
        ElevatedButton(
          onPressed: () async {
            await updateUserGrade(widget.userId, selectedGrade);
            Navigator.pop(context, selectedGrade);
          },
          child: const Text("저장", style: TextStyle(fontFamily: 'NotoSans')),
        ),
      ],
    );
  }
}

Future<void> updateUserGrade(String userId, String newGrade) async {
  final response = await http.patch(
    Uri.parse('http://10.0.2.2:8000/update-grade'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'new_grade': newGrade}),
  );

  if (response.statusCode == 200) {
    print("✅ 학년 변경 완료");
  } else {
    print("❌ 학년 변경 실패: ${response.body}");
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String updatedGrade = '';

  @override
  void initState() {
    super.initState();
    updatedGrade = widget.userGrade;
  }

  void refreshGrade(String newGrade) {
    setState(() {
      updatedGrade = newGrade;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필', style: TextStyle(fontFamily: 'NotoSans', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(updatedGrade, style: const TextStyle(fontFamily: 'NotoSans', fontSize: 12, color: Colors.deepOrange)),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.userId, style: const TextStyle(fontFamily: 'NotoSans', fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final newGrade = await showDialog<String>(
                      context: context,
                      builder: (_) => EditProfileDialog(
                        userId: widget.userId,
                        currentGrade: updatedGrade,
                      ),
                    );
                    if (newGrade != null) refreshGrade(newGrade);
                  },
                  child: const Text("수정", style: TextStyle(fontFamily: 'NotoSans')),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ListTile(
              title: const Text("오늘의 퀴즈 기록", style: TextStyle(fontFamily: 'NotoSans')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizHistoryScreen(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text("질문 기록", style: TextStyle(fontFamily: 'NotoSans')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: CustomNavBar(
          currentIndex: 3,
          userGrade: updatedGrade,
          userId: widget.userId,
        ),
      ),
    );
  }
}