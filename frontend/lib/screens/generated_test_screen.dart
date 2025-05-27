import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeneratedTestScreen extends StatefulWidget {
  final List quizList;
  final String? subject;
  final String range;
  final String userId;

  const GeneratedTestScreen({
    super.key,
    required this.quizList,
    required this.range,
    this.subject,
    required this.userId,
  });

  @override
  State<GeneratedTestScreen> createState() => _GeneratedTestScreenState();
}

class _GeneratedTestScreenState extends State<GeneratedTestScreen> {
  final Map<int, String> answers = {};
  final Map<int, String> results = {};
  final Map<int, String> explanations = {};
  bool submitting = false;

  Future<void> submitAllAnswers() async {
    setState(() => submitting = true);

    for (var q in widget.quizList) {
      final id = q["id"];
      final userAnswer = answers[id]?.trim() ?? "";

      if (userAnswer.isEmpty) continue;

      final res = await http.post(
        Uri.parse("http://10.0.2.2:8000/check-answer"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "user_id": widget.userId,
          "question": q["question"],
          "user_answer": userAnswer,
          "correct_answer": q["answer"],
        }),
      );

      final data = json.decode(utf8.decode(res.bodyBytes));
      setState(() {
        results[id] = data["result"];
        explanations[id] = data["explanation"];
      });
    }

    setState(() => submitting = false);
  }

  Widget buildQuestionTile(Map q) {
    final id = q["id"];
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Q$id. ${q['question']}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: "정답 입력",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                answers[id] = val;
              });
            },
          ),
          if (results.containsKey(id)) ...[
            SizedBox(height: 16),
            Text(
              results[id] == "정답입니다!" ? "🟢 정답입니다" : "🔴 틀렸습니다",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: results[id] == "정답입니다!" ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              explanations[id] ?? "",
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI 시험지 (${widget.range})"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: widget.quizList.map((q) => buildQuestionTile(q)).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: submitting ? null : submitAllAnswers,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(48),
              ),
              child: Text("정답 제출"),
            ),
          ],
        ),
      ),
    );
  }
}
