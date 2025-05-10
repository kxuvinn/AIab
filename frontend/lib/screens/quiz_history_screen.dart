import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizHistoryScreen extends StatefulWidget {
  final String userId;

  const QuizHistoryScreen({required this.userId, super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  Map<String, List<dynamic>> quizData = {};
  Set<String> expandedDates = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchQuizHistory();
  }

  Future<void> fetchQuizHistory() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/quiz-history?user_id=${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      setState(() {
        quizData = decoded.map((date, list) => MapEntry(date, List.from(list)));
        loading = false;
      });
    } else {
      print("❌ 기록 불러오기 실패: ${response.body}");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue[700];

    return Scaffold(
      appBar: AppBar(
        title: const Text("오늘의 퀴즈 기록", style: TextStyle(fontFamily: 'NotoSans', color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : quizData.isEmpty
              ? const Center(child: Text("기록이 없습니다.", style: TextStyle(fontFamily: 'NotoSans')))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: quizData.entries.map((entry) {
                    final date = entry.key;
                    final quizzes = entry.value;
                    final isExpanded = expandedDates.contains(date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                expandedDates.remove(date);
                              } else {
                                expandedDates.add(date);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'NotoSans'),
                                ),
                                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          ...quizzes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final q = entry.value;
                            final userAnswer = q["user_answer"]?.toString().trim() ?? "";
                            final correctAnswer = q["correct_answer"]?.toString().trim() ?? "";
                            final isCorrect = userAnswer == correctAnswer;

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("문제 ${index + 1}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'NotoSans')),
                                    const SizedBox(height: 8),
                                    Text(q["question"] ?? "", style: const TextStyle(fontSize: 16, fontFamily: 'NotoSans')),
                                    const SizedBox(height: 12),
                                    Text("내 답변: $userAnswer",
                                        style: TextStyle(
                                            color: isCorrect ? Colors.green : Colors.red,
                                            fontFamily: 'NotoSans')),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                                          color: isCorrect ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(isCorrect ? "정답" : "오답",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isCorrect ? Colors.green : Colors.red,
                                                fontFamily: 'NotoSans')),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text("정답: $correctAnswer",
                                        style: TextStyle(
                                            color: isCorrect ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'NotoSans')),
                                    const SizedBox(height: 8),
                                    Text("해설:",
                                        style: TextStyle(
                                            color: themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoSans')),
                                    Text(q["explanation"] ?? "해설이 없습니다.",
                                        style: const TextStyle(fontFamily: 'NotoSans')),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
