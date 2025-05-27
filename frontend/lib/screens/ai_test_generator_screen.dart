import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/quiz_result_screen.dart';

class AiTestGeneratorScreen extends StatefulWidget {
  final String userId;

  const AiTestGeneratorScreen({super.key, required this.userId});

  @override
  State<AiTestGeneratorScreen> createState() => _AiTestGeneratorScreenState();
}

class _AiTestGeneratorScreenState extends State<AiTestGeneratorScreen> {
  String? grade;
  Map<String, List<String>> subjectRangeMap = {};
  String? selectedSubject;
  String? selectedRange;
  bool isLoading = true;
  List quizzes = [];
  List<String> userAnswers = [];

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.0.2.2:8000/get-user-info?user_id=${widget.userId}"),
      );

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          grade = data['grade'];
          if (data.containsKey('available_subjects')) {
            final ranges = data['available_ranges'] as Map<String, dynamic>;
            subjectRangeMap = {
              for (var key in ranges.keys) key: List<String>.from(ranges[key])
            };
          } else {
            subjectRangeMap = {"": List<String>.from(data['available_ranges'])};
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ 네트워크 오류: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> generateTest() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("AI가 시험지를 생성하고 있습니다.", style:TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("잠시만 기다려주세요...", style: TextStyle(fontSize: 12, fontFamily: 'NotoSans')),
          ],
        ),
      ),
    );

    final body = {
      "user_id": widget.userId,
      "selected_range": selectedRange,
    };

    if (selectedSubject != null && selectedSubject!.isNotEmpty) {
      body["subject"] = selectedSubject;
    }

    final res = await http.post(
      Uri.parse("http://10.0.2.2:8000/generate-quiz"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    final data = json.decode(utf8.decode(res.bodyBytes));

    Navigator.pop(context);

    if (res.statusCode == 200 && data.containsKey("quizzes")) {
      setState(() {
        quizzes = data['quizzes'];
        userAnswers = List.filled(quizzes.length, "");
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("오류"),
          content: Text(data['error'] ?? "시험지를 생성할 수 없습니다."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))],
        ),
      );
    }
  }

  Future<void> submitAll() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("AI가 해설을 생성 중입니다.", style:TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("잠시만 기다려주세요...", style: TextStyle(fontSize: 12, fontFamily: 'NotoSans')),
          ],
        ),
      ),
    );

    final answerList = quizzes.asMap().entries.map((entry) {
      final i = entry.key;
      final quiz = entry.value;
      return {
        "question": quiz["question"],
        "user_answer": userAnswers[i],
        "correct_answer": quiz["answer"],
      };
    }).toList();

    final res = await http.post(
      Uri.parse("http://10.0.2.2:8000/check-answer-bulk"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "user_id": widget.userId,
        "answers": answerList
      }),
    );

    final resultList = json.decode(utf8.decode(res.bodyBytes));
  
    await http.post(
      Uri.parse("http://10.0.2.2:8000/save-note"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "user_id": widget.userId,
        "grade": grade,
        "subject": selectedSubject ?? "",
        "range_name": selectedRange ?? "",
        "quizzes": resultList,
      }),
    );

    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          quizzes: resultList,
          userAnswers: userAnswers,
          userId: widget.userId,
          isFromNote: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHigh = RegExp(r'고\d').hasMatch(grade ?? "");

    return Scaffold(
      appBar: AppBar(title: Text("AI 시험지")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isHigh && subjectRangeMap.isNotEmpty) ...[
                        Text("과목 선택", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                        DropdownButton<String>(
                          isExpanded: true,
                          hint: Text("과목 선택", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                          value: selectedSubject,
                          items: subjectRangeMap.keys
                              .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontFamily: 'NotoSans'))))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedSubject = val;
                              selectedRange = null;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                      Text("단원 선택", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSans')),
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: Text(isHigh && selectedSubject == null ? "과목 먼저 선택하세요" : "단원 선택"),
                        value: selectedRange,
                        items: (() {
                          if (isHigh) {
                            if (selectedSubject != null && subjectRangeMap.containsKey(selectedSubject)) {
                              return subjectRangeMap[selectedSubject]!;
                            } else {
                              return <String>[];
                            }
                          } else {
                            return subjectRangeMap[""] ?? <String>[];
                          }
                        })()
                            .map((r) => DropdownMenuItem<String>(
                                  value: r,
                                  child: Text(r, style:TextStyle(fontFamily: 'NotoSans')),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedRange = val),
                      ),
                      Spacer(),
                      Center(
                        child: ElevatedButton(
                          onPressed: selectedRange != null ? generateTest : null,
                          child: Text("시험지 생성하기"),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: quizzes.length,
                          itemBuilder: (context, index) {
                            final q = quizzes[index];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("문제 ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontFamily:'NotoSans')),
                                    SizedBox(height: 8),
                                    Text(q["question"]),
                                    SizedBox(height: 12),
                                    TextField(
                                      onChanged: (val) => userAnswers[index] = val,
                                      style: TextStyle(fontSize: 14, fontFamily: 'NotoSans'),
                                      decoration: InputDecoration(
                                        hintText: "답을 입력하세요",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: submitAll,
                        style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(48)),
                        child: Text("정답 제출"),
                      )
                    ],
                  ),
                ),
    );
  }
}